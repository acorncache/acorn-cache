require 'minitest/autorun'
require 'acorn_cache'

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
    request = stub(no_cache?: true, get?: true, env: { }, no_page_rule_for_url?: true)
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
    request = stub( get?: true, no_page_rule_for_url?: true )
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
end
