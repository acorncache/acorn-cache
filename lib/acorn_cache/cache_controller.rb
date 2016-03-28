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
        elsif !cached_response.fresh_for_request?(request)
          server_response = get_response_from_server
        elsif request.conditional?
          if cached_response.not_modified_for?(request)
            return not_modified(cached_response)
          end
        end
      end

      CacheMaintenance
        .new(request.cache_key, server_response, cached_response)
        .update_cache
        .response
    end

    private

    attr_reader :request, :app

    def get_response_from_server
      begin
        status, headers, body = @app.call(request.env)
      rescue => e
        raise AppException.new(e)
      end

      server_response = ServerResponse.new(status, headers, body)

      if request.page_rule?
        server_response.update_with_page_rules!(request.page_rule)
      else
        server_response
      end
    end

    def check_for_cached_response
      CacheReader.read(request.cache_key) || NullCachedResponse.new
    end

    def not_modified(cached_response)
      status = 304

      headers = cached_response.headers
      headers.delete("Content-Type")
      headers.delete("Content-Length")

      body = []
      [status, headers, body]
    end
  end
end
