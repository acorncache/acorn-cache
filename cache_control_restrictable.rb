module CacheControlRestrictable
  CACHE_CONTROL_RESTRICTIONS = ["no-cache", "no-store", "private"]

  def max_age
    headers["Cache-Control"][/\d+/].to_i
  end

  def max_age_specified?
    headers["Cache-Control"] && headers["Cache-Control"].include?("max-age")
  end

  private

  def caching_restrictions?
    CACHE_CONTROL_RESTRICTIONS.any? do |restriction|
      headers['Cache-Control'].include?(restriction)
    end
  end
end
