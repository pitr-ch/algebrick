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
  module Serializers
    class Chain < Abstract
      def self.build(*serializers)
        serializers.reverse_each.reduce { |ch, s| new(s, ch) }
      end

      attr_reader :serializer, :chain_to

      def initialize(serializer, chain_to)
        @serializer = Type! serializer, Abstract
        @chain_to   = Type! chain_to, Abstract
      end

      def load(data, options = {})
        serializer.load chain_to.load(data, options), options
      end

      def dump(object, options = {})
        chain_to.dump serializer.dump(object, options), options
      end
    end
  end
end
