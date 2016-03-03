require 'minitest/autorun'
require 'acorn_cache/cache_writer'
require 'mocha/mini_test'

class CacheWriterTest < Minitest::Test
  def test_writes_to_cache_with_appropriate_values
    Rack::AcornCache.configure {}
    storage = mock("storage")
    storage.expects(:set).with("path", "response").returns("OK")
    Rack::AcornCache.configuration.expects(:storage).returns(storage)

    assert_equal Rack::AcornCache::CacheWriter.write("path", "response"), "OK"

    Rack::AcornCache.configuration = nil
  end
end
