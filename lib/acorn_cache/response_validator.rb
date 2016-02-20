class Rack::AcornCache
  class RequestValidator
    def initialize(request, app, cached_response)
      @request = request
      @app = app
      @cached_response = cached_response
    end

    def request_revalidated?
      add_cached_response_etag_to_request
      add_cached_response_last_modified_to_request
      status, headers, body = @app.call(request.env)
      rack_response = RackResponse.new(status, headers, body)
      rack_response.not_changed?


        cached_response.update_date!
        CacheWriter.write(request.path, cached_response.serialize)
        cached_response
      elsif rack_response.cacheable?
        rack_response.update_date!
        CacheWriter.write(request.path, rack_response.serialize)
        rack_response
      else
        rack_response
      end
    end

    private

    attr_reader :request, :app, :cached_response

    def add_cached_response_etag_to_request
      if cached_response.etag_header
        request.if_none_match = cached_response.etag_header
      end
    end

    def add_cached_response_last_modified_to_request
      if cached_response.last_modified_header
        request.if_modified_since = cached_response.last_modified
      end
    end
  end
end
