class AppExcpetion < StandardError
  attr_reader :caught_exception

  def initialize(caught_exception)
    @caught_exception = caught_exception
  end
end
