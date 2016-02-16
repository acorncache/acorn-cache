require 'rack'
require "cache_control_restrictable"

class Request < Rack::Request
  include CacheControlRestrictable

  def accepts_cached_response?(paths_whitelist)
    get? && paths_whitelist.include?(path) && !caching_restrictions?
  end
end
