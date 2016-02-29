class Rack::AcornCache
  module CacheWriter
    def self.write(cache_key, serialized_response)
      storage.set(cache_key, serialized_response)
    end

    private

    def self.storage
      Rack::AcornCache.configuration.storage
    end
  end
end
