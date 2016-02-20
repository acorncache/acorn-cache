class Rack::AcornCache
  class RackResponse < Rack::Response
    attr_reader :status, :headers, :body

    def initialize(status, headers, body, no_cache: false)
      @status = status
      @headers = headers
      @body = body
      @no_cache = no_cache
    end

    def cache_control_header
      headers["Cache-Control"]
    end

    def update_date!
      @headers["Date"] = Time.now.httpdate
    end

    def cacheable?
      !@no_cache && status == 200
    end

    def date_updateable?
      status == 304
    end

    def serialize
      { status: status, headers: headers, body: body_string }.to_json
    end

    def body_string
      result = ""
      body.each { |part| result << part }
      result
    end

    def to_a
      [status, headers, body]
    end
  end
end
