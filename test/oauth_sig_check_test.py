import requests
import os
from requests_oauthlib import OAuth1
from oauthlib.oauth1 import SIGNATURE_TYPE_QUERY
from nose.tools import assert_equals, assert_regex

proxies = {
    'http': 'http://nonssl.global.fastly.net:80'
}

def test_returns_200_when_authentication_passes():
    service_host = os.environ['SERVICE_HOST']
    oauth = OAuth1('foo', client_secret='foo_secret',
             signature_type=SIGNATURE_TYPE_QUERY)
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            url=url, 
            auth=oauth,
            proxies=proxies)

    assert_regex(response.text, 'Authenticated!')
    assert_equals(response.status_code, 200)

def blah():
    return

