class Rack::AcornCache
  class CacheMaintenance
    attr_reader :response, :request_path, :server_response, :cached_response

    def initialize(request_path, server_response, cached_response)
      @request_path = request_path
      @server_response = server_response
      @cached_response = cached_response
    end

    def update_cache
      if !server_response
        @response = cached_response.add_acorn_cache_header!
      elsif !server_response.cacheable? && !server_response.status_304?
        @response = server_response
      elsif server_response.cacheable?
        @response = server_response.cache!(request_path)
      elsif cached_response.matches?(server_response)
        @response = cached_response.update_date_and_recache!(request_path)
      else
        @response = server_response
      end
    end
  end
end
