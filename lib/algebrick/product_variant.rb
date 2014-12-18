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
  # Representation of Product and Variant types. The class behaves differently
  # based on #kind.
  #noinspection RubyTooManyMethodsInspection
  class ProductVariant < Type
    # TODO split up into classes or modules
    # TODO aliases for fields, (update matchers)

    include FieldMethodReaders
    attr_reader :fields, :variants

    def initialize(name, &definition)
      super(name, &definition)
      @to_be_kind_of = []
      @final_variants  = false
    end

    def set_fields(fields_or_hash)
      raise TypeError, 'can be set only once' if @fields
      @kind        = nil
      fields, keys = case fields_or_hash
                     when Hash
                       [fields_or_hash.values, fields_or_hash.keys]
                     when Array
                       [fields_or_hash, nil]
                     else
                       raise ArgumentError
                     end

      add_field_names keys if keys

      fields.all? { |f| Type! f, Type, Class, Module }
      raise TypeError, 'there is no product with zero fields' unless fields.size > 0
      define_method(:value) { @fields.first } if fields.size == 1
      @fields      = fields
      @constructor = Class.new(
          field_names? ? ProductConstructors::Named : ProductConstructors::Basic).
          tap { |c| c.type = self }
      const_set :Constructor, @constructor
      apply_be_kind_of
      self
    end

    def field_indexes
      @field_indexes or raise TypeError, "field names not defined on #{self}"
    end

    def field(name)
      fields[field_indexes[name]]
    end

    def final!
      @final_variants = true
      self
    end

    def set_variants(*variants)
      raise TypeError, 'can be set only once' if @variants && @final_variants
      @kind = nil
      variants.all? { |v| Type! v, Type, Class }
      @variants ||= []
      @variants += variants
      apply_be_kind_of
      variants.each do |v|
        if v.respond_to? :be_kind_of
          v.be_kind_of self
        else
          v.send :include, self
        end
      end
      self
    end

    def new(*fields)
      raise TypeError, "#{self} does not have fields" unless @constructor
      @constructor.new *fields
    end

    alias_method :[], :new

    def ==(other)
      other.kind_of? ProductVariant and
          variants == other.variants and fields == other.fields
    end

    def be_kind_of(type)
      @to_be_kind_of << type
      apply_be_kind_of
    end

    def apply_be_kind_of
      @to_be_kind_of.each do |type|
        @constructor.send :include, type if @constructor
        variants.each { |v| v.be_kind_of type unless v == self } if @variants
      end
    end

    def call(*field_matchers)
      raise TypeError, "#{self} does not have any fields" unless @fields
      Matchers::Product.new self, *field_matchers
    end

    def to_m
      case kind
      when :product
        Matchers::Product.new self
      when :product_variant
        Matchers::Variant.new self
      when :variant
        Matchers::Variant.new self
      else
        raise
      end
    end

    def to_s
      case kind
      when :product
        product_to_s
      when :product_variant
        name + '(' +
            variants.map do |variant|
              if variant == self
                product_to_s
              else
                variant.name
              end
            end.join(' | ') +
            ')'
      when :variant
        "#{name}(#{variants.map(&:name).join ' | '})"
      else
        raise
      end
    end

    #noinspection RubyCaseWithoutElseBlockInspection
    def kind
      @kind ||= case
                when @fields && !@variants
                  :product
                when @fields && @variants
                  :product_variant
                when !@fields && @variants
                  :variant
                when !@fields && !@variants
                  raise TypeError, 'fields or variants have to be set'
                end
    end

    def assigned_types
      @assigned_types or raise TypeError, "#{self} does not have assigned types"
    end

    def assigned_types=(assigned_types)
      raise TypeError, "#{self} assigned types already set" if @assigned_types
      @assigned_types = assigned_types
    end

    private

    def product_to_s
      fields_str = if field_names?
                     field_names.zip(fields).map { |name, field| "#{name}: #{field.name}" }
                   else
                     fields.map(&:name)
                   end
      "#{name}(#{fields_str.join ', '})"
    end

    def add_field_names(names)
      @field_names = names
      names.all? { |k| Type! k, Symbol }
      dict = @field_indexes =
          Hash.new { |_, k| raise ArgumentError, "unknown field #{k.inspect} in #{self}" }.
              update names.each_with_index.inject({}) { |h, (k, i)| h.update k => i }
      define_method(:[]) { |key| @fields[dict[key]] }
      # TODO use attr_readers to speed things up
    end
  end
end
