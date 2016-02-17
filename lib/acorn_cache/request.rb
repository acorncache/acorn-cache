require 'rack/request'
require 'cache_control_restrictable'

class Rack::AcornCache
  class Request < Rack::Request
    include CacheControlRestrictable

    def accepts_cached_response?(paths_whitelist)
      get? && paths_whitelist.include?(path) && !caching_restrictions?
    end

    def cache_control_header
      @env["HTTP_CACHE_CONTROL"]
    end
  end
end
