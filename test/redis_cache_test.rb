require 'minitest/autorun'
require 'acorn_cache/redis_cache'
require 'mocha/mini_test'

class RedisCacheTest < Minitest::Test
  def test_setup_new_redis_connection
    ENV["ACORNCACHE_REDIS_HOST"] = "Some Host"
    ENV["ACORNCACHE_REDIS_PORT"] = "1234"
    ENV["ACORNCACHE_REDIS_PASSWORD"] = "password"

    Redis.expects(:new).with(host: "Some Host", port: 1234, password: "password" ).returns("redis connection")

    assert_equal Rack::AcornCache::Storage.redis, "redis connection"

    Rack::AcornCache::Storage.remove_instance_variable(:@redis)
  end

  def test_setup_new_redis_connection_without_password
    ENV["ACORNCACHE_REDIS_HOST"] = "Some Host"
    ENV["ACORNCACHE_REDIS_PORT"] = "1234"
    ENV["ACORNCACHE_REDIS_PASSWORD"] = nil

    Redis.expects(:new).with(host: "Some Host", port: 1234).returns("redis")

    assert_equal Rack::AcornCache::Storage.redis, "redis"

    Rack::AcornCache::Storage.remove_instance_variable(:@redis)
  end

  def test_setup_new_memecached_connection
    ENV["ACORNCACHE_MEMECACHED_URL"] = "host:port"
    ENV["ACORNCACHE_MEMECACHED_USERNAME"] = "Ol' Pete"
    ENV["ACORNCACHE_MEMECACHED_PASSWORD"] = "sneaky_pete"

    Dalli::Client.expects(:new).with("host:port", username: "Ol' Pete", password: "sneaky_pete").returns("memecached")

    assert_equal Rack::AcornCache::Storage.memecached, "memecached"

    Rack::AcornCache::Storage.remove_instance_variable(:@memecached)
  end

  def test_setup_new_memecached_connection_without_username_and_password
    ENV["ACORNCACHE_MEMECACHED_URL"] = "host:port"
    ENV["ACORNCACHE_MEMECACHED_USERNAME"] = nil
    ENV["ACORNCACHE_MEMECACHED_PASSWORD"] = nil

    Dalli::Client.expects(:new).with("host:port", {}).returns("memecached")

    assert_equal Rack::AcornCache::Storage.memecached, "memecached"

    Rack::AcornCache::Storage.remove_instance_variable(:@memecached)
  end
end
