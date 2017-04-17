[![Build Status](https://travis-ci.org/acorncache/acorn-cache.svg?branch=master)](https://travis-ci.org/acorncache/acorn-cache)

![AcornCache](http://i.imgur.com/6zdrz8A.png?1)

AcornCache is a Ruby HTTP proxy caching library that is lightweight, configurable and can be easily integrated with any Rack-based web application. AcornCache allows you to improve page load times and lighten the load on your server by allowing you to implement an in-memory cache shared by every client requesting a resource on your server.

Features currently available include the following:

* Honors origin server cache control directives according to RFC2616 standards unless directed otherwise.
* Allows for easily configuring:
    * which resources should be cached,
    * for how long, and
    * whether query params should be ignored
* Allows for basic browser caching behavior modification by changing out cache control header directives.
* Uses Redis or Memcached to store cached server responses.
* Adds a custom header to mark responses returned from the cache (`X-Acorn-Cache: HIT`)
* Removes cookies from server responses prior to caching.

## Getting Started

[![Join the chat at https://gitter.im/acorncache/acorn-cache](https://badges.gitter.im/acorncache/acorn-cache.svg)](https://gitter.im/acorncache/acorn-cache?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

#### Installation

Add this line to your application's Gemfile:

```ruby
gem 'acorn_cache'
```

And then execute:

    $ bundle

Or install it yourself:

    $ gem install acorn_cache


AcornCache must be included in the middleware pipeline of your Rails or Rack application.

With Rails, add the following config option to the appropriate environment, probably ```config/environments/production.rb```.  Note that we recommend AcornCache be positioned at the top of your middleware stack.  Replace `Rack::Sendfile` in the example if necessary.

```ruby
config.middleware.insert_before(Rack::Sendfile, Rack::AcornCache)
```

You should now see ```Rack::AcornCache``` listed at the top of your middleware pipeline when you run `rake middleware`.

For non-Rails Rack apps, just include the following in your rackup (.ru) file:
```ruby
require 'acorn_cache'

use Rack::AcornCache
```

#### Setting Up Storage
By default, AcornCache uses Redis to store server responses. You must include
your Redis host, port, and password (if you have one set) as environment variables.

```
ACORNCACHE_REDIS_HOST="your_host_name"
ACORNCACHE_REDIS_PORT="your_port_number"
ACORNCACHE_REDIS_PASSWORD="your_password"
```
You may also choose to use memcached.  If so, set the URL (including host and
port) and, if you have SASL authentication, username and password.

```
ACORNCACHE_MEMCACHED_URL="your_url"
ACORNCACHE_MEMCACHED_USERNAME="your_username"
ACORNCACHE_MEMCACHED_PASSWORD="your_password"
```
To switch to Memcached, add the following line to your AcornCache config:
```ruby
config.storage = :memcached
```

#### Configuration
AcornCache has a range of configuration options.  If you're using Rails, set them in an initializer: `config/initializers/acorn_cache.rb`

Without configuration, AcornCache won't cache anything.  Two basic configuration
patterns are possible. The most common will be to specify page rules telling
AcornCache how long to store a resource.

The config below specifies two URLs to cache and specifies the time to live, i.e., the time the resource at that location should live in AcornCache and the browser cache. With this config, AcornCache will only cache the resources at these two URLs:



```ruby
if Rails.env.production?
  Rack::AcornCache.configure do |config|  
    config.page_rules = {
      "http://foo.com/"    => { browser_cache_ttl: 30 },
      "http://foo.com/bar" => { acorn_cache_ttl: 100 }
    }
  end
end
```


If you choose to do so, you can have AcornCache act as an RFC compliant
shared proxy-cache for every resource on your server. For information concerning standard RFC caching rules,
please refer to the Further Information section below. To operate in this mode, just set:

```ruby
config.cache_everything = true
```
Keep in mind that you can override standard caching behavior even when in cache everything mode by specifying a page rule.

See below for all available options.

## Page Rules
Configuration options can be set for individual URLs via the
`page-rules` config option. The value of `page-rules` must be set to a hash. The hash must have a key that is either 1) a URL string, or 2) a pattern that matches the URL of the page(s) for which you are setting the rule, and a value that specifies the caching rule(s) for the page or pages. Here's an example:

```ruby
Rack::AcornCache.configure do |config|
  config.page_rules = {
    "http://foo.com/"            => { acorn_cache_ttl: 1800,
                                      browser_cache_ttl: 800 },
    "http://foo.com/helpcenter*" => { browser_cache_ttl: 3600,
                                      ignore_query_params: true },
    /^https?:\/\/foo.com\/docs/  => { respect_existing_headers: true,
                                      ignore_query_params: true }
  }
end
```
#### Deciding Which Resources Are Cached
Resources best suited for caching are public (not behind authentication) and don't change very often.
AcornCache provides you with three options for defining the URLs for the resources that you want to cache:

1. You can define a single URL explicitly:
   ```ruby
   "http://foo.com/" => { acorn_cache_ttl: 100 }
   ```

2. You can use wildcards to identify multiple pages for a which a given set of rules applies:
   ```ruby
   "http://foo.com/helpcenter*" => { browser_cache_ttl: 86400 }
   ```

3. You can use regex pattern matching simply by using a `Regexp` object as the
  key:
   ```ruby
   /^https?:\/\/.+\.com/ => { acorn_cache_ttl: 100 }
   ```


#### Deciding How Resources Are Cached
##### Override Existing Cache Control Headers
Suppose you don't know or want to change the cache control headers provided by your server.  AcornCache gives you the ability to control how a resource is
cached by both AcornCache and the browser cache simply by specifying the
appropriate page rule settings.

AcornCache provides four options, which can be set either as defaults or within
individual page rules.

1. `acorn_cache_ttl` -
This option specifies the time a resource should live in AcornCache before
expiring.  It works by overriding the `s-maxage` directive in the cache control
header with the specified value. Time should be given in seconds. It also removes any directives that would
prevent caching in a shared proxy cache, like `private` or `no-store`.

2. `browser_cache_ttl` -
This option specifies the time in seconds a resource should live in private
browser caches before expiring.  It works by overriding the `max-age` directive
in the cache control header with the specified value.  It also removes any
directives that would prevent caching in a private cache, like `no-store`.

3. `ignore_query_params` -
If the query params in a request shouldn't affect the response from your server,
you can set this option to `true` so that all requests for a URL, regardless of
the specified params, share the same cache entry. This means that if a resource
living at `http://foo.com` is cached with AcornCache, a request to
`http://foo.com/?bar=baz` will respond with that cached resource without creating another
cache entry.

4. `must_revalidate` -
When set to `true`, the content of the cache will be checked against the origin server using `ETag` or `Last-Modified` headers.  With this configuration, AcornCache will not use a cache entry without first revalidating it with the origin server.

These four options can be set either as defaults or for individual page rules.
Default settings apply to any page that AcornCache is allowed to cache unless
they are overwritten by a page rule. For example, if your
config looks like this...

```ruby
RackAcornCache.configure do |config|
 config.default_acorn_cache_ttl = 30
 config.page_rules = {
  "http://foo.com/" => { use_defaults: true },
  "http://foo.com/helpdocs" => { acorn_cache_ttl: 100 }
 }
end
```

...then the server response returned by a request to `foo.com/` will be cached in AcornCache for 30 seconds, but the server response returned by a request to `foo.com/helpdocs` will be cached for 100 seconds.

##### Respect Existing Cache Control Headers
AcornCache provides you with the ability to respect the cache control headers that were provided from the client or origin server.  This can be achieved by setting `respect_existing_headers: true` for a page or given set of pages. This option is useful when you don't want to cache everything but you also want to control caching behavior by ensuring that responses come from your server with the proper cache control headers.  If you choose this option, you will likely want to ensure that your response has an `s-maxage` directive, as AcornCache operates as a shared cache.

## Further Information

AcornCache's rules and caching guidelines strictly follow RFC 2616 standards.  [This flow chart](http://i.imgur.com/o63TJAa.jpg) details the logic and rules that AcornCache is built upon and defines its default behavior.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/acorncache/acorn-cache.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
