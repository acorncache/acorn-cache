# AcornCache

AcornCache is a ruby HTTP proxy caching library that is lightweight, configurable and can be easily integrated with any Rack-based web application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'acorn_cache'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acorn_cache

## Basic Usage

####Rails
AcornCache must be included in the middleware pipeline of a Rails application.  To include it in the rack, add the following config option to your ```config/environment.rb```:

```ruby
config.middleware.use "Rack::AcornCache"
```

You should now see ```Rack::AcornCache``` listed in the middleware pipeline when you  run `rake middleware`.

TODO: Add installation instructions for other platforms here.

## Further Information

AcornCache's rules and caching guidelines strictly follow HTTP 1.1 protocols and RFC 2616 standards.  [The following flow chart](http://imgur.com/o63TJAa) details the logic and rules that AcornCache is built on.

![AcornCache rules flow chart](http://imgur.com/o63TJAa)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/acorncache/acorn-cache.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
