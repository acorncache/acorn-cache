require 'redis'

class Rack::AcornCache
  module RedisCache
    def self.redis
      args = { host: ENV["ACORNCACHE_HOST"],
               port: ENV["ACORNCACHE_PORT"].to_i }

      if ENV["ACORNCACHE_REDIS_PASSWORD"]
        args.merge!(password: ENV["ACORNCACHE_REDIS_PASSWORD"])
      end

      @redis ||= Redis.new(args)
    end
  end
end
