require 'acorn_cache/storage'

class Rack::AcornCache
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_writer :storage
    attr_reader :page_rules
    attr_accessor :default_acorn_cache_ttl, :default_browser_cache_ttl,
      :cache_everything, :default_ignore_query_params, :default_must_revalidate

    def initialize
      @cache_everything = false
      @storage = :redis
    end

    def page_rules=(user_page_rules)
      @page_rules = user_page_rules.each_with_object({}) do |(k, v), result|
        result[k] = build_page_rule(v)
      end
    end

    def page_rule_for_url(url)
      if cache_everything
        return default_page_rule unless page_rules
        no_page_rule_found = proc { return default_page_rule }
      else
        return nil unless page_rules
        no_page_rule_found = proc { return nil }
      end

      page_rules.find(no_page_rule_found) do |k, _|
        page_rule_key_matches_url?(k, url)
      end.last
    end

    def storage
      if @storage == :redis
        Rack::AcornCache::Storage.redis
      elsif @storage == :memcached
        Rack::AcornCache::Storage.memcached
      end
    end

    private

    def default_page_rule
      { acorn_cache_ttl: default_acorn_cache_ttl,
        browser_cache_ttl: default_browser_cache_ttl,
        ignore_query_params: default_ignore_query_params,
        must_revalidate: default_must_revalidate }
    end

    def build_page_rule(options)
      options[:ignore_query_params] = default_ignore_query_params

      return options if options[:respect_existing_headers]
      { acorn_cache_ttl: default_acorn_cache_ttl,
        browser_cache_ttl: default_browser_cache_ttl }.merge(options)
    end

    def page_rule_key_matches_url?(page_rule_key, url)
      return url =~ page_rule_key if page_rule_key.is_a?(Regexp)
      string = page_rule_key.gsub("*", ".*")
      url =~ /^#{string}$/
    end
  end

  #Example config setup:
  # Rack::AcornCache.configure do |config|
  #   config.cache_everything = true
  #   config.default_acorn_cache_ttl = 3600
  #   config.page_rules = {
  #     "http://example.com/*.js" => { browser_cache_ttl: 30,
  #                                    regex: true },
  #     "another_url" => { acorn_cache_ttl: 100 },
  #     "foo.com" => { respect_existing_headers: true }
  #   }
  # end
end
