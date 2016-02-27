class Rack::AcornCache
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_reader :page_rules
    attr_accessor :default_acorn_cache_ttl, :default_browser_cache_ttl, 
                  :cache_everything

    def initialize
      @cache_everything = false
    end

    def page_rules=(user_page_rules)
      @page_rules = user_page_rules.each_with_object({}) do |(k, v), result|
        result[k] = build_page_rule(v)
      end
    end

    private

    def build_page_rule(options)
      return options if options[:respect_existing_headers]
      { acorn_cache_ttl: default_acorn_cache_ttl,
        browser_cache_ttl: default_browser_cache_ttl }.merge(options)
    end
  end

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
