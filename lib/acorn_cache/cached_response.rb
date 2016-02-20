class Rack::AcornCache
  class CachedResponse
    extend Forwardable
    def_delegators :@cache_control_header, :s_maxage, :max_age, :no_cache,
                   :must_revalidate

    attr_reader :body, :status, :headers
    DEFAULT_MAX_AGE = 3600

    def initialize(args={})
      @body = args["body"]
      @status = args["status"]
      @headers = args["headers"]
      @cache_control_header = CacheControlHeader.new(headers["Cache-Control"])
    end

    def fresh?
      expiration_date > Time.now
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

    def add_x_from_acorn_cache_header!
      unless headers["X-From-Acorn-Cache"]
        headers["X-From-Acorn-Cache"] = "HIT"
      end
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

    def date_header
      @date_header_time ||= headers["Date"]
    end

    def date
      Time.httpdate(date_header)
    end

    def expiration_header
      @expiration_header ||= headers["Expiration"]
    end

    def etag_header
      headers["ETag"]
    end

    def last_modified_header
      headers["Last-Modified"]
    end

    def expiration
      Time.httptime(expiration_header)
    end

    def cacheable?
      false
    end

    def date_updateable?
      false
    end
  end
end
