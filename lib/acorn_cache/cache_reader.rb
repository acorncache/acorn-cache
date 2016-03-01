require 'json'

class Rack::AcornCache
  module CacheReader
    def self.read(cache_key)
      response = storage.get(cache_key)
      return false unless response
      response_hash = JSON.parse(response)
      CachedResponse.new(response_hash)
    end

    private

    def self.storage
      Rack::AcornCache.configuration.storage
    end
  end
end
