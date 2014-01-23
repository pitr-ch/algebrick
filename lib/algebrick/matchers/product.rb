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
    class Product < Abstract
      attr_reader :algebraic_type, :field_matchers

      def initialize(algebraic_type, *field_matchers)
        super()
        @algebraic_type = Type! algebraic_type, Algebrick::ProductVariant, Algebrick::ParametrizedType
        raise ArgumentError unless algebraic_type.fields
        @field_matchers = case

                            # AProduct.()
                          when field_matchers.empty?
                            ::Array.new(algebraic_type.fields.size) { Algebrick.any }

                            # AProduct.(field_name: a_matcher)
                          when field_matchers.size == 1 && field_matchers.first.is_a?(Hash)
                            field_matchers = field_matchers.first
                            unless (dif = field_matchers.keys - algebraic_type.field_names).empty?
                              raise ArgumentError, "no #{dif} fields in #{algebraic_type}"
                            end
                            algebraic_type.field_names.map do |field|
                              field_matchers.key?(field) ? field_matchers[field] : Algebrick.any
                            end

                            # normal
                          else
                            field_matchers
                          end
        unless algebraic_type.fields.size == @field_matchers.size
          raise ArgumentError
        end
      end

      def children
        find_children @field_matchers
      end

      def to_s
        assign_to_s + "#{@algebraic_type.name}.(#{@field_matchers.join(', ')})"
      end

      def ==(other)
        other.kind_of? self.class and
            self.algebraic_type == other.algebraic_type and
            self.field_matchers == other.field_matchers
      end

      protected

      def matching?(other)
        other.kind_of?(@algebraic_type) and other.kind_of?(ProductConstructors::Abstract) and
            @field_matchers.zip(other.fields).all? do |matcher, field|
              matcher === field
            end
      end
    end
  end
end
