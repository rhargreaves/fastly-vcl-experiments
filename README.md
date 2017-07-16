# Fastly VCL Experiments
Various experiments around Fastly's implementation of Varnish VCL

## Edge OAuth 1.0 Signature Validation (oauth_sig_check.vcl)
A proof-of-concept demonstrating the ability to validate OAuth 1.0 HMAC-SHA1 signatures within VCL without having to validate the request against an authentication backend service by using a combination of Fastly's built-in cryptographic functions and edge dictionaries.

* Supports 2-legged and 3-legged auth flows.
* Validates timestamp (default expiration time is 30 minutes).

### Limitations
* Only supports GET requests, where the OAuth parameters are provided in the query string.
* Owing to differences between the OAuth percent encoding specification and the RFC3986 functions provided by Fastly, it is possible that an invalid signature may be produced by the code. In the event of an invalid signature being detected, you should allow the request to propogate to an actual OAuth authentication service to validate the signature. However, as long as parameters stick to common ASCII characters, it should work in the vast majority of cases.
* It will only provide limited protection against replay attacks as the nonce is not taken into consideration. It is therefore also unsuited for single-use URLs.

### Usage
Setup a Fastly service with a fake backend, and run:

```
$ curl 'http://<fastly_service_url>/?oauth_consumer_key=foo&oauth_nonce=801243096&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1450615933&oauth_token=bar&oauth_version=1.0&oauth_signature=dKVOZboE9tthtQzfCjqYsVYvkhU%3D'
```

As the above URL will have likely expired, you can use https://bettiolo.github.io/oauth-reference-page/ to generate a new URL.


All responses are synthetic. The actual backend will not be used.

### Tests
```
$ pip3 install --user -r requirements.txt
$ SERVICE_HOST=<fastly_service_host> nosetests
```

## Edge OAuth 1.0 Signature Validation (oauth_sig_check.vcl)
A proof-of-concept demonstrating the ability to validate OAuth 1.0 HMAC-SHA1 signatures within VCL without having to validate the request against an authentication backend service by using a combination of Fastly's built-in cryptographic functions and edge dictionaries.

## 99 Bottles of Beer (99_bottles.vcl)
An implmentation of the 99 bottles of beer song in VCL that works on Fastly's network (WIP)

The aim is to have the entire song returned in the response without explicitly referencing each bottle in the VCL (i.e. the bottle verses should be synthetically generated via some sort of loop or recursion).
