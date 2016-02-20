require 'acorn_cache/cache_control_header'
require 'acorn_cache/cache_reader'
require 'acorn_cache/cache_writer'

class Rack::AcornCache
  class CacheController
    def initialize(request, config, app)
      @request = request
      @config = config
      @app = app
    end

    def response
      if request_requires_server_response? ||
          !cached_response_directly_returnable_for_request?
        get_repsonse_from_server
        update_cache_if_needed
        rack_response
      elsif cached_repsonse.must_be_revalidated?
        add_cached_response_etag_to_request
        add_cached_response_last_modified_to_request
        get_response_from_server
        if rack_response.not_changed?
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
      else
        cached_response.add_x_from_acorn_cache_header!
        cached_response
      end
    end

    private

    attr_reader :request, :cached_response, :config, :hit_server,
                :rack_response, :app

    def get_response_from_server
      status, headers, body = @app.call(request.env)
      @rack_response = RackResponse.new(status, headers, body)
    end

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

    def rack_response
    end

    def update_cache_if_needed
      if rack_response.cacheable?
        rack_response.update_date!
        CacheWriter.write(request.path, rack_response.serialize)
      elsif rack_response.not_changed? && cached_response
        cached_response.update_date!
        CacheWriter.write(request.path, cached_response.serialize)
      end
    end

    def cached_response
      @cached_response ||= CacheReader.read(request.path)
    end

    def request_requires_server_response?
      !@config.paths_whitelist.include?(request.path) || request.no_cache
    end

    def cached_response_must_be_revalidated?
      cached_response &&
        (cached_repsonse.no_cache || cached_response.must_revalidate)
    end

    def cached_response_directly_returnable_for_request?
      return false if !cached_response || cached_response_must_be_revalidated?
      if cached_response.fresh?
        return true unless request.max_age || request.max_fresh
        if request.max_age
          cached_response.date + request.max_age >= Time.now
        elsif request.max_fresh
          cached_response.expiration_date - request.max_fresh >= Time.now
        end
      else
        return false unless request.max_stale
        return true unless request.max_stale.is_a?(Integer)
        (cached_response.expiration_date + request.max_stale) >= Time.now
      end
    end
  end
end
