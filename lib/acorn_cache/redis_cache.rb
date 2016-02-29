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

    def self.memecached
      if ENV["ACORNCACHE_MEMECACHED_USERNAME"]
        options = { username: ENV["ACORNCACHE_MEMECACHED_USERNAME"],
                    password: ENV["ACORNCACHE_MEMECACHED_PASSWORD"] }
      else
        options = {}
      end

      @memecached ||= Dalli::Client.new(ENV["ACORNCACHE_MEMECACHED_URL"], options)
    end
  end
end
