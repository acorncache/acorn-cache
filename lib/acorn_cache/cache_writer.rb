require 'acorn_cache/redis_cache'

class Rack::AcornCache
  module CacheWriter
    def write(request_path, serialized_response)
      RedisCache.redis.set(request_path, serialized_response)
    end
  end
end
