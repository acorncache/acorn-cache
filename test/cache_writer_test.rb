require 'minitest/autorun'
require 'acorn_cache/cache_writer'
require 'mocha/mini_test'

class CacheWriterTest < Minitest::Test
  def test_redis_writes_to_cache_with_appropriate_values
    redis_connection = mock("redis")
    redis_connection.expects(:set).with("path", "response").returns("OK")
    Rack::AcornCache::RedisCache.expects(:redis).returns(redis_connection)

    assert_equal Rack::AcornCache::CacheWriter.write("path", "response"), "OK"
  end
end
