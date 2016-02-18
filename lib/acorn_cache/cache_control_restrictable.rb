class Rack::AcornCache
  module CacheControlRestrictable
    CACHE_CONTROL_RESTRICTIONS = ["no-cache", "no-store", "private"]

    def max_age
      cache_control_header[/\d+/].to_i
    end

    def max_age_specified?
      cache_control_header && cache_control_header.include?("max-age")
    end

    def caching_restrictions?
      cache_control_header &&
        CACHE_CONTROL_RESTRICTIONS.any? do |restriction|
          cache_control_header.include?(restriction)
        end
    end
  end
end
