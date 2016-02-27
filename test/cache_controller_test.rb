require 'acorn_cache/cache_controller'
require 'minitest/autorun'

class CacheControllerTest < MiniTest::Test
  def test_response_when_request_no_cache_returns_server_response
    request = stub(no_cache?: true, env: {}, path: "/", page_rule?: false)
    app = stub(call: [200, {}, "foo"])
    server_response = mock('server_response')
    cache_maintenance = mock('cache_maintenance')

    Rack::AcornCache::ServerResponse.expects(:new).with(200, {}, "foo").returns(server_response)
    Rack::AcornCache::CacheMaintenance.expects(:new).with("/", server_response, nil).returns(cache_maintenance)
    cache_maintenance.expects(:update_cache).returns(cache_maintenance)
    cache_maintenance.expects(:response).returns(server_response)

    cache_controller = Rack::AcornCache::CacheController.new(request, app)
    assert server_response, cache_controller.response
  end

  def test_response_when_request_no_cache_false_and_theres_no_cached_version
    request = stub(no_cache?: false, path: "/", env: {}, page_rule?: false)
    server_response = mock('server_response')
    null_cached_response = stub(must_be_revalidated?: false, fresh_for_request?: false)
    app = stub(call: [200, {}, "foo"])
    cache_maintenance = mock('cache_maintenance')

    Rack::AcornCache::CacheReader.expects(:read).returns(nil)
    Rack::AcornCache::NullCachedResponse.expects(:new).returns(null_cached_response)
    Rack::AcornCache::ServerResponse.expects(:new).with(200, {}, "foo").returns(server_response)
    Rack::AcornCache::CacheMaintenance.expects(:new).with("/", server_response, null_cached_response).returns(cache_maintenance)
    cache_maintenance.expects(:update_cache).returns(cache_maintenance)
    cache_maintenance.expects(:response).returns(server_response)

    cache_controller = Rack::AcornCache::CacheController.new(request, app)
    assert server_response, cache_controller.response
  end

  def test_response_when_request_no_cache_false_and_there_is_cached_version_and_must_be_revalidated
    request = stub(no_cache?: false, path: "/", env: {}, page_rule?: false)
    server_response = mock('server_response')
    cached_response = stub(must_be_revalidated?: true)
    app = stub(call: [200, {}, "foo"])
    cache_maintenance = mock('cache_maintenance')

    Rack::AcornCache::CacheReader.expects(:read).with("/").returns(cached_response)

    request.expects(:update_conditional_headers!).with(cached_response)
    Rack::AcornCache::ServerResponse.expects(:new).with(200, {}, "foo").returns(server_response)
    Rack::AcornCache::CacheMaintenance.expects(:new).with("/", server_response, cached_response).returns(cache_maintenance)
    cache_maintenance.expects(:update_cache).returns(cache_maintenance)
    cache_maintenance.expects(:response).returns(server_response)

    cache_controller = Rack::AcornCache::CacheController.new(request, app)
    assert server_response, cache_controller.response
  end

  def test_response_when_request_no_cache_false_and_there_is_cached_version_and_not_must_be_revalidated_and_isnt_fresh_for_request
    request = stub(no_cache?: false, path: "/", env: {}, page_rule?: false)
    server_response = mock('server_response')
    cached_response = stub(must_be_revalidated?: false, fresh_for_request?: false)
    app = stub(call: [200, {}, "foo"])
    cache_maintenance = mock('cache_maintenance')

    Rack::AcornCache::CacheReader.expects(:read).with("/").returns(cached_response)
    Rack::AcornCache::ServerResponse.expects(:new).with(200, {}, "foo").returns(server_response)
    Rack::AcornCache::CacheMaintenance.expects(:new).with("/", server_response, cached_response).returns(cache_maintenance)
    cache_maintenance.expects(:update_cache).returns(cache_maintenance)
    cache_maintenance.expects(:response).returns(server_response)

    cache_controller = Rack::AcornCache::CacheController.new(request, app)
    assert server_response, cache_controller.response
  end

  def test_response_when_request_no_cache_false_and_there_is_cached_version_and_not_must_be_revalidated_and_is_fresh_for_request
    request = stub(no_cache?: false, path: "/", env: {})
    cached_response = stub(must_be_revalidated?: false, fresh_for_request?: true)
    app = stub(call: [200, {}, "foo"])
    cache_maintenance = mock('cache_maintenance')

    Rack::AcornCache::CacheReader.expects(:read).with("/").returns(cached_response)
    Rack::AcornCache::CacheMaintenance.expects(:new).with("/", nil, cached_response).returns(cache_maintenance)
    cache_maintenance.expects(:update_cache).returns(cache_maintenance)
    cache_maintenance.expects(:response).returns(cached_response)

    cache_controller = Rack::AcornCache::CacheController.new(request, app)
    assert cached_response, cache_controller.response
  end

  def test_response_when_request_no_cache_true_and_page_rules_set
    request = stub(no_cache?: true, env: {}, path: "/", page_rule?: true, page_rule: { acorn_cache_ttl: 30 })
    app = stub(call: [200, {}, "foo"])
    server_response = mock("server response")

    Rack::AcornCache::ServerResponse.stubs(:new).returns(server_response)
    Rack::AcornCache::CacheMaintenance.stubs(:new).returns(server_response)
    server_response.stubs(:update_cache).returns(server_response)
    server_response.stubs(:response)

    server_response.expects(:update_with_page_rules!).with(acorn_cache_ttl: 30)

    Rack::AcornCache::CacheController.new(request, app).response
  end
end
