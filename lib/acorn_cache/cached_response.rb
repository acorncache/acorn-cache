require 'forwardable'
require 'time'

class Rack::AcornCache
  class CachedResponse
    extend Forwardable
    def_delegators :@cache_control_header, :s_maxage, :max_age, :no_cache?, :must_revalidate?

    attr_reader :body, :status, :headers, :date
    DEFAULT_MAX_AGE = 3600

    def initialize(args={})
      @body = args["body"]
      @status = args["status"]
      @headers = args["headers"]
      @cache_control_header = CacheControlHeader.new(headers["Cache-Control"])
    end

    def must_be_revalidated?
      no_cache? || must_revalidate?
    end

    def update_date!
      headers["Date"] = Time.now.httpdate
    end

    def serialize
      { headers: headers, status: status, body: body }.to_json
    end

    def to_a
      [status, headers, [body]]
    end

    def etag_header
      headers["ETag"]
    end

    def last_modified_header
      headers["Last-Modified"]
    end

    def update_date_and_recache!(cache_key)
      cached_response.update_date!
      CacheWriter.new.async.write(cache_key, cached_response.serialize)
      self
    end

    def add_acorn_cache_header!
      unless headers["X-Acorn-Cache"]
        headers["X-Acorn-Cache"] = "HIT"
      end
      self
    end

    def matches?(server_response)
      if etag_header
        server_response.etag_header == etag_header
      elsif last_modified_header
        server_response.last_modified_header == last_modified_header
      else
        false
      end
    end

    def time_to_live
      s_maxage || max_age || (expiration_header_time - date)
    end

    alias_method :stale_time_specified?, :time_to_live

    def fresh?
      expiration_date > Time.now
    end

    def date
      @date ||= Time.httpdate(date_header)
    end

    def expiration_date
      if s_maxage
        date + s_maxage
      elsif max_age
        date + max_age
      elsif expiration_header
        expiration
      else
        date + DEFAULT_MAX_AGE
      end
    end

    def time_until_expiration
      Time.now - expiration
    end

    def fresh_for_request?(request)
      FreshnessRules.cached_response_fresh_for_request?(self, request)
    end

    private

    def expiration_header_time
      Time.httpdate(expiration_header)
    end

    def expiration_header
      @expiration_header ||= headers["Expiration"]
    end

    def expiration
      @expiration ||= Time.httpdate(expiration_header)
    end

    def date_header
      headers["Date"]
    end
  end

  class NullCachedResponse
    def must_be_revalidated?
      false
    end

    def matches?(server_response)
      false
    end

    def update!; end

    def fresh_for_request?(request)
      false
    end
  end
end
