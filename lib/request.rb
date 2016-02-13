class Rack::AcornCache::Request < Rack::Request
  def url_whitelisted?(config)
    config.whitelisted_urls.include?(path)
  end
end
