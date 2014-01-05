module Algebrick
  module Matchers
    class Abstract
      include TypeCheck
      attr_reader :value

      def initialize
        @assign, @value, @matched = nil
      end

      def case(&block)
        return self, block
      end

      alias_method :when, :case

      def >(block)
        return self, block
      end

      alias_method :>>, :>

      def ~
        @assign = true
        self
      end

      def &(matcher)
        And.new self, matcher
      end

      def |(matcher)
        Or.new self, matcher
      end

      def !
        Not.new self
      end

      def assign?
        @assign
      end

      def matched?
        @matched
      end

      def children_including_self
        children.unshift self
      end

      def assigns
        collect_assigns.tap do
          return yield *assigns if block_given?
        end
      end

      def to_a
        assigns
      end

      def ===(other)
        matching?(other).tap { |matched| @value = other if (@matched = matched) }
      end

      def assign_to_s
        assign? ? '~' : ''
      end

      def inspect
        to_s
      end

      def children
        raise NotImplementedError
      end

      def to_s
        raise NotImplementedError
      end

      def ==(other)
        raise NotImplementedError
      end

      # TODO pretty_print for all matchers

      protected

      def matching?(other)
        raise NotImplementedError
      end

      private

      def collect_assigns
        mine = @assign ? [@value] : []
        children.inject(mine) { |assigns, child| assigns + child.assigns }
      end

      def matchable!(obj)
        raise ArgumentError, 'object does not respond to :===' unless obj.respond_to? :===
        obj
      end

      def find_children(collection)
        collection.map do |matcher|
          matcher if matcher.kind_of? Abstract
        end.compact
      end
    end
  end
end
