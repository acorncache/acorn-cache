require 'minitest/autorun'
require 'acorn_cache/config'

class ConfigurationTest < Minitest::Test
  def test_setting_configuration
    Rack::AcornCache.configure do |config|
      config.default_acorn_cache_ttl = 3600
    end

    assert_equal 3600, Rack::AcornCache.configuration.default_acorn_cache_ttl
  end

  def test_set_page_rules_without_defaults
    config = Rack::AcornCache::Configuration.new
    user_page_rules = {"http://foo.com" => { acorn_cache_ttl: 30 } }

    config.page_rules = user_page_rules

    assert_equal 30, config.page_rules["http://foo.com"][:acorn_cache_ttl]
  end

  def test_set_page_rules_with_defaults
    config = Rack::AcornCache::Configuration.new
    config.default_acorn_cache_ttl = 100
    user_page_rules = {"http://foo.com" => { browser_cache_ttl: 30 } }

    config.page_rules = user_page_rules

    assert config.page_rules["http://foo.com"]
    assert_equal 30, config.page_rules["http://foo.com"][:browser_cache_ttl]
    assert_equal 100, config.page_rules["http://foo.com"][:acorn_cache_ttl]
  end

  def test_set_page_rules_override_default
    config = Rack::AcornCache::Configuration.new
    config.default_acorn_cache_ttl = 100
    user_page_rules = {
      "http://foo.com" => { acorn_cache_ttl: 86400 }
    }

    config.page_rules = user_page_rules

    assert_equal 86400, config.page_rules["http://foo.com"][:acorn_cache_ttl]
  end

  def test_set_page_rules_with_respect_existing_headers_overrides_defaults
    config = Rack::AcornCache::Configuration.new
    config.default_acorn_cache_ttl = 100
    user_page_rules = {
      "http://foo.com" => { respect_existing_headers: true }
    }

    config.page_rules = user_page_rules
    refute config.page_rules["http://foo.com"][:acorn_cache_ttl]
  end

  def teardown
    Rack::AcornCache.configuration = nil
  end
end
