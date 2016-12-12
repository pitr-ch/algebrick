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
  module ProductConstructors
    class Abstract
      include Value
      extend TypeCheck
      attr_reader :fields

      def initialize(*fields)
        if fields.size == 1 && fields.first.is_a?(Hash)
          fields = type.field_names.map { |k| fields.first[k] }
        end
        @fields = fields.zip(self.class.type.fields).map { |field, type| Type! field, type }.freeze
      end

      def to_ary
        @fields
      end

      def to_a
        @fields
      end

      def ==(other)
        return false unless other.kind_of? self.class
        @fields == other.fields
      end

      alias_method :eql?, :==

      def hash
        [self.class, @fields].hash
      end

      def self.type
        @type || raise
      end

      def type
        self.class.type
      end

      def self.name
        @type.to_s
      end

      def self.to_s
        name
      end

      def self.type=(type)
        Type! type, ProductVariant
        raise if @type
        @type = type
        include type
      end

      def update(*fields)
        raise NotImplementedError
      end
    end
  end
end
