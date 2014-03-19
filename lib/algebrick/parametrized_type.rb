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
  require 'monitor'

  class ParametrizedType < Type
    include TypeCheck
    include MatcherDelegations

    attr_reader :variables, :fields, :variants

    def initialize(variables)
      @variables     = variables.each { |v| Type! v, Symbol }
      @fields        = nil
      @variants      = nil
      @cache         = {}
      @cache_barrier = Monitor.new
    end

    def set_fields(fields)
      @fields = Type! fields, Hash, Array
    end

    def field_names
      case @fields
      when Hash
        @fields.keys
      when Array, nil
        raise TypeError, "field names not defined on #{self}"
      else
        raise
      end
    end

    def set_variants(variants)
      @variants = Type! variants, Array
    end

    def [](*assigned_types)
      @cache_barrier.synchronize do
        @cache[assigned_types] || begin
          raise ArgumentError unless assigned_types.size == variables.size
          ProductVariant.new(type_name(assigned_types)).tap do |type|
            type.be_kind_of self
            @cache[assigned_types] = type
            type.assigned_types    = assigned_types
            type.set_variants insert_types(variants, assigned_types) if variants
            type.set_fields insert_types(fields, assigned_types) if fields
          end
        end
      end
    end

    def to_s
      "#{name}[#{variables.join(', ')}]"
    end

    def inspect
      to_s
    end

    def to_m
      if @variants
        Matchers::Variant.new self
      else
        Matchers::Product.new self
      end
    end

    def call(*field_matchers)
      raise TypeError unless @fields
      Matchers::Product.new self, *field_matchers
    end

    def ==(other)
      other.kind_of? ParametrizedType and
          self[*Array(variables.size) { Object }] ==
              other[*Array(other.variables.size) { Object }]
    end

    private

    def insert_types(types, assigned_types)
      case types
      when Hash
        types.inject({}) { |h, (k, v)| h.update k => insert_type(v, assigned_types) }
      when Array
        types.map { |v| insert_type v, assigned_types }
      else
        raise ArgumentError
      end
    end

    def insert_type(type, assigned_types)
      case type
      when Symbol
        assigned_types[variables.index type]
      when ParametrizedType
        type[*type.variables.map { |v| assigned_types[variables.index v] }]
      else
        type
      end
    end

    def type_name(assigned_types)
      "#{name}[#{assigned_types.join(', ')}]"
    end
  end
end
