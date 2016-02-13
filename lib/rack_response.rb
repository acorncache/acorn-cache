class Rack::AcornCache::RackResponse < Rack::Response
  def eligible_for_caching?(whitelist)
    get? && status == 200 && whitelist.include?(path)
  end

  def to_json
    finish.to_json
  end
end
