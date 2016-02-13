class Rack::AcornCache::CachedResponse < Rack::Response
  def initialize(args={})
    super(args["body"], 200, args["header"])
  end

  def add_x_from_acorn_cache_header
    headers["X-From-Acorn-Cache"] = "true"
  end
end
