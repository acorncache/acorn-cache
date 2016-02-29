require 'minitest/autorun'
require 'acorn_cache/server_response'
require 'mocha/mini_test'

class ServerResponseTest < Minitest::Test

  attr_reader :status, :headers, :body

  def test_new
    @status = status
    @headers = headers
    @body = body

    Rack::AcornCache::CacheControlHeader.expects(:new).with("private")

    server_response = Rack::AcornCache::ServerResponse.new(200, { "Cache-Control" => "private" }, "test body")

    assert_equal 200, server_response.status
    assert_equal({ "Cache-Control" => "private" },  server_response.headers)
    assert_equal "test body", server_response.body
  end

  def test_private_delegation
    cache_control_header = mock("cache control header")
    cache_control_header.expects(:private?).returns(true)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    server_response = Rack::AcornCache::ServerResponse.new(200, { "Cache-Control" => "private" }, "test body")

    assert server_response.private?
  end

  def test_no_store_delegation
    cache_control_header = mock("cache control header")
    cache_control_header.expects(:no_store?).returns(true)
    Rack::AcornCache::CacheControlHeader.expects(:new).returns(cache_control_header)

    server_response = Rack::AcornCache::ServerResponse.new(200, { "Cache-Control" => "no-store" }, "test body")

    assert server_response.no_store?
  end

  def test_update_date_when_date_already_exists
    server_response = Rack::AcornCache::ServerResponse.new(200, { "Date" => "Mon, 01 Jan 2000 01:00:01 GMT" }, "test body")

    assert "Mon, 01 Jan 2000 01:00:01 GMT", server_response.update_date!
  end

  def test_update_when_no_date_exists
    server_response = Rack::AcornCache::ServerResponse.new(200, { "Cache-Control" => "no-store" }, "test body")

    current_time = mock("current time")
    current_time.expects(:httpdate).returns(Time.now.httpdate)

    server_response.update_date!
    assert_equal current_time.httpdate, server_response.headers["Date"]
  end

  def test_cacheable_returns_true
    server_response = Rack::AcornCache::ServerResponse.new(200, { }, "test body")

    assert server_response.cacheable?
  end

  def test_cacheable_returns_false_for_cache_control
    server_response = Rack::AcornCache::ServerResponse.new(200, { "Cache-Control" => "no-store" }, "test body")

    refute server_response.cacheable?
  end

  def test_cacheable_returns_false_for_status
    server_response = Rack::AcornCache::ServerResponse.new(304, { }, "test body")

    refute server_response.cacheable?
  end

  def test_status_304?
    server_response = Rack::AcornCache::ServerResponse.new(304, { "Cache-Control" => "no-store" }, "test body")

    assert server_response.status_304?
  end

  def test_serialize
    server_response = Rack::AcornCache::ServerResponse.new(304, { "Cache-Control" => "no-store" }, ["test body"])

    result = server_response.serialize

    assert_equal "{\"status\":304,\"headers\":{\"Cache-Control\":\"no-store\"},\"body\":\"test body\"}", result
  end

  def test_body_string
    server_response = Rack::AcornCache::ServerResponse.new(304, { "Cache-Control" => "no-store" }, ["test body part one", "test body part deux"])

    result = server_response.body_string

    assert_equal "test body part onetest body part deux", result
  end

  def test_to_a
    server_response = Rack::AcornCache::ServerResponse.new(304, { "Cache-Control" => "no-store" }, "test body")

    result = server_response.to_a

    assert_equal [304, {"Cache-Control"=>"no-store"}, "test body"], result
  end

  def test_cache_updates_date
    server_response = Rack::AcornCache::ServerResponse.new(304, {"Cache-Control"=>"no-store"}, "test body")
    server_response.expects(:serialize).returns("Hey look I'm serialized!")
    Rack::AcornCache::CacheWriter.expects(:write).with("key", "Hey look I'm serialized!")

    server_response.cache!("key")
  end

  def test_update_with_page_rules_when_directives_are_removed
    page_rule = { acorn_cache_ttl: 30 }

    headers = { "Cache-Control" => "private, no-cache, no-store, must_revalidate" }
    response = Rack::AcornCache::ServerResponse.new(200, headers, "test body")

    assert response.private?
    assert response.no_cache?
    assert response.no_store?
    assert response.must_revalidate?

    response.update_with_page_rules!(page_rule)

    refute response.private?
    refute response.no_cache?
    refute response.no_store?
    refute response.must_revalidate?

    assert_equal 30, response.s_maxage
  end
end
