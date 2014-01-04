module Algebrick
  module Matchers
    # wraps any object having #=== method into matcher
    class Wrapper < Abstract
      def self.call(something)
        new something
      end

      attr_reader :something

      def initialize(something)
        super()
        @something = matchable! something
      end

      def children
        find_children [@something]
      end

      def to_s
        assign_to_s + "Wrapper.(#{@something})"
      end

      def ==(other)
        other.kind_of? self.class and
            self.something == other.something
      end

      protected

      def matching?(other)
        @something === other
      end
    end

    # allow to convert any object to matcher if it has #=== method
    class ::Object
      def to_m
        Wrapper.new(self)
      end
    end
  end
end
