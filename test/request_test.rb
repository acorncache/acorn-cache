require 'acorn_cache/request'
require 'minitest/autorun'

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

  def test_max_age_more_restrictive_when_max_age_greater_than_cached_response_time_until_stale
    cached_response = stub(stale_time_specified?: true, time_until_stale: 30)
    env = { "HTTP_CACHE_CONTROL" => "max-age=40" }
    request = Rack::AcornCache::Request.new(env)

    refute request.max_age_more_restrictive?(cached_response)
  end

  def test_max_age_more_restrictive_when_max_age_less_than_cached_response_time_until_stale
    cached_response = stub(stale_time_specified?: true, time_until_stale: 30)
    env = { "HTTP_CACHE_CONTROL" => "max-age=20" }
    request = Rack::AcornCache::Request.new(env)

    assert request.max_age_more_restrictive?(cached_response)
  end
end
