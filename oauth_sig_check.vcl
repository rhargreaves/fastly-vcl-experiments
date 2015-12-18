
table consumer_secrets {
	"foo": "super_secret"
}

sub vcl_recv {
#FASTLY recv
#DEPLOY recv
	set req.url = boltsort.sort(req.url);
	set req.http.X-Consumer-Key = regsub(req.url, ".*\?.*oauth_consumer_key=(.*?)(&|$)", "\1");
	set req.http.X-Consumer-Secret = table.lookup(consumer_secrets, req.http.X-Consumer-Key);
	set req.http.X-Provided-Signature = regsub(req.url, ".*\?.*oauth_signature=(.*?)(&|$)", "\1");
	set req.http.X-Parameters = regsub(req.url, ".*\?", "");
	set req.http.X-Parameters = regsub(req.http.X-Parameters, "&oauth_signature=[^&]*", "");
	
	set req.http.X-Base-String-Uri = 
		if(req.http.Fastly-SSL,"https","http") 
		"://" 
		std.tolower(req.http.host)
		req.url.path;

	# Construct according to https://tools.ietf.org/html/rfc5849#page-18
	set req.http.X-Signature-Base-String = 
		req.request
		"&"
		req.http.X-Base-String-Uri
		"&"
		req.http.X-Parameters;

	set req.http.X-Calculated-Signature = urlencode(digest.hmac_sha1_base64(
		req.http.X-Consumer-Secret "&", req.http.X-Signature-Base-String));

	if(req.http.X-Provided-Signature != req.http.X-Calculated-Signature) {
		error 401 "Invalid OAuth signature";
	}


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
	set resp.http.X-Consumer-Secret = req.http.X-Consumer-Secret;
	set resp.http.X-Provided-Signature = req.http.X-Provided-Signature;
	set resp.http.X-Calculated-Signature = req.http.X-Calculated-Signature;
	set resp.http.X-Parameters = req.http.X-Parameters;
	set resp.http.X-Base-String-Uri = req.http.X-Base-String-Uri;
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
