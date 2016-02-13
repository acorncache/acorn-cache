require 'rack'
require 'redis_cache'
require 'config'
require 'rack_response'
require 'cached_response'
require 'request'

class AcornCache
  def initialize(app)
    @app = app
    @config = Config.new
  end

  def call(env)
    @request = Request.new(env)

    if return_cached_response?
      cached_response.add_x_from_acorn_cache_header
      return cached_response.finish
    end

    status, headers, body = @app.call(env)
    @rack_response = RackResponse.new(body, status, headers)

    cache_rack_response_if_eligible
    rack_response.finish
  end

  private

  attr_reader :request, :rack_response

  def cache_rack_response_if_eligible
    return unless request.get? &&
                  rack_response.eligible_for_caching?(paths_whitelist)

    rack_response.add_from_acorn_cache_header
    redis.set(rack_response.path, rack_response.finish.to_json)
  end

  def return_cached_response?
    paths_whitelist.include?(request.path) && cached_response
  end

  def paths_whitelist
    @paths_whitelist ||= config.paths_whitelist
  end

  def cached_response
    @cached_response ||=
      cached_response? || CachedResponse.new(cached_response_hash)
  end

  def cached_response?
    json_cached_response
  end

  def json_cached_response
    @json_cached_response ||= redis.get(request.path)
  end

  def cached_reponse_hash
    JSON.parse(json_cached_response)
  end

  def redis
    RedisCache.redis
  end
end
