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


# TODO method definition in variant type defines methods on variants based on match, better performance?
# TODO add matcher/s for Hash
# TODO add method matcher (:size, matcher)
# TODO Menu modeling example, add TypedArray
# TODO update actor pattern example when gem is done
# TODO gemmify reclude
# TODO gemmify typecheck

require 'monitor'


# Provides Algebraic types and pattern matching
#
# **Quick example**
# {include:file:doc/quick_example.out.rb}
module Algebrick

  def self.version
    @version ||= Gem::Version.new File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  end

  # fix module to re-include itself to where it was already included when a module is included into it
  module Reclude
    def included(base)
      included_into << base
      super base
    end

    def include(*modules)
      super(*modules)
      modules.reverse.each do |module_being_included|
        included_into.each do |mod|
          mod.send :include, module_being_included
        end
      end
    end

    private

    def included_into
      @included_into ||= []
    end
  end

  module TypeCheck
    # FIND: type checking of collections?

    def Type?(value, *types)
      types.any? { |t| value.is_a? t }
    end

    def Type!(value, *types)
      Type?(value, *types) or
          TypeCheck.error(value, 'is not', types)
      value
    end

    def Match?(value, *types)
      types.any? { |t| t === value }
    end

    def Match!(value, *types)
      Match?(value, *types) or
          TypeCheck.error(value, 'is not matching', types)
      value
    end

    def Child?(value, *types)
      Type?(value, Class) &&
          types.any? { |t| value <= t }
    end

    def Child!(value, *types)
      Child?(value, *types) or
          TypeCheck.error(value, 'is not child', types)
      value
    end

    private

    def self.error(value, message, types)
      raise TypeError,
            "Value (#{value.class}) '#{value}' #{message} any of: #{types.join('; ')}."
    end
  end

  # include this module anywhere yoy need to use pattern matching
  module Matching
    def any
      Matchers::Any.new
    end

    def match(value, *cases)
      cases = if cases.size == 1 && cases.first.is_a?(Hash)
                cases.first
              else
                cases
              end

      cases.each do |matcher, block|
        return Matching.match_value matcher, block if matcher === value
      end
      raise "no match for (#{value.class}) '#{value}' by any of #{cases.map(&:first).join ', '}"
    end

    def on(matcher, value = nil, &block)
      matcher = if matcher.is_a? Matchers::Abstract
                  matcher
                else
                  matcher.to_m
                end
      raise ArgumentError, 'only one of block or value can be supplied' if block && value
      [matcher, value || block]
    end

    # FIND: #match! raise when match is not complete on a given type

    private

    def self.match_value(matcher, block)
      if block.kind_of? Proc
        if matcher.kind_of? Matchers::Abstract
          matcher.assigns &block
        else
          block.call
        end
      else
        block
      end
    end
  end

  include Matching
  extend Matching

  module MatcherDelegations
    def ~
      ~to_m
    end

    def &(other)
      to_m & other
    end

    def |(other)
      to_m | other
    end

    def !
      !to_m
    end

    def case(&block)
      to_m.case &block
    end

    def >>(block)
      to_m >> block
    end

    def >(block)
      to_m > block
    end
  end

  # Any Algebraic type defined by Algebrick is kind of Type
  class Type < Module
    include TypeCheck
    include Matching
    include MatcherDelegations
    include Reclude

    def initialize(name, &definition)
      super &definition
      @name = name
    end

    def name
      super || @name
    end

    def to_m(*args)
      raise NotImplementedError
    end

    def ==(other)
      raise NotImplementedError
    end

    def be_kind_of(type)
      raise NotImplementedError
    end

    def to_s
      raise NotImplementedError
    end

    def inspect
      to_s
    end
  end

  # Any value of Algebraic type is kind of Value
  module Value
    include TypeCheck
    include Matching

    def ==(other)
      raise NotImplementedError
    end

    def type
      raise NotImplementedError
    end

    def to_hash
      raise NotImplementedError
    end

    def to_s
      raise NotImplementedError
    end

    def inspect
      to_s
    end
  end

  TYPE_KEY   = :algebrick
  FIELDS_KEY = :fields

  # Representation of Atomic types
  class Atom < Type
    include Value

    def initialize(name, &block)
      super name, &block
      extend self
    end

    def to_m
      Matchers::Atom.new self
    end

    def be_kind_of(type)
      extend type
    end

    def ==(other)
      self.equal? other
    end

    def type
      self
    end

    def to_s
      name
    end

    def to_hash
      { TYPE_KEY => name }
    end

    def from_hash(hash)
      if hash == to_hash
        self
      else
        raise ArgumentError
      end
    end
  end

  # A private class used for Product values creation
  class ProductConstructor
    include Value
    attr_reader :fields

    def initialize(*fields)
      if fields.size == 1 && fields.first.is_a?(Hash)
        fields = type.field_names.map { |k| fields.first[k] }
      end
      @fields = fields.zip(self.class.type.fields).map { |field, type| Type! field, type }.freeze
    end

    def to_s
      "#{self.class.type.name}[" +
          if type.field_names?
            type.field_names.map { |name| "#{name}: #{self[name].to_s}" }.join(', ')
          else
            fields.map(&:to_s).join(', ')
          end + ']'
    end

    def pretty_print(q)
      q.group(1, "#{self.class.type.name}[", ']') do
        if type.field_names?
          type.field_names.each_with_index do |name, i|
            if i == 0
              q.breakable ''
            else
              q.text ','
              q.breakable ' '
            end
            q.text name.to_s
            q.text ':'
            q.group(1) do
              q.breakable ' '
              q.pp self[name]
            end
          end
        else
          fields.each_with_index do |value, i|
            if i == 0
              q.breakable ''
            else
              q.text ','
              q.breakable ' '
            end
            q.pp value
          end
        end
      end
    end

    def to_ary
      @fields
    end

    def to_a
      @fields
    end

    def to_hash
      { TYPE_KEY => self.class.type.name }.
          update(if type.field_names?
                   type.field_names.inject({}) { |h, name| h.update name => hashize(self[name]) }
                 else
                   { FIELDS_KEY => fields.map { |v| hashize v } }
                 end)
    end

    def ==(other)
      return false unless other.kind_of? self.class
      @fields == other.fields
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
      raise if @type
      @type = type
      include type
    end

    private

    def hashize(value)
      (value.respond_to? :to_hash) ? value.to_hash : value
    end
  end

  # Representation of Product and Variant types. The class behaves differently
  # based on #kind.
  class ProductVariant < Type
    attr_reader :fields, :variants

    def initialize(name, &definition)
      super(name, &definition)
      @to_be_kind_of = []
    end

    def set_fields(fields_or_hash)
      raise TypeError, 'can be set only once' if @fields
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
      @constructor = Class.new(ProductConstructor).tap { |c| c.type = self }
      apply_be_kind_of
      self
    end

    def field_names
      @field_names or raise TypeError, "field names not defined on #{self}"
    end

    def field_names?
      !!@field_names
    end

    def field_indexes
      @field_indexes or raise TypeError, "field names not defined on #{self}"
    end

    def add_field_method_reader(field)
      raise TypeError, 'no field names' unless field_names?
      raise ArgumentError, "no field name #{field}" unless field_names.include? field
      raise ArgumentError, "method #{field} already defined" if instance_methods.include? field
      define_method(field) { self[field] }
      self
    end

    def add_field_method_readers(*fields)
      fields.each { |f| add_field_method_reader f }
      self
    end

    def add_all_field_method_readers
      add_field_method_readers *@field_names
    end

    def set_variants(variants)
      raise TypeError, 'can be set only once' if @variants
      variants.all? { |v| Type! v, Type, Class }
      @variants = variants
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

    def from_hash(hash)
      case kind
      when :product
        product_from_hash hash
      when :product_variant
        product_from_hash hash
      when :variant
        field_from_hash hash
      else
        raise
      end
    end

    def kind
      case
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
          Hash.new { |h, k| raise ArgumentError, "unknown field #{k.inspect} in #{self}" }.
              update names.each_with_index.inject({}) { |h, (k, i)| h.update k => i }
      define_method(:[]) { |key| @fields[dict[key]] }
    end

    def product_from_hash(hash)
      (type_name = hash[TYPE_KEY] || hash[TYPE_KEY.to_s]) or
          raise ArgumentError, "hash does not have #{TYPE_KEY}"
      raise ArgumentError, "#{type_name} is not #{name}" unless type_name == name

      fields = hash[FIELDS_KEY] || hash[FIELDS_KEY.to_s] ||
          hash.reject { |k, _| k.to_s == TYPE_KEY.to_s }
      Type! fields, Hash, Array

      case fields
      when Array
        self[*fields.map { |value| field_from_hash value }]
      when Hash
        self[fields.inject({}) do |h, (name, value)|
          raise ArgumentError unless field_names.map(&:to_s).include? name.to_s
          h.update name.to_sym => field_from_hash(value)
        end]
      end
    end

    def field_from_hash(hash)
      return hash unless Hash === hash
      (type_name = hash[TYPE_KEY] || hash[TYPE_KEY.to_s]) or return hash
      type = constantize type_name
      type.from_hash hash
    end

    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      parameter = nil
      names.last.tap do |last|
        name, parameter = last.split /\[|\]/
        last.replace name
      end

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant = constant[constantize(parameter)] if parameter
      constant
    end
  end

  class ParametrizedType < Module
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
      raise 'Atom canot be parametrized' unless variables.empty?
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

  module Matchers

    class Abstract
      include TypeCheck
      attr_reader :value

      def initialize
        @assign, @value, @matched = nil
      end

      def case(&block)
        return self, block
      end

      alias_method :when, :case

      def >(block)
        return self, block
      end

      alias_method :>>, :>

      def ~
        @assign = true
        self
      end

      def &(matcher)
        And.new self, matcher
      end

      def |(matcher)
        Or.new self, matcher
      end

      def !
        Not.new self
      end

      def assign?
        @assign
      end

      def matched?
        @matched
      end

      def children_including_self
        children.unshift self
      end

      def assigns
        collect_assigns.tap do
          return yield *assigns if block_given?
        end
      end

      def to_a
        assigns
      end

      def ===(other)
        matching?(other).tap { |matched| @value = other if (@matched = matched) }
      end

      def assign_to_s
        assign? ? '~' : ''
      end

      def inspect
        to_s
      end

      def children
        raise NotImplementedError
      end

      def to_s
        raise NotImplementedError
      end

      def ==(other)
        raise NotImplementedError
      end

      protected

      def matching?(other)
        raise NotImplementedError
      end

      private

      def collect_assigns
        mine = @assign ? [@value] : []
        children.inject(mine) { |assigns, child| assigns + child.assigns }
      end

      def matchable!(obj)
        raise ArgumentError, 'object does not respond to :===' unless obj.respond_to? :===
        obj
      end

      def find_children(collection)
        collection.map do |matcher|
          matcher if matcher.kind_of? Abstract
        end.compact
      end
    end

    class AbstractLogic < Abstract
      def self.call(*matchers)
        new *matchers
      end

      attr_reader :matchers

      def initialize(*matchers)
        @matchers = matchers.each { |m| matchable! m }
      end

      def children
        find_children matchers
      end

      def ==(other)
        other.kind_of? self.class and
            self.matchers == other.matchers
      end
    end

    class And < AbstractLogic
      def to_s
        matchers.join ' & '
      end

      protected

      def matching?(other)
        matchers.all? { |m| m === other }
      end
    end

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

    class Not < Abstract
      attr_reader :matcher

      def initialize(matcher)
        @matcher = matcher
      end

      def children
        []
      end

      def to_s
        '!' + matcher.to_s
      end

      def ==(other)
        other.kind_of? self.class and
            self.matcher == other.matcher
      end

      protected

      def matching?(other)
        not matcher === other
      end
    end

    class Any < Abstract
      def children
        []
      end

      def to_s
        assign_to_s + 'any'
      end

      def ==(other)
        other.kind_of? self.class
      end

      protected

      def matching?(other)
        true
      end
    end

    class Wrapper < Abstract
      def self.call(something)
        new something
      end

      attr_reader :something

      def initialize(something)
        super()
        @something = matchable! something
      end

      def children
        find_children [@something]
      end

      def to_s
        assign_to_s + "Wrapper.(#{@something})"
      end

      def ==(other)
        other.kind_of? self.class and
            self.something == other.something
      end

      protected

      def matching?(other)
        @something === other
      end
    end

    class ::Object
      def to_m
        Wrapper.new(self)
      end
    end

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

      # TODO prety_print for all matchers

      def ==(other)
        other.kind_of? self.class and
            self.algebraic_type == other.algebraic_type and
            self.field_matchers == other.field_matchers
      end

      protected

      def matching?(other)
        other.kind_of?(@algebraic_type) and other.kind_of?(ProductConstructor) and
            @field_matchers.zip(other.fields).all? do |matcher, field|
              matcher === field
            end
      end
    end

    class Variant < Wrapper
      def initialize(something)
        raise ArgumentError unless something.variants
        Type! something, Algebrick::ProductVariant
        super something
      end

      def to_s
        assign_to_s + "#{@something.name}.to_m"
      end
    end

    class Atom < Wrapper
      def initialize(something)
        Type! something, Algebrick::Atom
        super something
      end

      def to_s
        assign_to_s + "#{@something.name}.to_m"
      end
    end
  end

  module Types
    Maybe = Algebrick.type(:v) do
      variants None = atom,
               Some = type(:v) { fields :v }
    end

    module Maybe
      def maybe
        match self,
              None >> nil,
              Some >-> { yield value }
      end
    end
  end

  include Types

end
