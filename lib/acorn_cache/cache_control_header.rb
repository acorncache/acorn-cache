require 'rack'

class Rack::AcornCache
  class CacheControlHeader
    attr_accessor :max_age, :s_maxage, :no_cache, :no_store,
                  :must_revalidate, :private, :max_fresh, :max_stale

    def initialize(header_string = "")
      @header_string = header_string
      return unless @header_string
      set_directive_instance_variables!
    end

    alias_method :max_stale?, :max_stale
    alias_method :no_cache?, :no_cache
    alias_method :private?, :private
    alias_method :no_store?, :no_store
    alias_method :must_revalidate?, :must_revalidate

    private

    def set_directive_instance_variables!
      @header_string.gsub(/\s+/, "").split(",").each do |directive, result|
        k, v = directive.split("=")
        send(writer_method(k), directive_value(v)) rescue NoMethodError
      end
    end

    def writer_method(directive)
      "#{directive.gsub("-", "_")}=".to_sym
    end

    def directive_value(value)
      return value.to_i if value =~ /^[0-9]+$/
      value.nil?
    end
  end
end
