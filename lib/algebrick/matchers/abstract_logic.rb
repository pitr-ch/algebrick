module Algebrick
  module Matchers
    class AbstractLogic < Abstract
      def self.call(*matchers)
        new *matchers
      end

      attr_reader :matchers

      def initialize(*matchers)
        @matchers = matchers.each { |m| matchable! m }
      end

      def children
        find_children matchers
      end

      def ==(other)
        other.kind_of? self.class and
            self.matchers == other.matchers
      end
    end
  end
end
