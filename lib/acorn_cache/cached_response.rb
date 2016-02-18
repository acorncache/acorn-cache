require 'acorn_cache/cache_control_restrictable'
require 'time'

class Rack::AcornCache
  class CachedResponse
    include CacheControlRestrictable

    DEFAULT_MAX_AGE = 3600

    attr_reader :body, :status

    def initialize(args={})
      @body = args["body"]
      @status = args["status"]
      @headers = args["headers"]
    end

    def fresh?(request)
      Time.now <= expiration_date(request)
    end

    def cache_control_header
      headers["Cache-Control"]
    end

    def add_x_from_acorn_cache_header
      headers["X-From-Acorn-Cache"] = "true"
    end

    def update_date
      headers["Date"] = Time.now.httpdate
    end

    def to_json
      { headers: headers, status: status, body: body }.to_json
    end

    def to_a
      [status, headers, [body]]
    end

    private

    attr_reader :headers

    def expiration_date(request)
      if max_age_specified?
        date_header_time + more_restrictive_max_age(request)
      elsif expiration_header && request.max_age_specified?
        more_restrictive_of_expiration_and_request_max_age(request)
      elsif expiration_header
        expiration_header
      elsif request.max_age_specified?
        date_header_time + request.max_age
      else
        date_header_time + DEFAULT_MAX_AGE
      end
    end

    def more_restrictive_of_expiration_and_request_max_age(request)
      if (date_header_time + request.max_age) < expiration_header
        date_header_time + request.max_age
      else
        expiration_header
      end
    end

    def date_header_time
      @date_header_time ||= header_value_to_time("Date")
    end

    def expiration_header
      @expiration_header ||= headers["Expiration"]
    end

    def more_restrictive_max_age(request)
      if request.max_age_specified? && (max_age > request.max_age)
        request.max_age
      else
        max_age
      end
    end

    def header_value_to_time(header)
      Time.httpdate(headers[header])
    end
  end
end
