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
  module DSL
    module Shortcuts
      def type(*variables, &block)
        Algebrick.type *variables, &block
      end

      def atom
        Algebrick.atom
      end
    end

    class TypeDefinitionScope
      include Shortcuts
      include TypeCheck

      attr_reader :new_type

      def initialize(new_type, &block)
        @new_type = Type! new_type, ProductVariant, ParametrizedType
        instance_exec @new_type, &block
        @new_type.kind if @new_type.is_a? ProductVariant
      end

      def fields(*fields)
        @new_type.set_fields fields.first.is_a?(Hash) ? fields.first : fields
        self
      end

      def fields!(*fields)
        fields(*fields)
        all_readers
      end

      def variants(*variants)
        @new_type.set_variants variants
        self
      end

      def field_readers(*names)
        @new_type.add_field_method_readers *names
        self
      end

      alias_method :readers, :field_readers

      def all_field_readers
        @new_type.add_all_field_method_readers
        self
      end

      alias_method :all_readers, :all_field_readers
    end

    class OuterShell
      include Shortcuts

      def initialize(&block)
        instance_eval &block
      end
    end
  end

  def self.type(*variables, &block)
    if block.nil?
      raise 'Atom cannot be parametrized' unless variables.empty?
      atom
    else
      if variables.empty?
        DSL::TypeDefinitionScope.new(ProductVariant.new(nil), &block).new_type
      else
        DSL::TypeDefinitionScope.new(ParametrizedType.new(variables), &block).new_type
      end
    end
  end

  def self.atom
    Atom.new nil
  end

  def self.types(&block)
    DSL::OuterShell.new &block
  end

end
