class Rack::AcornCache
  module CacheMaintenance
    def self.update_cache_with(request_path, server_response, cached_response)
      return cached_response.add_acorn_cache_header! unless server_response
      if !server_response.cacheable? && !server_response.status_304?
        server_response
      elsif server_response.cacheable?
        server_response.cache!(request_path)
      elsif cached_response.matches(server_response)
        cached_response.update!(request_path)
      else
        server_response
      end
    end
  end
end
