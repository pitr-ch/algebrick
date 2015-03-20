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
  #noinspection RubyConstantNamingConvention
  module Types
    Maybe = Algebrick.type(:v) do
      variants None = atom,
               Some = type(:v) { fields :v }
    end

    module Maybe
      def maybe
        match self,
              on(None, nil),
              on(Some) { yield value }
      end
    end

    Boolean = Algebrick.type do
      variants TrueClass, FalseClass
    end

    List = Algebrick.type(:value_type) do |list|
      fields! value: :value_type, next: list
      variants EmptyList = atom, list
    end

    module List
      include Enumerable

      def each(&block)
        return to_enum unless block_given?

        it = self
        loop do
          break if EmptyList === it
          block.call it.value
          it = it.next
        end

        self
      end

      def next?
        self.next != EmptyList
      end

      def empty?
        !next?
      end

      def self.build(type, *items)
        items.reverse_each.reduce(EmptyList) { |list, item| self[type][item, list] }
      end
    end
  end

  include Types
end
