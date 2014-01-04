module Algebrick
  module Matchers
    class Variant < Wrapper
      def initialize(something)
        raise ArgumentError unless something.variants
        Type! something, Algebrick::ProductVariant
        super something
      end

      def to_s
        assign_to_s + "#{@something.name}.to_m"
      end
    end
  end
end
