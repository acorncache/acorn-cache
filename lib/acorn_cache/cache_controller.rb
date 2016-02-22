require 'acorn_cache/cache_reader'
require 'acorn_cache/cache_writer'
require 'acorn_cache/cache_maintenance'

class Rack::AcornCache
  class CacheController
    def initialize(request, app)
      @request = request
      @app = app
    end

    # def response_v2
    #   set_server_and_cached_responses!
    #   perform_cache_maintenance(request.path, @server_response, @cached_response)
    # end

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
      CacheMaintenance
        .update_cache_with(path, server_response, cached_response)
    end

    # def set_server_and_cached_responses!
    #   if request.no_cache?
    #     @server_response = get_response_from_server
    #     return
    #   end

    #   @cached_response = check_for_cached_response

    #   if @cached_response.must_be_revalidated?
    #     request.update_conditional_headers!(cached_response)
    #   end

    #   return if @cached_response.fresh_for?(request)

    #   @server_response = get_response_from_server
    # end

    def get_response_from_server
      status, headers, body = @app.call(request.env)
      ServerResponse.new(status, headers, body)
    end

    def check_for_cached_response
      CacheReader.read(request.path) || NullCachedResponse.new
    end
  end
end
