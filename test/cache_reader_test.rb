require 'minitest/autorun'
require 'acorn_cache/cache_reader'
require 'mocha/mini_test'

class CacheReaderTest < MiniTest::Test
  def test_returns_false_if_response_from_redis_is_nil
    redis = mock('redis')
    redis.expects(:get).with("foo").returns(nil)
    Rack::AcornCache::RedisCache.expects(:redis).returns(redis)

    refute Rack::AcornCache::CacheReader.read("foo")
  end

  def test_returns_cached_response_object_if_response_from_redis
    redis = mock('redis')
    redis_response = mock('redis_reponse')
    response_hash = mock('response_hash')

    redis.expects(:get).with("foo").returns(redis_response)
    Rack::AcornCache::RedisCache.expects(:redis).returns(redis)
    JSON.expects(:parse).with(redis_response).returns(response_hash)
    Rack::AcornCache::CachedResponse
      .expects(:new)
      .with(response_hash)
      .returns('cache-response-object')

    result = Rack::AcornCache::CacheReader.read("foo")
    assert_equal 'cache-response-object', result
  end
end
