require 'acorn_cache/cache_control_header'
require 'acorn_cache/cache_writer'

class Rack::AcornCache
  class ServerResponse < Rack::Response
    extend Forwardable
    def_delegators :@cache_control_header, :private?, :no_store?

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
      [:private?, :no_store?].none? { |directive| send(directive) } &&
        status == 200
    end

    def status_304?
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

    def cache!(request_path)
      update_date!
      CacheWriter.write(request_path, serialize)
      self
    end

    private

    attr_reader :status, :headers, :body
  end
end
