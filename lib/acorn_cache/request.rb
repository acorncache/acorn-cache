require 'forwardable'

class Rack::AcornCache
  class Request < Rack::Request
    extend Forwardable
    def_delegators :@cache_control_header, :no_cache?, :max_age, :max_fresh,
                   :max_stale, :max_stale?

    def initialize(env)
      super
      @cache_control_header = CacheControlHeader.new(@env["HTTP_CACHE_CONTROL"])
    end

    def update_conditional_headers!(cached_response)
      if cached_response.etag_header
        self.if_none_match = cached_response.etag_header
      end

      if cached_response.last_modified_header
        self.if_modified_since = cached_response.last_modified_header
      end
    end

    def max_age_more_restrictive?(cached_response)
      cached_response.stale_time_specified? &&
        max_age && max_age < cached_response.time_to_live
    end

    def cacheable?
      get? && (config.cache_everything || page_rule?)
    end

    def page_rule
      config.page_rule_for_url(url) if config
    end

    def cache_key
      return base_url + path if page_rule? && page_rule[:ignore_query_params]
      url
    end

    alias_method :page_rule?, :page_rule

    private

    def config
      Rack::AcornCache.configuration
    end

    def if_none_match=(etag)
      env["HTTP_IF_NONE_MATCH"] = etag
    end

    def if_modified_since=(last_modified)
      env["HTTP_IF_MODIFIED_SINCE"] = last_modified
    end
  end
end
