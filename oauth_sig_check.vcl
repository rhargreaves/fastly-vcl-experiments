
table consumer_secrets {
	"foo": "super_secret"
}

table access_tokens {
	"bar": "token_secret"
}

sub vcl_recv {
#FASTLY recv
#DEPLOY recv
	set req.http.X-OAuth-Consumer-Key = if(req.url ~ "(?i)oauth_consumer_key=([^&]*)", urldecode(re.group.1), "");
	if(req.http.X-OAuth-Consumer-Key == "") {
		error 401 "Missing Consumer Key";
	}
	set req.http.X-OAuth-Consumer-Secret = table.lookup(consumer_secrets, req.http.X-OAuth-Consumer-Key);
	if(!req.http.X-OAuth-Consumer-Secret) {
		error 401 "Invalid Consumer Key";
	}
	set req.http.X-OAuth-Access-Token = if(req.url ~ "(?i)oauth_token=([^&]*)", urldecode(re.group.1), "");
	if(req.http.X-OAuth-Access-Token != "") {
		set req.http.X-OAuth-Access-Token-Secret = table.lookup(access_tokens, req.http.X-OAuth-Access-Token);
		if(!req.http.X-OAuth-Access-Token-Secret) {
			error 401 "Invalid Access Token";
		}
	} else {
		set req.http.X-OAuth-Access-Token-Secret = "";
	}
	set req.http.X-OAuth-Provided-Signature = if(req.url ~ "(?i)oauth_signature=([^&]*)", urldecode(re.group.1), "");
	if(req.http.X-OAuth-Provided-Signature == "") {
		error 401 "Missing Signature";
	}
	set req.http.X-OAuth-Ordered-Url = boltsort.sort(req.url);
	set req.http.X-OAuth-Parameters = regsub(regsub(req.http.X-OAuth-Ordered-Url, ".*\?", ""), "&oauth_signature=[^&]*", "");
	set req.http.X-OAuth-Base-String-Uri = 
		if(req.http.Fastly-SSL, "https", "http") 
		"://"
		std.tolower(req.http.host)
		req.url.path;
	set req.http.X-OAuth-Signature-Base-String = 
		req.request
		"&"
		urlencode(req.http.X-OAuth-Base-String-Uri)
		"&"
		urlencode(req.http.X-OAuth-Parameters);

	set req.http.X-OAuth-Calculated-Signature = digest.hmac_sha1_base64(
			req.http.X-OAuth-Consumer-Secret "&" req.http.X-OAuth-Access-Token-Secret, 
			req.http.X-OAuth-Signature-Base-String);

	unset req.http.X-OAuth-Consumer-Secret;
	unset req.http.X-OAuth-Access-Token-Secret;
	unset req.http.X-OAuth-Base-String-Uri;

	if(req.http.X-OAuth-Provided-Signature != req.http.X-OAuth-Calculated-Signature) {
		error 401 "Invalid OAuth Signature";
	}

	set req.http.X-OAuth-Timestamp = if(req.url ~ "(?i)oauth_timestamp=([0-9]*)", urldecode(re.group.1), "");
	if(req.http.X-OAuth-Timestamp == "") {
		error 401 "Missing/Invalid Timestamp";
	}

	if(time.is_after(
		now,
		time.add(std.integer2time(std.atoi(req.http.X-OAuth-Timestamp)), 30m))) {
		error 401 "Timestamp expired";
	}

	if(time.is_after(
		std.integer2time(std.atoi(req.http.X-OAuth-Timestamp)),
		time.add(now, 1m))) {
		error 401 "Timestamp too far in future";
	}

	error 200 "Authenticated!";

	return(lookup);
}

sub vcl_fetch {
#FASTLY fetch
	return(deliver);
}

sub vcl_hit {
#FASTLY hit
	if (!obj.cacheable) {
		return(pass);
	}
	return(deliver);
}

sub vcl_miss {
#FASTLY miss
	return(fetch);
}

sub vcl_deliver{
#FASTLY deliver
	# Expose variables for debugging
	set resp.http.X-OAuth-Consumer-Key = req.http.X-OAuth-Consumer-Key;
	set resp.http.X-OAuth-Access-Token = req.http.X-OAuth-Access-Token;
	set resp.http.X-OAuth-Provided-Signature = req.http.X-OAuth-Provided-Signature;
	set resp.http.X-OAuth-Calculated-Signature = req.http.X-OAuth-Calculated-Signature;
	set resp.http.X-OAuth-Parameters = req.http.X-OAuth-Parameters;
	set resp.http.X-OAuth-Signature-Base-String = req.http.X-OAuth-Signature-Base-String;
	return(deliver);
}

sub vcl_error {
#FASTLY error
#DEPLOY error
}

sub vcl_pass {
#FASTLY pass
}
