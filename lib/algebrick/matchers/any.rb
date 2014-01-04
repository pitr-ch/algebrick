module Algebrick
  module Matchers
    class Any < Abstract
      def children
        []
      end

      def to_s
        assign_to_s + 'any'
      end

      def ==(other)
        other.kind_of? self.class
      end

      protected

      def matching?(other)
        true
      end
    end
  end
end
