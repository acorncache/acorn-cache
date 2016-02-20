require 'rack/request'

class Rack::AcornCache
  class Request < Rack::Request
    def cache_control_header
      @env["HTTP_CACHE_CONTROL"]
    end
  end
end
