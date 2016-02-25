require 'acorn_cache/freshness_rules'
require 'minitest/autorun'

class FreshnessRulesTest < Minitest::Test
  def test_cached_response_fresh_for_request_when_no_cached_response_present
    cached_response = stub(present?: false)
    request = mock

    refute Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_when_cached_response_and_fresh_request_max_age_more_restrictive_cached_response_not_fresh_for_request
    cached_response = stub(present?: true, fresh?: true, date: Time.new(2015))
    request = stub(max_age: 30)
    Time.stubs(:now).returns(Time.new(2016))

    request.expects(:max_age_more_restrictive?).with(cached_response).returns(true)

    refute Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_when_cached_response_and_fresh_request_max_age_more_restrictive_cached_response_fresh_for_request
    cached_response = stub(present?: true, fresh?: true, date: Time.new(2016))
    request = stub(max_age: 30)
    Time.stubs(:now).returns(Time.new(2016))

    request.expects(:max_age_more_restrictive?).with(cached_response).returns(true)

    assert Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_when_cached_response_and_fresh_request_has_max_fresh_cached_response_not_fresh_for_request
    cached_response = stub(present?: true, fresh?: true, expiration_date: Time.new(2016) + 25)
    request = stub(max_age_more_restrictive?: false)
    Time.stubs(:now).returns(Time.new(2016))

    request.expects(:max_fresh).returns(30).times(2)

    refute Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_when_cached_response_and_fresh_request_has_max_fresh_cached_response_fresh_for_request
    cached_response = stub(present?: true, fresh?: true, expiration_date: Time.new(2016) + 35)
    request = stub(max_age_more_restrictive?: false)
    Time.stubs(:now).returns(Time.new(2016))

    request.expects(:max_fresh).returns(30).times(2)

    assert Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_cached_response_fresh_request_has_no_max_age_no_max_fresh
    cached_response = stub(present?: true, fresh?: true)
    request = stub(max_age_more_restrictive?: false, max_fresh: false)

    assert Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_cached_response_not_fresh_request_does_not_have_max_stale
    cached_response = stub(present?: true, fresh?: false)
    request = stub(max_stale?: false)

    refute Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_cached_response_not_fresh_request_max_stale_is_true
    cached_response = stub(present?: true, fresh?: false)
    request = stub(max_stale?: true, max_stale: true)

    assert Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_cached_response_not_fresh_request_max_stale_is_a_value_cached_response_not_fresh_for_request
    cached_response = stub(present?: true, fresh?: false, expiration_date: Time.new(2016))
    request = stub(max_stale?: true, max_stale: 30)
    Time.stubs(:now).returns(Time.new(2016) + 35)

    refute Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end

  def test_cached_response_not_fresh_request_max_stale_is_a_value_cached_response_fresh_for_request
    cached_response = stub(present?: true, fresh?: false, expiration_date: Time.new(2016))
    request = stub(max_stale?: true, max_stale: 30)
    Time.stubs(:now).returns(Time.new(2016) + 25)

    assert Rack::AcornCache::FreshnessRules.cached_response_fresh_for_request?(cached_response, request)
  end
end
