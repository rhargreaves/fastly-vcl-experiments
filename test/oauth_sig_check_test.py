import requests
import os
from requests_oauthlib import OAuth1
from oauthlib.oauth1 import SIGNATURE_TYPE_QUERY
from nose.tools import assert_equals, assert_regex
from freezegun import freeze_time
from datetime import datetime, timedelta

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

def test_returns_401_when_consumer_key_not_defined():
    oauth = OAuth1('unknown_key', 
                   client_secret='unknown_secret',
                   signature_type=SIGNATURE_TYPE_QUERY)
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            auth=oauth,
            url=url, 
            proxies=proxies)

    assert_regex(response.text, 'Invalid Consumer Key')
    assert_equals(response.status_code, 401)

def test_returns_401_when_access_token_not_defined():
    oauth = OAuth1('foo', 
            client_secret='foo_secret',
            resource_owner_key='unknown_token', 
            resource_owner_secret='unknown_secret',
            signature_type=SIGNATURE_TYPE_QUERY)
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            auth=oauth,
            url=url, 
            proxies=proxies)

    assert_regex(response.text, 'Invalid Access Token')
    assert_equals(response.status_code, 401)

def test_returns_401_when_missing_signature():
    url = 'http://{0}/baz?oauth_consumer_key=foo'.format(service_host)
    response = requests.get(
            url=url, 
            proxies=proxies)

    assert_regex(response.text, 'Missing Signature')
    assert_equals(response.status_code, 401)

def test_returns_401_when_signature_invalid():
    oauth = OAuth1('foo', client_secret='wrong_secret',
             signature_type=SIGNATURE_TYPE_QUERY)
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            url=url, 
            auth=oauth,
            proxies=proxies)

    assert_regex(response.text, 'Invalid OAuth Signature')
    assert_equals(response.status_code, 401)

@freeze_time('2017-01-01')
def test_returns_401_when_timestamp_is_too_old():
    oauth = OAuth1('foo', client_secret='foo_secret',
             signature_type=SIGNATURE_TYPE_QUERY)
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            url=url, 
            auth=oauth,
            proxies=proxies)

    assert_regex(response.text, 'Timestamp expired')
    assert_equals(response.status_code, 401)

@freeze_time(datetime.now() + timedelta(hours=1))
def test_returns_401_when_timestamp_is_in_future():
    oauth = OAuth1('foo', client_secret='foo_secret',
             signature_type=SIGNATURE_TYPE_QUERY)
    url = 'http://{0}/baz'.format(service_host)
    response = requests.get(
            url=url, 
            auth=oauth,
            proxies=proxies)

    assert_regex(response.text, 'Timestamp too far in future')
    assert_equals(response.status_code, 401)
