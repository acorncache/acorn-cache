class CapstoneCaching
  def initialize(app)
    @app = app
  end

  def call(env)
    return [200, cached_headers, [cached_body]] if cached_response(env)
    @status, @headers, @body = @app.call(env)
    redis.set(env["REQUEST_PATH"], cachable_response) if @status == 200
    [@status, @headers, @body]
  end

  private

  def redis
    RedisCache.redis
  end

  def cached_response(env)
    cached_response = redis.get(env["REQUEST_PATH"])
    return false unless cached_response
    @cached_response = JSON.parse(cached_response)
  end

  def cached_headers
    @cached_response["headers"].merge!({"X-From-Redis-Cache" => "true"})
  end

  def cached_body
    @cached_response["body"]
  end

  def cachable_response
    JSON[{headers: @headers, body: cachable_body}]
  end

  def cachable_body
    @cachable_body = ''
    @body.each { |part| @cachable_body << part }
    @cachable_body
  end
  
  module RedisCache
    def self.redis
      @redis ||= Redis.new(
                  host: 'pub-redis-11997.us-east-1-3.7.ec2.redislabs.com',
                  port: 11997,
                  password: '123123'
                )
    end
  end
end
