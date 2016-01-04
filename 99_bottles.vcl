backend F_fake_backend {
	.host = "example.com";
	.port = "80";
	.dynamic = true;
	.connect_timeout = 5s;
	.first_byte_timeout = 15s;
	.probe = {
		.dummy = true;
	}
}

sub vcl_recv {
#FASTLY recv
	set req.backend = F_fake_backend;

	set req.http.X-Bottle = if(req.url ~ "(?i)bottle=([^&]*)", urldecode(re.group.1), "99");

	call set_next_bottle;

	set req.http.X-Verse = if(req.http.X-Verse,req.http.X-Verse,"") req.http.X-Bottle {" bottles of beer on the wall, "} req.http.X-Bottle {" bottles of beer.
Take one down and pass it around, "} req.http.X-Next-Bottle {" bottles of beer on the wall.
"};

	if(req.http.X-Bottle == "0") {
		error 996;
	}
	return(lookup);
}

sub vcl_fetch {
#FASTLY fetch

	if(req.restarts > 0) {
		set beresp.http.Fastly-Restarts = req.restarts;
	}
	return(deliver);
}

sub vcl_deliver {
#FASTLY deliver
	set resp.http.X-Verse = req.http.X-Verse;
	set resp.http.X-Bottle = req.http.X-Bottle;
	set resp.http.X-Next-Bottle = req.http.X-Next-Bottle;

	if(req.restarts == 2) {
		# For now, limit to 3 bottles as we can only restart 3 times
		set req.http.X-Next-Bottle = "0";
	}

	set req.url = "/?bottle=" req.http.X-Next-Bottle;

	if(req.restarts < 3) {
		restart;
	}
	return(deliver);
}

sub set_next_bottle {
	set req.grace = 1d;
	set req.http.X-Original-Grace = req.grace;
	set req.grace = std.atoi(req.http.X-Bottle);
	set req.grace -= 1s;
	set req.http.X-Next-Bottle = regsub(req.grace, "\..*", "");
	set req.grace = std.atoi(req.http.X-Original-Grace);
}

sub vcl_error {
#FASTLY error
	if(obj.status == 996) {
		set obj.status = 200;
		set obj.response = "Cheers!";
		synthetic req.http.X-Verse;
		return (deliver);
	}
}
