module CacheControlRestrictable
  CACHE_CONTROL_RESTRICTIONS = ["no-cache", "no-store", "private"]

  def max_age_in_seconds
    return nil unless headers["Cache-Control"] &&
                        headers["Cache-Control"].include?("max-age")
    headers["Cache-Control"][/\d+/].to_i
  end

  private

  def caching_restrictions?
    CACHE_CONTROL_RESTRICTIONS.any? do |restriction|
      headers['Cache-Control'].include?(restriction)
    end
  end
end
