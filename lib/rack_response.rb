require 'rack'

class RackResponse < Rack::Response
  attr_reader :status, :headers, :body

  def initialize(status, headers, body)
    @status = status
    @headers = headers
    @body = body
  end

  def eligible_for_caching?
    status == 200
  end

  def to_json
    { status: status, headers: headers, body: body_string }.to_json
  end

  def body_string
    result = ""
    body.each { |part| result << part }
    result
  end

  def to_a
    [status, headers, body]
  end
end
