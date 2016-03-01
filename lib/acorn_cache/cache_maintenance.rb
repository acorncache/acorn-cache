class Rack::AcornCache
  class CacheMaintenance
    attr_reader :response, :cache_key, :server_response, :cached_response

    def initialize(cache_key, server_response, cached_response)
      @cache_key = cache_key
      @server_response = server_response
      @cached_response = cached_response
    end

    def update_cache
      if !server_response
        @response = cached_response.add_acorn_cache_header!
      elsif !server_response.cacheable? && !server_response.status_304?
        @response = server_response
      elsif server_response.cacheable?
        @response = server_response.cache!(cache_key)
      elsif cached_response.matches?(server_response)
        @response = cached_response.update_date_and_recache!(cache_key)
      else
        @response = server_response
      end

      self
    end
  end
end
