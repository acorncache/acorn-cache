require 'acorn_cache/request'
require 'acorn_cache/cache_controller'
require 'acorn_cache/app_exception'
require 'rack'

class Rack::AcornCache
  def initialize(app)
    @app = app
  end

  def call(env)
    dup._call(env)
  end

  def _call(env)
    request = Request.new(env)
    return @app.call(env) unless request.get? && request.no_page_rule_for_url?

    begin
      CacheController.new(request, @app).response.to_a
    rescue AppException => e
      raise e.caught_exception
    rescue
      @app.call(env)
    end
  end
end
