module Algebrick
  module Matchers
    class Array < Abstract
      def self.call(*matchers)
        new *matchers
      end

      attr_reader :matchers

      def initialize(*matchers)
        super()
        @matchers = matchers
      end

      def children
        find_children @matchers
      end

      def to_s
        "#{assign_to_s}#{"Array.(#{matchers.join(',')})" if matchers}"
      end

      def ==(other)
        other.kind_of? self.class and
            self.matchers == other.matchers
      end

      protected

      def matching?(other)
        other.kind_of? ::Array and
            matchers.size == other.size and
            matchers.each_with_index.all? { |m, i| m === other[i] }
      end
    end

    class ::Array
      def self.call(*matchers)
        Matchers::Array.new *matchers
      end
    end
  end
end
