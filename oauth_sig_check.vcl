
table consumer_secrets {
	"foo": "foo_secret"
}

table access_tokens {
	"bar": "bar_secret"
}

sub vcl_recv {
#FASTLY recv
#DEPLOY recv
	declare local var.consumer_key STRING;
	declare local var.consumer_secret STRING;
	declare local var.access_token STRING;
	declare local var.access_token_secret STRING;
	declare local var.provided_signature STRING;
	declare local var.parameters STRING;
	declare local var.base_string_uri STRING;
	declare local var.base_string STRING;
	declare local var.calculated_signature STRING;
	declare local var.timestamp STRING;

	set var.consumer_key = if(req.url ~ "(?i)oauth_consumer_key=([^&]*)", 
			urldecode(re.group.1), "");
	if(var.consumer_key == "") {
		error 401 "Missing Consumer Key";
	}
	set var.consumer_secret = table.lookup(consumer_secrets, var.consumer_key, "");
	if(var.consumer_secret == "") {
		error 401 "Invalid Consumer Key";
	}
	set var.access_token = if(req.url ~ "(?i)oauth_token=([^&]*)", 
			urldecode(re.group.1), "");
	if(var.access_token != "") {
		set var.access_token_secret = table.lookup(access_tokens, var.access_token, "");
		if(var.access_token_secret == "") {
			error 401 "Invalid Access Token";
		}
	} else {
		set var.access_token_secret = "";
	}
	set var.provided_signature = if(req.url ~ "(?i)oauth_signature=([^&]*)", 
			urldecode(re.group.1), "");
	if(var.provided_signature == "") {
		error 401 "Missing Signature";
	}
	set var.parameters = regsub(
			regsub(boltsort.sort(req.url), ".*\?", ""), 
			"&oauth_signature=[^&]*", "");
	set var.base_string_uri = 
		if(req.http.Fastly-SSL, "https", "http") 
			"://"
				std.tolower(req.http.host)
				req.url.path;
	set var.base_string = 
		req.request
		"&"
		urlencode(var.base_string_uri)
		"&"
		urlencode(var.parameters);

	set var.calculated_signature = digest.hmac_sha1_base64(
			var.consumer_secret "&" var.access_token_secret, 
			var.base_string);

	if(!digest.secure_is_equal(var.provided_signature, 
			var.calculated_signature)) {
		error 401 "Invalid OAuth Signature";
	}

	set var.timestamp = if(req.url ~ "(?i)oauth_timestamp=([0-9]*)", 
			urldecode(re.group.1), "");
	if(var.timestamp == "") {
		error 401 "Missing/Invalid Timestamp";
	}

	if(time.is_after(
				now,
				time.add(std.integer2time(std.atoi(var.timestamp)), 30m))) {
		error 401 "Timestamp expired";
	}

	if(time.is_after(
				std.integer2time(std.atoi(var.timestamp)),
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
	return(deliver);
}

sub vcl_error {
#FASTLY error
#DEPLOY error
}

sub vcl_pass {
#FASTLY pass
}
