require 'rack/request'
require 'acorn_cache/cache_control_header'

class Rack::AcornCache
  class Request < Rack::Request
    extend Forwardable
    def_delegators :@cache_control_header, :no_cache, :max_age, :max_fresh,
                   :max_stale

    def initialize(env)
      super
      @cache_control_header = CacheControlHeader.new(@env["HTTP_CACHE_CONTROL"])
    end
  end
end
