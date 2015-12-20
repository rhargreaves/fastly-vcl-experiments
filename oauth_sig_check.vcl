
table consumer_secrets {
	"foo": "super_secret"
}

table access_tokens {
	"bar": "token_secret"
}

sub vcl_recv {
#FASTLY recv
#DEPLOY recv
	set req.http.X-Consumer-Key = if(req.url ~ "(?i)oauth_consumer_key=([^&]*)", urldecode(re.group.1), "");
	if(req.http.X-Consumer-Key == "") {
		error 401 "Missing Consumer Key";
	}
	set req.http.X-Consumer-Secret = table.lookup(consumer_secrets, req.http.X-Consumer-Key);
	if(!req.http.X-Consumer-Secret) {
		error 401 "Invalid Consumer Key";
	}
	set req.http.X-Access-Token = if(req.url ~ "(?i)oauth_token=([^&]*)", urldecode(re.group.1), "");
	if(req.http.X-Access-Token != "") {
		set req.http.X-Access-Token-Secret = table.lookup(access_tokens, req.http.X-Access-Token);
		if(!req.http.X-Access-Token-Secret) {
			error 401 "Invalid Access Token";
		}
	} else {
		set req.http.X-Access-Token-Secret = "";
	}
	set req.http.X-Provided-Signature = if(req.url ~ "(?i)oauth_signature=([^&]*)", urldecode(re.group.1), "");
	if(req.http.X-Provided-Signature == "") {
		error 401 "Missing Signature";
	}
	set req.http.X-Ordered-Url = boltsort.sort(req.url);
	set req.http.X-Parameters = regsub(regsub(req.http.X-Ordered-Url, ".*\?", ""), "&oauth_signature=[^&]*", "");
	set req.http.X-Base-String-Uri = 
		if(req.http.Fastly-SSL, "https", "http") 
		"://"
		std.tolower(req.http.host)
		req.url.path;
	set req.http.X-Signature-Base-String = 
		req.request
		"&"
		urlencode(req.http.X-Base-String-Uri)
		"&"
		urlencode(req.http.X-Parameters);

	set req.http.X-Calculated-Signature = digest.hmac_sha1_base64(
			req.http.X-Consumer-Secret "&" req.http.X-Access-Token-Secret, 
			req.http.X-Signature-Base-String);

	unset req.http.X-Consumer-Secret;
	unset req.http.X-Access-Token-Scret;
	unset req.http.X-Base-String-Uri;

	if(req.http.X-Provided-Signature != req.http.X-Calculated-Signature) {
		error 401 "Invalid OAuth Signature";
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
	set resp.http.X-Consumer-Key = req.http.X-Consumer-Key;
	set resp.http.X-Access-Token = req.http.X-Access-Token;
	set resp.http.X-Provided-Signature = req.http.X-Provided-Signature;
	set resp.http.X-Calculated-Signature = req.http.X-Calculated-Signature;
	set resp.http.X-Parameters = req.http.X-Parameters;
	set resp.http.X-Signature-Base-String = req.http.X-Signature-Base-String;
	return(deliver);
}

sub vcl_error {
#FASTLY error
#DEPLOY error
}

sub vcl_pass {
#FASTLY pass
}
