require 'acorn_cache/cache_control_restrictable'

class Rack::AcornCache
  class RackResponse < Rack::Response
    include CacheControlRestrictable

    attr_reader :status, :headers, :body

    def initialize(status, headers, body)
      @status = status
      @headers = headers
      @body = body
    end

    def cache_control_header
      headers["Cache-Control"]
    end

    def add_date_header
      @headers["Date"] = Time.now.httpdate
    end

    def eligible_for_caching?
      status == 200 && !caching_restrictions?
    end

    def eligible_for_updating?
      status == 304
    end

    def to_json
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

    private

    attr_reader :headers
  end
end
