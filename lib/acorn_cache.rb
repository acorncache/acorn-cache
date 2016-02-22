require 'acorn_cache/request'
require 'acorn_cache/cache_controller'

class Rack::AcornCache
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Request.new(env)
    return @app.call(env) unless request.get?
    CacheController.new(request, @app).response.to_a
  end
end
