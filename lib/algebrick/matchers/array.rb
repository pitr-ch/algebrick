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
