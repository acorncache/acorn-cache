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
end
