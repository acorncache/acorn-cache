require 'acorn_cache/config'
require 'acorn_cache/redis_cache'
require 'acorn_cache/rack_response'
require 'acorn_cache/cached_response'
require 'acorn_cache/request'
require 'acorn_cache/cache_reader'
require 'acorn_cache/cache_writer'

class Rack::AcornCache
  def initialize(app)
    @app = app
    @config = Config.new
  end

  def call(env)
    @request = Request.new(env)

    unless request.accepts_cached_response?(paths_whitelist)
      return @app.call(env)
    end

    if cached_response? && cached_response.fresh?(request)
      cached_response.add_x_from_acorn_cache_header
      return cached_response.to_a
    end

    status, headers, body = @app.call(env)
    @rack_response = RackResponse.new(status, headers, body)
    update_cache
    rack_response.to_a
  end

  private

  attr_reader :request, :rack_response, :config, :cached_response,
              :cache_reader, :cache_writer

  def update_cache
    CacheWriter.new(rack_response, cached_response, request.path).update_cache
  end

  def paths_whitelist
    @paths_whitelist ||= config.paths_whitelist
  end

  def cached_response?
    return false unless CacheReader.new(request.path).hit?
    @cached_response = CachedResponse.new(cache_reader.cached_response_hash)
  end
end
