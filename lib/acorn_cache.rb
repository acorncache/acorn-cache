require 'rack'
require 'redis_cache'

class Rack::AcornCache
  def initialize(app)
    @app = app
  end

  def call(env)
    @env = env

    if url_whitelisted? && cached_response
      return [200, cached_headers, [cached_body]]
    end

    @status, @headers, @body = @app.call(env)
    cache_response if response_eligible_for_caching?
    [@status, @headers, @body]
  end

  private

  def redis
    RedisCache.redis
  end

  def url_whitelisted?
    config["whitelisted_urls"].include?(@env["REQUEST_PATH"])
  end

  def config
    @config ||= begin
      config_path = root_directory + "/.acorncache.yml"
      config_yml = File.read(config_path)
      YAML.load(config_yml)
    end
  end

  def root_directory
    @root_dir ||= Rack::Directory.new("").root
  end

  def cached_response
    cached_response = redis.get(@env["REQUEST_PATH"])
    return false unless cached_response
    @cached_response = JSON.parse(cached_response)
  end

  def cached_headers
    @cached_response["headers"].merge!("X-From-Redis-Cache" => "true")
  end

  def cached_body
    @cached_response["body"]
  end

  def cachable_response
    JSON[headers: @headers, body: cachable_body]
  end

  def cachable_body
    @cachable_body = ''
    @body.each { |part| @cachable_body << part }
    @cachable_body
  end

  def response_eligible_for_caching?
    return false unless @status == 200

    if config["whitelisted_urls"]
      url_whitelisted?
    else
      permitted_response_content_type?
    end
  end

  def permitted_response_content_type?
    permitted_content_types = config["permitted_content_types"]
    header_content_type = @headers["Content-Type"]

    if permitted_content_types
      permitted_content_types.any? do |permitted_content_type|
        header_content_type.include?(permitted_content_type)
      end
    else
      header_content_type.include?("text/html")
    end
  end

  def cache_response
    redis.set(@env["REQUEST_PATH"], cachable_response)
  end
end
