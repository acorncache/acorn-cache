require 'config'
require 'redis_cache'
require 'rack_response'
require 'cached_response'
require 'request'

class Rack::AcornCache
  def initialize(app)
    @app = app
    @config = Config.new
  end

  def call(env)
    @request = Request.new(env)

    if return_cached_response?
      cached_response.add_x_from_acorn_cache_header
      return cached_response.to_a
    end

    status, headers, body = @app.call(env)
    @rack_response = RackResponse.new(status, headers, body)
    cache_rack_response_if_eligible
    rack_response.to_a
  end

  private

  attr_reader :request, :rack_response, :config

  def cache_rack_response_if_eligible
    return unless request.get? && paths_whitelist.include?(request.path)
    rack_response.add_date_header
    redis.set(request.path, rack_response.to_json)
  end

  def return_cached_response?
    paths_whitelist.include?(request.path) && cached_response? &&
      cached_response.fresh?
  end

  def paths_whitelist
    @paths_whitelist ||= config.paths_whitelist
  end

  def cached_response
    @cached_response ||= CachedResponse.new(cached_response_hash)
  end

  def cached_response?
    !!json_cached_response
  end

  def json_cached_response
    @json_cached_response ||= redis.get(request.path)
  end

  def cached_response_hash
    JSON.parse(json_cached_response)
  end

  def redis
    RedisCache.redis
  end
end
