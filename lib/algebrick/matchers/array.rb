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
    class Array < Abstract
      def self.call(*matchers)
        new *matchers
      end

      attr_reader :matchers

      def initialize(*matchers)
        super()
        @matchers = matchers
        raise ArgumentError, 'many can be only last' if @matchers[0..-2].any? { |v| v.is_a?(Many) }
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

      def rest?
        matchers.last.is_a?(Many)
      end

      protected

      def matching?(other)
        return false unless other.kind_of? ::Array
        if rest?
          matchers[0..-2].zip(other).all? { |m, v| m === v } and
              matchers.last === other[(matchers.size-1)..-1]
        else
          matchers.size == other.size and
              matchers.zip(other).all? { |m, v| m === v }
        end
      end
    end

    class ::Array
      def self.call(*matchers)
        Matchers::Array.new *matchers
      end
    end
  end
end
