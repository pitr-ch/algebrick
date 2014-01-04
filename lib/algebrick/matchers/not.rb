module Algebrick
  module Matchers
    class Not < Abstract
      attr_reader :matcher

      def initialize(matcher)
        @matcher = matcher
      end

      def children
        []
      end

      def to_s
        '!' + matcher.to_s
      end

      def ==(other)
        other.kind_of? self.class and
            self.matcher == other.matcher
      end

      protected

      def matching?(other)
        not matcher === other
      end
    end
  end
end
