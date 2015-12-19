# Fastly VCL Experiments
Various experiments around Fastly's implementation of Varnish VCL

## Edge OAuth 1.0 Signature Validation (oauth_sig_check.vcl)
A proof-of-concept demonstrating the the ability to validate OAuth 1.0 HMAC-SHA1 signatures within VCL without having to validate the request against an authentication service by using a combination of Fastly's built in cryptographic functions and edge dictionaries.

* Only supports GET requests, where the OAuth parameters are passed on the URL.
* Only supports 2-legged auth but could easily support 3-legged too.

