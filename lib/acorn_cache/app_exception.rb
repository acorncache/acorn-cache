class Rack::AcornCache
  class AppException < StandardError
    attr_reader :caught_exception

    def initialize(caught_exception)
      @caught_exception = caught_exception
    end
  end
end
