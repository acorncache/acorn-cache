class Rack::AcornCache
  module FreshnessRules
    def self.cached_response_fresh_for_request?(cached_response, request)
      return false unless cached_response
      if cached_response.fresh?
        if request.max_age_more_restrictive?(cached_response)
          return cached_response.date + request.max_age >= Time.now
        elsif request.max_fresh
          return cached_response.expiration_date - request.max_fresh >= Time.now
        end
        true
      else
        return false unless request.max_stale?
        return true if request.max_stale == true
        cached_response.expiration_date + request.max_stale >= Time.now
      end
    end
  end
end
