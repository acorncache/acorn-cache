require 'minitest/autorun'
require 'acorn_cache/cache_reader'
require 'mocha/mini_test'

class CacheReaderTest < MiniTest::Test
  def test_returns_false_if_response_from_storage_is_nil
    Rack::AcornCache.configure {}
    storage = mock('storage')
    storage.expects(:get).with("foo").returns(nil)
    Rack::AcornCache.configuration.expects(:storage).returns(storage)

    refute Rack::AcornCache::CacheReader.read("foo")
  end

  def test_returns_cached_response_object_if_response_from_storage
    Rack::AcornCache.configure {}
    storage = mock('storage')
    storage_response = mock('storage_reponse')
    response_hash = mock('response_hash')

    storage.expects(:get).with("foo").returns(storage_response)
    Rack::AcornCache.configuration.expects(:storage).returns(storage)
    JSON.expects(:parse).with(storage_response).returns(response_hash)
    Rack::AcornCache::CachedResponse
      .expects(:new)
      .with(response_hash)
      .returns('cache-response-object')

    result = Rack::AcornCache::CacheReader.read("foo")
    assert_equal 'cache-response-object', result
  end
end
