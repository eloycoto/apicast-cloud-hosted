BEGIN {
    $ENV{TEST_NGINX_APICAST_BINARY} ||= 'rover exec apicast';
}

use strict;
use warnings FATAL => 'all';
use Test::APIcast::Blackbox 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: rate limit without limit
The module does not crash without configuration.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit" },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request
GET /t
--- response_body
GET /t HTTP/1.1
--- error_code: 200
--- no_error_log
[error]



=== TEST 2: rate limit with limit
The module does rate limiting.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit", "configuration": { "limit": 1 } },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request eval
["GET /t", "GET /t"]
--- error_code eval
[200, 503]
--- grep_error_log
rejected request over limit, key: localhost
--- grep_error_log_out eval
["", "rejected request over limit, key: localhost"]



=== TEST 3: rate limit with limit and burst
Delays the request.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit", "configuration": { "limit": 1, "burst": 1 } },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request eval
["GET /t", "GET /t"]
--- response_body eval
["GET /t HTTP/1.1\n", "GET /t HTTP/1.1\n" ]
--- error_code eval
[200, 200]
--- grep_error_log
delaying request: localhost for 1s, excess: 1
--- grep_error_log_out eval
["", "delaying request: localhost for 1s, excess: 1"]



=== TEST 4: rate limit with custom status
Sends the custom status code.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit", "configuration": { "limit": 1, "status": 429 } },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request eval
["GET /t", "GET /t"]
--- error_code eval
[200, 429]
