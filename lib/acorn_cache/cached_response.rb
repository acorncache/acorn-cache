class Rack::AcornCache
  class CachedResponse
    attr_reader :body, :status, :headers

    def initialize(args={})
      @body = args["body"]
      @status = args["status"]
      @headers = args["headers"]
    end

    def cache_control_header
      headers["Cache-Control"]
    end

    def add_x_from_acorn_cache_header!
      headers["X-From-Acorn-Cache"] = "true"
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

    def expiration_header
      @expiration_header ||= headers["Expiration"]
    end

    def cacheable?
      false
    end

    def date_updateable?
      false
    end
  end
end
