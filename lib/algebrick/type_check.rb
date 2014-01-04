module Algebrick
  #noinspection RubyInstanceMethodNamingConvention
  module TypeCheck
    # FIND: type checking of collections?

    def Type?(value, *types)
      types.any? { |t| value.is_a? t }
    end

    def Type!(value, *types)
      Type?(value, *types) or
          TypeCheck.error(value, 'is not', types)
      value
    end

    def Match?(value, *types)
      types.any? { |t| t === value }
    end

    def Match!(value, *types)
      Match?(value, *types) or
          TypeCheck.error(value, 'is not matching', types)
      value
    end

    def Child?(value, *types)
      Type?(value, Class) &&
          types.any? { |t| value <= t }
    end

    def Child!(value, *types)
      Child?(value, *types) or
          TypeCheck.error(value, 'is not child', types)
      value
    end

    private

    def self.error(value, message, types)
      raise TypeError,
            "Value (#{value.class}) '#{value}' #{message} any of: #{types.join('; ')}."
    end
  end
end
