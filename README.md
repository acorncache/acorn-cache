# AcornCache

AcornCache is a Ruby HTTP proxy caching library that is lightweight, configurable and can be easily integrated with any Rack-based web application.

Features currently available include the following:

* Adheres to HTTP 1.1 protocols and RFC 2616 standards
* Customized Page Rules on a global and per-page basis
* Respects Cache-Control headers
* Respects Conditional Requests
* Works with any Rack-based framework   

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'acorn_cache'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acorn_cache

## Configuration

####Rails
AcornCache must be included in the middleware pipeline of a Rails application.  To include it in the rack, add the following config option to your ```config/environment.rb```:

```ruby
config.middleware.use "Rack::AcornCache"
```

You should now see ```Rack::AcornCache``` listed in the middleware pipeline when you run `rake middleware`.

AcornCache has a range of configuration options that can be configured both globally and on a page-by-page basis.  Create an initializer:

```
config/initializers/acorn_cache.rb
```

And include your configuration options (example below):

```
Rack::AcornCache.configure do |config|
  config.cache_everything = true
  config.default_acorn_cache_ttl = 3600
  config.page_rules = {
    "http://example.com/*.js" => { browser_cache_ttl: 30 },
      "another_url" => { acorn_cache_ttl: 100 },
      "foo.com" => { respect_existing_headers: true }
    }
end
```

TODO: Add configuration instructions for other platforms here.

## Page Rules

You can set Page Rules in AcornCache at the global (or default) level, as well as, on a page-by-page basis.  

#### Global Page Rules
Global configuration options can be set directly on the config block variable in your configuration initializer and include the following:

* `cache_everything` - when set to `true`, AcornCache will attempt to cache all incoming HTTP `GET` requests according to its default behavior.  For more information concerning the "out-of-the-box" caching rules that define AcornCache's default behavior, please refer to the Further Information section below.

* `default_acorn_cache_ttl` - sets the time (in seconds) that will be applied as an `s-maxage` Cache-Control header.  This will be applied to all pages unless overridden by a specific page rule as described below.

* `default_browser_cache_ttl` - sets the time (in seconds) that will be applied as an `maxage` Cache-Control header.  This will be applied to all pages unless overridden by a specific page rule as described below.

* `default_ignore_query_params` - when set to `true`, AcornCache will ignore any query parameters contained in the url of the incoming HTTP request.

#### Individual Page Rules
Configuration options can be set for individual 'whitelisted' pages via the `page-rules` method when called on the `config` block variable in your configuration initializer. `page-rules` can be set as a hash; the key being the url of the page (or pages) for which you are setting the rule, and the value being the caching rule(s) you are setting for that particular page.

AcornCache provides you with three options for defining the urls that you want to cache:

* You can define a singular page explicitly:

  `"http://www.foobar.com/baz" => { acorn_cache_ttl: 100 }`

* You can use wildcards to identify multiple pages for a which a given rule (or set of rules) applies:

  `"http://foo*.com" => { browser_cache_ttl: 86400" }`
* You can use a `Regexp`:

  `/https?:\/\/[\S]+/ => { respect_existing_headers: true }`

In addition, AcornCache provides you with the ability to respect the cache control headers that were provided from the client or origin server.  This can be achieved by setting `respect_existing_headers: true` for a page or given set of pages.

## Further Information

AcornCache's rules and caching guidelines strictly follow HTTP 1.1 protocols and RFC 2616 standards.  [This flow chart](http://i.imgur.com/o63TJAa.jpg) details the logic and rules that AcornCache is built upon and defines its default behavior.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/acorncache/acorn-cache.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
