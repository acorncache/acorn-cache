require 'redis'

class Rack::AcornCache
  module RedisCache
    def self.redis
      @redis ||= Redis.new(host: ENV["ACORNCACHE_HOST"],
                           port: ENV["ACORNCACHE_PORT"].to_i,
                           password: ENV["ACORNCACHE_PASSWORD"])
    end
  end
end
