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
    #noinspection RubyClassModuleNamingConvention
    class Or < AbstractLogic
      def to_s
        matchers.join ' | '
      end

      protected

      def matching?(other)
        matchers.any? { |m| m === other }
      end

      alias_method :super_children, :children
      private :super_children

      def children
        super.select &:matched?
      end

      private

      def collect_assigns
        super.tap do |assigns|
          missing = assigns_size - assigns.size
          assigns.push(*::Array.new(missing))
        end
      end

      def assigns_size
        # TODO is it efficient?
        super_children.map { |ch| ch.assigns.size }.max
      end
    end
  end
end
