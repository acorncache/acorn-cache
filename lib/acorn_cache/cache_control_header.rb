class Rack::AcornCache
  class CacheControlHeader
    def initialize(header_string)
      @header_string = header_string
      @header_hash = to_h
    end

    def max_age
      header_hash["max-age"]
    end

    def s_maxage
      header_hash["s-maxage"]
    end

    def no_cache?
      header_hash["no-cache"]
    end

    def no_store?
      header_hash["no-store"]
    end

    def must_revalidate?
      header_hash["must-revalidate"]
    end

    def private?
      header_hash["private"]
    end

    def max_fresh
      header_hash["max-fresh"]
    end

    def max_stale
      header_hash["max-stale"]
    end

    alias_method :max_stale?, :max_stale

    def directives
      header_hash.keys
    end

    private

    attr_reader :header_hash

    def to_h
      return {} unless @header_string
      @header_string.split(",").each_with_object({}) do |directive, result|
        k, v = directive.split("=")
        v = v.to_i if v =~ /^[0-9]+$/
        v = true if v.nil?
        result[k] = v
      end
    end
  end
end
