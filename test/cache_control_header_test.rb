require 'acorn_cache/cache_control_header'
require 'minitest/autorun'

class CacheControlHeaderTest < MiniTest::Test
  def test_max_age
    header_string = "max-age=30"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert_equal 30, cache_control_header.max_age
  end

  def test_max_age_not_present
    header_string = "private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    refute cache_control_header.max_age
  end

  def test_max_age_no_cache_control_header_present
    header_string = nil
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    refute cache_control_header.max_age
  end

  def test_max_age_not_well_formed
    header_string = "max-age=foo"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    max_age = cache_control_header.max_age

    refute max_age
  end

  def test_s_max_age
    header_string = "s-maxage=30"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    s_maxage = cache_control_header.s_maxage

    assert_equal 30, s_maxage
  end

  def test_assert_no_cache?
    header_string = "no-cache, private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert cache_control_header.no_cache?
  end

  def test_refute_no_cache?
    header_string = "private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    refute cache_control_header.no_cache?
  end

  def test_assert_no_store?
    header_string = "no-store, private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert cache_control_header.no_store?
  end

  def test_refute_no_store?
    header_string = "private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    refute cache_control_header.no_store?
  end

  def test_assert_must_revalidate?
    header_string = "no-store, must-revalidate, private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert_equal true, cache_control_header.must_revalidate?
  end

  def test_refute_must_revalidate?
    header_string = "private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    refute cache_control_header.must_revalidate?
  end

  def test_assert_private?
    header_string = "no-store, must-revalidate, private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert_equal true, cache_control_header.private?
  end

  def test_refute_private?
    header_string = "no-store"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    refute cache_control_header.private?
  end

  def test_max_fresh
    header_string = "no-store, max-fresh=30, private"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert_equal 30, cache_control_header.max_fresh
  end

  def test_max_stale_with_no_value_specified
    header_string = "max-stale"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert_equal true, cache_control_header.max_stale
  end

  def test_max_stale_with_value_specified
    header_string = "max-stale=30"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert_equal 30, cache_control_header.max_stale
  end

  def test_max_stale?
    header_string = "max-stale"
    cache_control_header = Rack::AcornCache::CacheControlHeader.new(header_string)
    assert true, cache_control_header.max_stale?
  end
end
