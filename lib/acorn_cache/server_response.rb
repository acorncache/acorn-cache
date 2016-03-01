require 'json'
require 'time'

class Rack::AcornCache
  class ServerResponse < Rack::Response
    CACHEABLE_STATUS_CODES = [200, 203, 300, 301, 302, 404, 410]
    attr_reader :status, :headers, :body, :cache_control_header

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
        CACHEABLE_STATUS_CODES.include?(status)
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

    def cache!(cache_key)
      update_date!
      CacheWriter.write(cache_key, serialize)
      self
    end

    def update_with_page_rules!(page_rule)
      if page_rule[:must_revalidate]
        self.no_cache = true
        self.must_revalidate = true
        self.max_age = nil
        self.s_maxage = nil
        self.no_store = nil
      end

      if page_rule[:acorn_cache_ttl] || page_rule[:browser_cache_ttl]
        self.no_cache = nil
        self.no_store = nil
        self.must_revalidate = nil
      end

      if page_rule[:acorn_cache_ttl]
        self.max_age = nil
        self.s_maxage = page_rule[:acorn_cache_ttl]
        self.private = nil
      end

      if page_rule[:browser_cache_ttl]
        self.max_age = page_rule[:browser_cache_ttl]
      end

      headers["Cache-Control"] = cache_control_header.to_s
      self
    end

    def method_missing(method, *args)
      cache_control_header.send(method, *args)
    end
  end
end
