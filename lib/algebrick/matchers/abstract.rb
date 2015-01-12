#  Copyright 2013 Petr Chalupa <git+algebrick@pitr.ch>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

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

      def assign!
        @assign = true
        self
      end

      alias_method :~, :assign!

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

      def assigned?
        !!@value
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
