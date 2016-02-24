require 'minitest/autorun'
require 'acorn_cache/redis_cache'
require 'mocha/mini_test'

class RedisCacheTest < Minitest::Test
  ENV["ACORNCACHE_HOST"] = "Some Host"
  ENV["ACORNCACHE_PORT"] = "1234"
  ENV["ACORNCACHE_PASSWORD"] = "password"

  def test_setup_new_redis_connection
    Redis.expects(:new).with({ host: "Some Host", port: 1234, password: "password" }).returns("redis connection")

    assert_equal Rack::AcornCache::RedisCache.redis, "redis connection"
  end
end
