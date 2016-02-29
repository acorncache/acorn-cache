require 'redis'
require 'dalli'

class Rack::AcornCache
  module Storage
    def self.redis
      args = { host: ENV["ACORNCACHE_REDIS_HOST"],
               port: ENV["ACORNCACHE_REDIS_PORT"].to_i }
      if ENV["ACORNCACHE_REDIS_PASSWORD"]
        args.merge!(password: ENV["ACORNCACHE_REDIS_PASSWORD"])
      end

      @redis ||= Redis.new(args)
    end

    def self.memcached
      options = {}

      if ENV["ACORNCACHE_MEMCACHED_USERNAME"]
        options = { username: ENV["ACORNCACHE_MEMCACHED_USERNAME"],
                    password: ENV["ACORNCACHE_MEMCACHED_PASSWORD"] }
      end

      @memcached ||= Dalli::Client.new(ENV["ACORNCACHE_MEMCACHED_URL"], options)
    end
  end
end
