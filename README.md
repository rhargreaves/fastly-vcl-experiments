# Fastly VCL Experiments
Various experiments around Fastly's implementation of Varnish VCL

## Edge OAuth 1.0 Signature Validation (oauth_sig_check.vcl)
A proof-of-concept demonstrating the the ability to validate OAuth 1.0 HMAC-SHA1 signatures within VCL without having to validate the request against an authentication service by using a combination of Fastly's built in cryptographic functions and edge dictionaries. Validating the signature within VCL opens up the possiblity of caching auth responses on the edge.

* Only supports GET requests, where the OAuth parameters are passed on the URL.
* Supports 2-legged and 3-legged auth flows.

### Limitations
* Owing to differences between the OAuth percent encoding specification and the RFC3986 functions provided by Fastly, it is possible that an invalid signature may be produced by the code. In the event of an invalid signature being detected, you should allow the request to propogate to an actual OAuth authentication service to validate the signature. However, as long as parameters stick to common ASCII characters, it should work in the vast majority of cases.
* It will not protect against replay attacks as the timestamp and nonce are not taken into consideration. It is therefore also unsuited for single-use URLs.

### Usage
Setup a Fastly service with a fake backend, and run:

```
$ curl 'http://<fastly_service_url>/?oauth_consumer_key=foo&oauth_nonce=801243096&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1450615933&oauth_token=bar&oauth_version=1.0&oauth_signature=dKVOZboE9tthtQzfCjqYsVYvkhU%3D'
```

All responses are synthentic. The actual backend will not be used.
