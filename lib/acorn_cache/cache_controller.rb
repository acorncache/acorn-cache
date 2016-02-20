require 'acorn_cache/cache_control_header'

class Rack::AcornCache
  class CacheController
    def initialize(request, cached_response, config, &hit_server)
      @request = request
      @cached_response = cached_response
      @config = config
      @hit_server = hit_server
    end

    def response
      if request_requires_server_response? ||
          !cached_response_returnable_for_request?
        status, headers, response = hit_server.call
        RackResponse.new(status, headers, response)
      else
        cached_response.add_x_from_acorn_cache_header!
        cached_response
      end
    end

    private

    attr_reader :request, :cached_response, :config, :hit_server

    def request_requires_server_response?
      !@config.paths_whitelist.include?(request.path) || request.no_cache
    end

    def cached_response_returnable_for_request?
      return false unless cached_response
      if cached_response.fresh?
        return true unless request.max_age || request.max_fresh
        if request.max_age
          cached_response.date + request.max_age >= Time.now
        elsif request.max_fresh
          cached_response.expiration_date - request.max_fresh >= Time.now
        end
      else
        return false unless request.max_stale
        return true unless request.max_stale.is_a?(Integer)
        (cached_response.expiration_date + request.max_stale) >= Time.now
      end
    end
  end
end
