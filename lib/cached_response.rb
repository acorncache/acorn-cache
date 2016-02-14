class CachedResponse
  attr_reader :body, :status, :headers

  def initialize(args={})
    @body = args["body"]
    @status = args["status"]
    @headers = args["headers"]
  end

  def add_x_from_acorn_cache_header
    headers["X-From-Acorn-Cache"] = "true"
  end

  def to_a
    [status, headers, [body]]
  end
end
