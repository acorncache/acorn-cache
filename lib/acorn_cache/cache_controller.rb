class Rack::AcornCache
  class CacheController
    def initialize(request, cached_response, &hit_server)
      @request = request
      @cached_response = cached_response
      @hit_server = hit_server
      @config = config
    end

    def run
      if !request_requires_server_response?(paths_whitelist)
        rack_response(no_cache: true)
      elsif cached_response_returnable_for_request?
        cached_response.add_x_from_acorn_cache_header!
      else
        rack_response.update_date!
      end
    end

    private

    def request_requires_server_response?
      request.get? && paths_whitelist.include?(path) &&
        !resuest_cache_control_header.no_cache
    end

    def cached_response_returnable_for_request?
      return false if cached_control_headers_prohibit_return?
      Time.now <= max_cached_response_returnable_date
    end

    def cached_control_headers_prohibit_return?
      %w(private, no-cache, no-store, must-revalidate).any? do |directive|
        cached_control_header.send(:directive)
      end
    end

    def max_cached_response_returnable_date
      if cached_response_fresh? && !request_cache_control_header.max_age
        cached_response_expiration_date
      elsif cached_response_fresh? && request_max_age_more_restrictive?
        Time.httpdate(cached_response.date_header) + request.max_age
      elsif cached_response_fresh? && request_cache_control_header.max_fresh
        cached_response_expiration_date - request_cache_control_header.max_fresh
      elsif cached_response_fresh?
        cached_response_expiration_date
      elsif request_cache_control_header.max_stale
        cached_response_expiration_date + request_cache_control_header.max_stale
      else
        Time.now
      end
    end

    def request_max_age_more_restrictive?
      max_age = request.s_max_age || request.max_age
      return false unless max_age
      max_age < response.max_age
    end

    def request_s_max_age_more_restrictive?
      request.s_max_age && request.s_max_age < response.max_age
    end

    def cached_response_fresh?
      Time.now < cached_response_expiration_date
    end

    def cached_response_expiration_date
      if cached_response_header.max_age
        cached_response_header.max_age
      elsif cached_response.expiration_header
        Time.httpdate(cached_response.expiration_header)
      else
        Time.now
      end
    end

    def rack_response(no_cache: false)
      status, headers, response = hit_server.call
      return RackResponse.new(status, headers, response, no_cache: no_cache)
    end

    def request_cache_control_header
      @request_cache_control_header ||=
        CacheControlHeader.new(request.cache_control_header)
    end

    def response_cache_control_header
      @response_cache_control_header ||=
        CacheControlHeader.new(response.cache_control_header)
    end

    def paths_whitelist
      @config.paths_whitelist
    end
  end
end
