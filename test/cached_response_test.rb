require 'minitest/autorun'
require 'acorn_cache/cached_response'
require 'mocha/mini_test'

class CachedResponseTest < Minitest::Test
  def test_new
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "private" },
             "body" => "some body" }

    Rack::AcornCache::CacheControlHeader.expects(:new).with("private")

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    assert_equal 200, cached_response.status
    assert_equal({ "Cache-Control" => "private" },  cached_response.headers)
    assert_equal "some body", cached_response.body
  end

  def test_no_cache_delegation
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "no-cache" },
             "body" => "some body" }

    cache_control_header = mock("cache control header")
    cache_control_header.expects(:no_cache?).returns(true)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    assert cached_response.no_cache?
  end

  def test_must_revalidate_delegation
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "must-revalidate" },
             "body" => "some body" }

    cache_control_header = mock("cache control header")
    cache_control_header.expects(:must_revalidate?).returns(true)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    assert cached_response.must_revalidate?
  end

  def test_max_age_delegation
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "max-age=30" },
             "body" => "some body" }

    cache_control_header = mock("cache control header")
    cache_control_header.expects(:max_age).returns(30)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    assert_equal 30, cached_response.max_age
  end

  def test_s_max_age_delegation
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "s-maxage=30" },
             "body" => "some body" }

    cache_control_header = mock("cache control header")
    cache_control_header.expects(:s_maxage).returns(30)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    assert_equal 30, cached_response.s_maxage
  end

  def test_must_be_revalidated
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "no-cache" },
             "body" => "some body" }

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    cached_response.expects(:no_cache?).returns(true)

    assert cached_response.must_be_revalidated?
  end

  def test_update_date!
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "no-cache" },
             "body" => "some body" }

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    current_time = mock('current_time')
    current_time.expects(:httpdate).returns(Time.now.httpdate)

    cached_response.update_date!
    assert_equal current_time.httpdate, cached_response.headers["Date"]
  end

  def test_serialize
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "no-cache" },
             "body" => "some body" }

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    result = cached_response.serialize

    assert_equal "{\"headers\":{\"Cache-Control\":\"no-cache\"},\"status\":200,\"body\":\"some body\"}", result
  end

  def test_to_a
    args = { "status" => 200,
             "headers" =>  { "Cache-Control" => "no-cache" },
             "body" => "some body" }

    cached_response = Rack::AcornCache::CachedResponse.new(args)
    result = cached_response.to_a

    assert_equal [200, {"Cache-Control"=>"no-cache"}, ["some body"]], result
  end
end
