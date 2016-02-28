# AcornCache

AcornCache is a Ruby HTTP proxy caching library that is lightweight, configurable and can be easily integrated with any Rack-based web application. AcornCache allows you to improve page load times and lighten the load on your server by allowing you to implement an in-memory cache shared by every client requesting a resource on your server.

Features currently available include the following:

* Honors origin server cache control directives according to RFC2616 standards unless directed otherwise.
* Allows for easily configuring:
    * which resources should be cached,
    * for how long, and 
    * whether query params should be ignored
* Allows for basic browser caching behavior modification by changing out cache control header directives.
* Uses Redis to store cached server responses.

##Getting Started

####Installation

Add this line to your application's Gemfile:

```ruby
gem 'acorn_cache'
```

And then execute:

    $ bundle

Or install it yourself:

    $ gem install acorn_cache


AcornCache must be included in the middleware pipeline of your Rails or Rack application.

With Rails, add the following config option to the appropriate environment, probably ```config/environments/production.rb```:

```ruby
config.middleware.use Rack::AcornCache
```

You should now see ```Rack::AcornCache``` listed in the middleware pipeline when you run `rake middleware`.

For non-Rails Rack apps, just include the following in your rackup (.ru) file:
```
require 'acorn_cache'

use Rack::AcornCache
```

####Setting Up Storage
By default, AcornCache uses Redis to store server responses. You must include
your Redis host, port, and password (if you have one set) as environment variables.

```
ACORNCAHE_REDIS_HOST="your_host_name"
ACORNCACHE_REDIS_PORT="your_port_number"
ACRONCACE_REDIS_PASSWORD="your_password"
```

####Configuration
AcornCache has a range of configuration options.  If you're using Rails, set them in an initializer: `config/initializers/acorn_cache.rb`

Without configuration, AcornCache won't cache anything.  Two basic configuration
patterns are possible. The most common will be to specify page rules telling
AcornCache how long to store a resource.

The config below specifies two URLs to cache and specifies the time to live, i.e., the time the resource at that location should live in AcornCache and the browser cache. With this config, AcornCache will only cache the resources at these two URLs:

```
Rack::AcornCache.configure do |config|
  config.page_rules = {
    "http://example.com/" => { browser_cache_ttl: 30 },
    "http://foo.com/bar" => { acorn_cache_ttl: 100 },
  }
end
```

If you choose to do so, you can have AcornCache act as an RFC compliant
shared proxy-cache for every resource on your server. For information concerning standard RFC caching rules,
please refer to the Further Information section below. To operate in this mode, just set:

```
config.cache_everything = true
```
Keep in mind that you can override standard caching behavior even when in cache
everything mode by specifying a page rule.

See below for all the available options.

## Page Rules
Configuration options can be set for individual URLs via the
`page-rules` config option. The value of `page-rules` must be set to a hash. The hash must have a key that is either 1) a URL string or 2) a pattern that matches the URL of the page(s) for which you are setting the rule, and a value that specifies the caching rule(s) for the page or pages. Here's an example:

```ruby
Rack::AcornCache.configure do |config|
  config.page_rules = {
    { "http://foo.com" => { acorn_cache_ttl: 3600,
                            broswer_cache_ttl: 800,
      "http://bar.com/*" => { broswer_cache_ttl: 3600,
                              ignore_query_params: true }
      /^https+://.+\.com/ => { respect_default_header: true,
                               ignore_query_params: true }
    }
end
```
####Deciding Which Resources Are Cached
Resources best suited for caching are public (not behind authentication) and don't change very often.
AcornCache provides you with three options for defining the URLs for the resources that you want to cache:

1. You can define a single URL explicitly:

  `"http://www.foobar.com/baz" => { acorn_cache_ttl: 100 }`

2. You can use wildcards to identify multiple pages for a which a given set of rules applies:

  `"http://foo*.com" => { browser_cache_ttl: 86400" }`

3. You can use regex pattern matching simply by using a `Regexp` object as the
  key:

  `/^http://.+\..+$/` => { acorn_cache_ttl: 100 }`


####Deciding How Resources Are Cached
#####Override Existing Cache Control Headers
Suppose you don't know or want to change the cache control headers included
from your server.  AcornCache gives you the ability to control how a resource is
cached by both AcornCache and the browser cache simply by specifying the
appropriate page rule saettings.

AcornCache provides three options, which can be set either as defaults or within
individual page rules.

1. `acorn_cache_ttl`
This option specifies the time a resource should live in AcornCache before
expiring.  It works by setting overriding the `s-maxage` directive in your cache control
headers with the specified value. Time should be given in seconds. It also removes any directives that would
prevent caching in a shared proxy cache, like `private` or `no-store`.

2. `browser_cache_ttl`
This option specified the time in seconds a resource should live in private
browser caches before expiring.  It works by overriding the `max-age` directive
in the cache contreol header with the specified value.  It also removes any
directivs that would prevent caching in a private cache, like 'no-store'.

3. `ignore-query-params`
If the query params in a request shouldn't effect the response from your server,
you can set this option as true so that all requests for a URL, regardless of
the specified params, share the same cache entry. This means that if a resource
that lives at `http://foo.com` is cached with AcornCache, a request to
`http://foo.com/?bar=baz` will respond with that cached resource without creating another
cache entry.

These three options can be set either as defaults or for individual page rules.
Default settings apply to any page that AcornCache is allowed to cache unless
they are overwritten by a page rule. For example, if your
config looks like this...

```ruby
RackAcornCache.configure do |config|
  config.default_acorn_cache_ttl = 30
  config.page_rules = {
   "http://foo.com" => { use_defaults: true }
   "http://bar.com" => { acorn_cache_ttl: 100 }
end
```

...then the server response returned by a request to `foo.com` will be cached in AcornCache for 30 seconds, but the server response returned by a request to `bar.com` will be cached for 100 seconds.

#####Respect Existing Cache Control Headers
AcornCache provides you with the ability to respect the cache control headers that were provided from the client or origin server.  This can be achieved by setting `respect_existing_headers: true` for a page or given set of pages. This option is useful when you don't want to cache everything but you also want to control caching behavior by ensuring that responses come from your server with the proper cache control headers.  If you choose this option, you will likely want to ensure your response has an `s-maxage` directive, as AcornCache operates as a shared cache.

## Further Information

AcornCache's rules and caching guidelines strictly follow HTTP 1.1 protocols and RFC 2616 standards.  [This flow chart](http://i.imgur.com/o63TJAa.jpg) details the logic and rules that AcornCache is built upon and defines its default behavior.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/acorncache/acorn-cache.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
