require 'acorn_cache/cache_reader'
require 'acorn_cache/cache_maintenance'
require 'acorn_cache/server_response'
require 'acorn_cache/cached_response'

class Rack::AcornCache
  class CacheController
    def initialize(request, app)
      @request = request
      @app = app
    end

    def response
      if request.no_cache?
        server_response = get_response_from_server
      else
        cached_response = check_for_cached_response

        if cached_response.must_be_revalidated?
          request.update_conditional_headers!(cached_response)
          server_response = get_response_from_server
        elsif !cached_response.fresh_for?(request)
          server_response = get_response_from_server
        end
      end

      perform_cache_maintenance(request.path, server_response, cached_response)
    end

    private

    attr_reader :request, :app

    def perform_cache_maintenance(path, server_response, cached_response)
      CacheMaintenance.update_cache_with(path, server_response, cached_response)
    end

    def get_response_from_server
      status, headers, body = @app.call(request.env)
      ServerResponse.new(status, headers, body)
    end

    def check_for_cached_response
      CacheReader.read(request.path) || NullCachedResponse.new
    end
  end
end
