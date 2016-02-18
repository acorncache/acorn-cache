require 'acorn_cache/redis_cache'

class Rack::AcornCache
  class CacheWriter

    def initialize(rack_response, cached_response, request_path)
      @rack_response = rack_response
      @cached_response = cached_response
      @request_path = request_path
      @redis = RedisCache.redis
    end

    def update_cache
      update_cached_response_date_if_eligible
      cache_rack_response_if_eligible
    end

    private

    attr_reader :rack_response, :cached_response, :request_path, :redis

    def update_cached_response_date_if_eligible
      return unless cached_response && rack_response.eligible_for_updating?
      cached_response.update_date
      redis.set(request_path, cached_response.to_json)
    end

    def cache_rack_response_if_eligible
      return unless rack_response.eligible_for_caching?
      rack_response.add_date_header
      redis.set(request_path, rack_response.to_json)
    end
  end
end
