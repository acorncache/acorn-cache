class Rack::AcornCache
  class CacheWriter
    include Concurrent::Async

    def initialize
      super
    end

    def write(cache_key, serialized_response)
      storage.set(cache_key, serialized_response)
    end

    private

    def storage
      Rack::AcornCache.configuration.storage
    end
  end
end
