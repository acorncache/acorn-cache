class Rack::AcornCache
  module CacheMaintenance
    def self.update_cache_with(request_path, server_response, cached_response)
      return cached_response.add_acorn_cache_header! unless server_response
      unless server_response.cacheable? || server_response.status_304?
        return server_response
      end

      if server_response.cacheable?
        server_response.cache!(request_path)
      else cached_response.matches?(server_response)
        cached_response.update_date_and_recache!(request_path)
      end
    end
  end
end
