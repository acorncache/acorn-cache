require 'acorn_cache/request'
require 'minitest/autorun'
require 'time'

class RequestTest < Minitest::Test
  def test_no_cache_delegation
    env = {}
    cache_control_header = mock("cache control header")
    cache_control_header.expects(:no_cache?).returns(true)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    cached_response = Rack::AcornCache::Request.new(env)
    assert cached_response.no_cache?
  end

  def test_max_age_delegation
    env = {}
    cache_control_header = mock("cache control header")
    cache_control_header.expects(:max_age).returns(30)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    request = Rack::AcornCache::Request.new(env)
    assert_equal 30, request.max_age
  end

  def test_max_fresh_delegation
    env = {}
    cache_control_header = mock("cache control header")
    cache_control_header.expects(:max_fresh).returns(30)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    request = Rack::AcornCache::Request.new(env)
    assert_equal 30, request.max_fresh
  end

  def test_max_stale_delegation
    cache_control_header = mock("cache control header")
    cache_control_header.expects(:max_stale).returns(true)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    env = {}
    request = Rack::AcornCache::Request.new(env)
    assert request.max_stale
  end

  def test_update_conditional_headers
    cached_response = mock('cached_response')
    cached_response.stubs(:etag_header).returns("1317121")
    cached_response.stubs(:last_modified_header).returns("a long time ago")

    env = {}
    request = Rack::AcornCache::Request.new(env)
    request.update_conditional_headers!(cached_response)
    assert_equal "1317121", request.env["HTTP_IF_NONE_MATCH"]
    assert_equal "a long time ago", request.env["HTTP_IF_MODIFIED_SINCE"]
  end

  def test_update_conditional_headers_when_cached_response_has_no_relevant_headers
    cached_response = mock('cached_response')
    cached_response.stubs(:etag_header).returns(nil)
    cached_response.stubs(:last_modified_header).returns(nil)

    env = {}
    request = Rack::AcornCache::Request.new(env)
    request.update_conditional_headers!(cached_response)
    refute request.env["HTTP_IF_NONE_MATCH"]
    refute request.env["HTTP_IF_MODIFIED_SINCE"]
  end

  def test_max_age_more_restrictive_when_no_cached_response_stale_time_specified
    cached_response = stub(stale_time_specified?: false)
    request = Rack::AcornCache::Request.new({})

    refute request.max_age_more_restrictive?(cached_response)
  end

  def test_max_age_more_restrictive_when_request_has_no_max_age
    cached_response = stub(stale_time_specified?: true)
    request = Rack::AcornCache::Request.new({})

    refute request.max_age_more_restrictive?(cached_response)
  end

  def test_max_age_more_restrictive_when_max_age_greater_than_cached_response_time_to_live
    cached_response = stub(stale_time_specified?: true, time_to_live: 30)
    env = { "HTTP_CACHE_CONTROL" => "max-age=40" }
    request = Rack::AcornCache::Request.new(env)

    refute request.max_age_more_restrictive?(cached_response)
  end

  def test_max_age_more_restrictive_when_max_age_less_than_cached_response_time_to_live
    cached_response = stub(stale_time_specified?: true, time_to_live: 30)
    env = { "HTTP_CACHE_CONTROL" => "max-age=20" }
    request = Rack::AcornCache::Request.new(env)

    assert request.max_age_more_restrictive?(cached_response)
  end

  def test_page_rule_when_none_specified
    request = Rack::AcornCache::Request.new({})

    refute request.page_rule?
    refute request.page_rule
  end

  def test_page_rule_when_specified
    Rack::AcornCache.configure do |config|
      config.page_rules = { "foo.com" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("foo.com")

    assert request.page_rule?
    assert_includes(request.page_rule, :acorn_cache_ttl)
    assert_equal 30, request.page_rule[:acorn_cache_ttl]
  end

  def test_cacheable_when_cache_everything_true_and_no_page_rule_set_for_url
    Rack::AcornCache.configure do |config|
      config.cache_everything = true
      config.page_rules = { "foo.com" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("bar.com")
    request.stubs(:get?).returns(true)

    assert request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_and_page_rule_set_for_url_with_normal_string
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { "foo.com" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("foo.com")
    request.stubs(:get?).returns(true)

    assert request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_and_page_rule_set_for_url_with_wildcard_string
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { "f*.com" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("foo.com")
    request.stubs(:get?).returns(true)

    assert request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_and_no_page_rule_set_for_url_with_wildcard_string
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { "b*.com" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("foo.com")
    request.stubs(:get?).returns(true)

    refute request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_page_rule_set_for_url_with_wildcard_string_specifying_cache_all_http
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { "http://*.com" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("http://foo.com")
    request.stubs(:get?).returns(true)

    assert request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_page_rule_set_for_url_with_wildcard_string_specifying_cache_all_https
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { "https://*.com" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("http://foo.com")
    request.stubs(:get?).returns(true)

    refute request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_page_rule_set_for_url_with_wildcard_string_specifying_cache_all_js
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { "*.js" => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("foo.js")
    request.stubs(:get?).returns(true)

    assert request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_page_rule_set_for_url_with_regex
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { /fo{2}\.com/ => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("foo.com")
    request.stubs(:get?).returns(true)

    assert request.cacheable?
  end

  def test_cacheable_when_cache_everything_false_no_page_rule_set_for_url_with_regex
    Rack::AcornCache.configure do |config|
      config.cache_everything = false
      config.page_rules = { /^fo{2}\.com$/ => { acorn_cache_ttl: 30 } }
    end

    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("bar.foo.com/baz")
    request.stubs(:get?).returns(true)

    refute request.cacheable?
  end

  def test_cache_key_when_no_page_rule_set
    request = Rack::AcornCache::Request.new({})
    request.stubs(:url).returns("http://foo.com/bar?baz=true")

    assert_equal "http://foo.com/bar?baz=true", request.cache_key
  end

  def test_cache_key_when_defualt_ignore_query_params_set
    Rack::AcornCache.configure do |config|
      config.cache_everything = true
      config.default_ignore_query_params = true
    end

    env = { "rack.url_scheme" => "http",
           "HTTP_HOST" => "foo.com",
           "PATH_INFO" => "/bar",
           "SERVER_PORT" => 80,
           "QUERY_STRING" => "baz=true"}

    request = Rack::AcornCache::Request.new(env)

    assert_equal "http://foo.com/bar?baz=true", request.url
    assert_equal "http://foo.com/bar", request.cache_key
  end

  def test_if_modified_since
    date = Time.new(2016).httpdate
    env = { "HTTP_IF_MODIFIED_SINCE" => date }
    request = Rack::AcornCache::Request.new(env)

    assert_equal date, request.if_modified_since
  end

  def test_if_none_match
    env = { "HTTP_IF_NONE_MATCH" => "12345" }
    request = Rack::AcornCache::Request.new(env)

    assert_equal "12345", request.if_none_match
  end


  def test_conditional
    env = { "HTTP_IF_NONE_MATCH" => "12345" }
    request = Rack::AcornCache::Request.new(env)

    assert request.conditional?
  end

  def test_not_conditional
    request = Rack::AcornCache::Request.new({})

    refute request.conditional?
  end

  def teardown
    Rack::AcornCache.configuration = nil
  end
end
