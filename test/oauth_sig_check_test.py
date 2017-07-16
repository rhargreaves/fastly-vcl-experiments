import requests
import os
from requests_oauthlib import OAuth1
from oauthlib.oauth1 import SIGNATURE_TYPE_QUERY
from nose.tools import assert_equals, assert_regex

proxies = {
    'http': 'http://nonssl.global.fastly.net:80'
}
service_host = os.environ['SERVICE_HOST']

def test_returns_200_when_authentication_passes():
    oauth = OAuth1('foo', client_secret='foo_secret',
             signature_type=SIGNATURE_TYPE_QUERY)
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            url=url, 
            auth=oauth,
            proxies=proxies)

    assert_regex(response.text, 'Authenticated!')
    assert_equals(response.status_code, 200)

def test_returns_401_when_consumer_key_missing():
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            url=url, 
            proxies=proxies)

    assert_regex(response.text, 'Missing Consumer Key')
    assert_equals(response.status_code, 401)
