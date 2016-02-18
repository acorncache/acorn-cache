require 'acorn_cache/redis_cache'

class Rack::AcornCache
  class CacheReader

    attr_reader :json_cached_response

    def initialize(request_path)
      @request_path = request_path
    end

    def hit?
      response = RedisCache.redis.get(request_path)
      return false unless response
      @json_cached_response = response
    end

    def cached_response_hash
      JSON.parse(json_cached_response)
    end

    private

    attr_reader :request_path
  end
end
