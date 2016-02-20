require 'acorn_cache/config'
require 'acorn_cache/redis_cache'
require 'acorn_cache/rack_response'
require 'acorn_cache/cached_response'
require 'acorn_cache/request'
require 'acorn_cache/cache_reader'
require 'acorn_cache/cache_writer'
require 'acorn_cache/cache_controller'

class Rack::AcornCache
  def initialize(app)
    @app = app
    @config = Config.new
  end

  def call(env)
    request = Request.new(env)
    cached_response = CacheReader.read(request.path)

    hit_server = Proc.new { @app.call(env) }
    response =
      CacheController.new(request, cached_response, @config, &hit_server).run

    if response.cacheable?
      CacheWriter.write(request.path, response.serialize)
    elsif response.date_updateable?
      cached_response.update_date!
      CacheWriter.write(request.path, cached_response.update_date.serialize)
    end

    response.to_a
  end
end
