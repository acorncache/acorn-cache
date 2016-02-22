class Rack::AcornCache
  module CacheMaintenance
    def self.update_cache_with(request_path, server_response, cached_response)
      return cached_response unless server_response
      return server_response unless server_response.cacheable? ||
                                    server_response.status_304?
      return server_response.cache! if server_response.cacheable?
      return cached_response.update! if cached_repsonse.matches?(server_response)
      server_response
    end
  end
end
