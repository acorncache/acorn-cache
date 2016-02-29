require 'rack'

class Rack::AcornCache
  class CacheControlHeader
    attr_accessor :max_age, :s_maxage, :no_cache, :no_store,
                  :must_revalidate, :private, :max_fresh, :max_stale

    def initialize(header_string = "")
      return unless header_string && !header_string.empty?
      set_directive_instance_variables!(header_string)
    end

    alias_method :max_stale?, :max_stale
    alias_method :no_cache?, :no_cache
    alias_method :private?, :private
    alias_method :no_store?, :no_store
    alias_method :must_revalidate?, :must_revalidate

    def to_s
      instance_variables.map do |ivar|
        directive = ivar.to_s.sub("@", "").sub("_", "-")
        value = instance_variable_get(ivar)
        next directive if value == true
        "#{directive}=#{value}"
      end.sort.join(", ")
    end

    private

    def set_directive_instance_variables!(header_string)
      header_string.gsub(/\s+/, "").split(",").each do |directive, result|
        k, v = directive.split("=")
        instance_variable_set(variable_symbol(k), directive_value(v))
      end
    end

    def variable_symbol(directive)
      "@#{directive.gsub("-", "_")}".to_sym
    end

    def directive_value(value)
      return value.to_i if value =~ /^[0-9]+$/
      return true if value.nil?
      value
    end
  end
end
