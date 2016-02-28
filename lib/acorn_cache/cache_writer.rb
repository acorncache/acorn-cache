require 'acorn_cache/redis_cache'

class Rack::AcornCache
  module CacheWriter
    def self.write(cache_key, serialized_response)
      RedisCache.redis.set(cache_key, serialized_response)
    end
  end
end
