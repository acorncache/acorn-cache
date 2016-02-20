require 'acorn_cache/config'
require 'acorn_cache/redis_cache'
require 'acorn_cache/rack_response'
require 'acorn_cache/cached_response'
require 'acorn_cache/request'
require 'acorn_cache/cache_writer'
require 'acorn_cache/cache_controller'

class Rack::AcornCache
  def initialize(app)
    @app = app
    @config = Config.new
  end

  def call(env)
    request = Request.new(env)
    return @app.call(env) unless request.get?
    CacheController.new(request, @config, @app).response.to_a
  end
end
