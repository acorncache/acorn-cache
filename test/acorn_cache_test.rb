require 'acorn_cache'
require 'minitest/autorun'
require 'mocha/mini_test'

class AcornCacheTest < Minitest::Test
  def test_call_returns_app_if_request_is_not_a_get
    env = { "REQUEST_METHOD" => "POST" }
    app = mock("app")
    app.stubs(:call).returns([200, { }, ["foo"]])

    acorn_cache = Rack::AcornCache.new(app)

    assert_equal [200, { }, ["foo"]], acorn_cache.call(env)
  end

  def test_catch_and_re_raise_caught_app_exception
    env = { }
    request = stub(no_cache?: true, env: { }, cacheable?: true)
    Rack::AcornCache::Request.stubs(:new).returns(request)
    app = mock("app")
    app.stubs(:call).raises(StandardError)

    acorn_cache = Rack::AcornCache.new(app)

    assert_raises (StandardError) { acorn_cache.call(env) }
  end

  def test_catch_and_rescue_exception_from_cache_controller
    env = { }
    Rack::AcornCache::CacheController.stubs(:new).raises(StandardError)
    app = stub(call: [200, { }, ["foo"]])

    acorn_cache = Rack::AcornCache.new(app)

    assert_equal [200, { }, ["foo"]], acorn_cache.call(env)
  end

  def test_call_passes_request_and_app_to_cache_controller_if_ok
    request = stub(cacheable?: true)
    response = mock("response")
    cache_controller = mock("cache controller")
    env = { "REQUEST_METHOD" => "GET" }
    app = mock("app")
    app.stubs(:call).returns([200, { }, ["foo"]])
    Rack::AcornCache::CacheController.stubs(:new).with(request, app)
                                     .returns(cache_controller)
    Rack::AcornCache::Request.stubs(:new).with(env).returns(request)
    cache_controller.expects(:response).returns(response)
    response.expects(:to_a).returns([200, { }, ["foo"]])

    acorn_cache = Rack::AcornCache.new(app)

    assert_equal [200, { }, ["foo"]], acorn_cache.call(env)
  end

  def test_when_request_is_not_get
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com")
    env["REQUEST_METHOD"] = "POST"
    app.stubs(:call).with(env).returns([200, {}, ["foo"]])

    acorn_cache = Rack::AcornCache.new(app)
    result = acorn_cache.call(env)
    assert_equal ([200, {}, ["foo"]]), result
  end

  def test_cache_not_checked_unless_page_rule_set
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com")
    env["REQUEST_METHOD"] = "GET"
    app.stubs(:call).with(env).returns([200, {}, ["foo"]])

    acorn_cache = Rack::AcornCache.new(app)

    Rack::AcornCache.configure do |config|
      config.page_rules = {
        "http://bar.com" => { acorn_cache_ttl: 30 }
      }
    end

    result = acorn_cache.call(env)
    assert_equal ([200, {}, ["foo"]]), result
  end

  def test_cache_not_checked_unless_page_rule_set
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com")
    env["REQUEST_METHOD"] = "GET"
    app.stubs(:call).with(env).returns([200, {}, ["foo"]])

    acorn_cache = Rack::AcornCache.new(app)

    Rack::AcornCache.configure do |config|
      config.page_rules = {
        "http://bar.com" => { acorn_cache_ttl: 30 }
      }
    end

    result = acorn_cache.call(env)
    assert_equal ([200, {}, ["foo"]]), result
  end

  def test_cache_checked_when_cache_everything_set_and_no_cached_repsonse
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com")
    env["REQUEST_METHOD"] = "GET"
    response = ([200, {"Cache-Control" => "no-store" }, ["foo"]])
    app.stubs(:call).with(env).returns(response)
    redis = mock("redis")
    Redis.expects(:new).returns(redis)
    redis.stubs(:get).returns(nil)

    acorn_cache = Rack::AcornCache.new(app)

    Rack::AcornCache.configure do |config|
      config.cache_everything = true
    end

    result = acorn_cache.call(env)
    assert_equal response, result
  end

  def test_cached_response_fresh
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com")
    env["REQUEST_METHOD"] = "GET"

    redis = mock("redis")
    serialized_cached_response = "{\"status\":200,\"headers\":{\"Date\":\"Fri, 01 Jan 2016 05:00:00 GMT\",\"Cache-Control\":\"max-age=30\"},\"body\":\"foo\"}"
    redis.stubs(:get).returns(serialized_cached_response)
    Redis.expects(:new).returns(redis)
    Time.stubs(:now).returns(Time.new(2016))

    acorn_cache = Rack::AcornCache.new(app)

    Rack::AcornCache.configure do |config|
      config.page_rules = {
        "http://foo.com/" => { respect_existing_headers: true }
      }
    end

    response = [200, { "Date" => "Fri, 01 Jan 2016 05:00:00 GMT", "Cache-Control" => "max-age=30", "X-Acorn-Cache" => "HIT" }, ["foo"] ]

    result = acorn_cache.call(env)
    assert_equal response, result
  end

  def test_cached_response_expired_server_response_cacheable
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com/")
    env["REQUEST_METHOD"] = "GET"

    redis = mock("redis")
    serialized_cached_response = "{\"status\":200,\"headers\":{\"Date\":\"Fri, 01 Jan 2016 04:50:00 GMT\",\"Cache-Control\":\"max-age=0\"},\"body\":\"foo\"}"
    redis.stubs(:get).returns(serialized_cached_response)
    Redis.stubs(:new).returns(redis)
    Time.stubs(:now).returns(Time.new(2016))

    acorn_cache = Rack::AcornCache.new(app)

    Rack::AcornCache.configure do |config|
      config.page_rules = {
        "http://foo.com/" => { acorn_cache_ttl: 30,
                               browser_cache_ttl: 45 }
      }
    end

    response = [200, {}, ["foo"]]

    app.expects(:call).with(env).returns(response)
    serialized_response = { status: 200, headers: { "Cache-Control" => "max-age=45, s-maxage=30", "Date" => Time.new(2016).httpdate }, body: "foo" }.to_json
    redis.expects(:set).with('http://foo.com/', serialized_response)

    result = acorn_cache.call(env)
    assert_equal [200, {"Cache-Control"=>"max-age=45, s-maxage=30", "Date"=>"Fri, 01 Jan 2016 05:00:00 GMT"}, ["foo"]], result
  end

  def test_cached_response_expired_server_response_not_cacheable
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com/")
    env["REQUEST_METHOD"] = "GET"

    redis = mock("redis")
    serialized_cached_response = "{\"status\":200,\"headers\":{\"Date\":\"Fri, 01 Jan 2016 04:59:00:00 GMT\",\"Cache-Control\":\"max-age=0\"},\"body\":\"foo\"}"
    redis.stubs(:get).returns(serialized_cached_response)
    Redis.stubs(:new).returns(redis)
    Time.stubs(:now).returns(Time.new(2016))

    acorn_cache = Rack::AcornCache.new(app)

    Rack::AcornCache.configure do |config|
      config.page_rules = {
        "http://foo.com/" => { respect_existing_headers: true }
      }
    end

    response = [200, {"Cache-Control" => "no-store"}, ["foo"]]
    app.expects(:call).with(env).returns(response)
    redis.expects(:set).never

    result = acorn_cache.call(env)
    assert_equal response, result
  end

  def test_cached_response_needs_revalidated
    app = mock("app")
    env = Rack::MockRequest.env_for("http://foo.com")
    env["REQUEST_METHOD"] = "GET"

    redis = mock("redis")
    serialized_cached_response = "{\"status\":200,\"headers\":{\"Date\":\"Fri, 01 Jan 2016 05:00:00 GMT\",\"Cache-Control\":\"no-cache\", \"ETag\": \"12345\"},\"body\":\"foo\"}"
    redis.stubs(:get).returns(serialized_cached_response)
    Redis.stubs(:new).returns(redis)

    acorn_cache = Rack::AcornCache.new(app)

    Rack::AcornCache.configure do |config|
      config.page_rules = {
        "http://foo.com/" => { respect_existing_headers: true }
      }
    end

    response = [304, {"Cache-Control" => "no-store"}, ["foo"]]
    modified_env = env
    modified_env["HTTP_IF_NONE_MATCH"] = "12345"
    app.expects(:call).with(modified_env).returns(response)

    result = acorn_cache.call(env)
    assert_equal response, result
  end

  def teardown
    Rack::AcornCache.configuration = nil
    if Rack::AcornCache::Storage.instance_variable_get(:@redis)
      Rack::AcornCache::Storage.remove_instance_variable(:@redis)
    end
  end
end
