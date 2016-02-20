require 'acorn_cache/cache_control_header'

class Rack::AcornCache
  class RackResponse < Rack::Response
    extend Forwardable
    def_delegators :@cache_control_header, :private, :no_store
    attr_reader :status, :headers, :body

    def initialize(status, headers, body)
      @status = status
      @headers = headers
      @body = body
      @cache_control_header = CacheControlHeader.new(headers["Cache-Control"])
    end

    def update_date!
      @headers["Date"] = Time.now.httpdate unless @headers["Date"]
    end

    def cacheable?
      [:private, :no_store].none? { |directive| send(directive) } &&
        status == 200
    end

    def not_changed?
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
