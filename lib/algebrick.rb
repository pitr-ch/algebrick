#  Copyright 2013 Petr Chalupa <git@pitr.ch>
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
# TODO type variables/constructor maybe(a) === none | a

require 'set'

#class Module
#  # Return any modules we +extend+
#  def extended_modules
#    class << self
#      self
#    end.included_modules
#  end
#end

module Algebrick

  def self.version
    @version ||= Gem::Version.new File.read(File.join(File.dirname(__FILE__), '..', 'VERSION'))
  end

  module TypeCheck
    def is_kind_of?(value, *types)
      a_type_check :kind_of?, false, value, *types
    end

    def is_kind_of!(value, *types)
      a_type_check :kind_of?, true, value, *types
    end

    def is_matching?(value, *types)
      a_type_check :===, false, value, *types
    end

    def is_matching!(value, *types)
      a_type_check :===, true, value, *types
    end

    private

    def a_type_check(which, bang, value, *types)
      ok = types.any? do |t|
        case which
        when :===
          t === value
        when :kind_of?
          value.kind_of? t
        else
          raise ArgumentError
        end
      end
      bang && !ok and
          raise TypeError,
                "value (#{value.class}) '#{value}' is not ##{which} any of #{types.join(', ')}"
      bang ? value : ok
    end
  end

  module Matching
    def any
      Matchers::Any.new
    end

    alias_method :_, :any # TODO make it optional

    #match Empty,
    #      Empty >> static_value_like_string,
    #      Leaf.(~any) >-> value do
    #        value
    #      end
    #match Empty,
    #      Node        => ->() {},
    #      Empty       => ->() {},
    #      Leaf.(~any) => ->(value) { value }
    #match Empty,
    #      [Node, lambda {}],
    #      [Empty, lambda {}],
    #      [Leaf.(~any), lambda { |value| value }]
    #match(Empty,
    #      Node.case {},
    #      Empty.case {},
    #      Leaf.(~any).case { |value| value })

    def match(value, *cases)
      cases = if cases.size == 1 && cases.first.is_a?(Hash)
                cases.first
              else
                cases
              end

      cases.each do |matcher, block|
        return match_value matcher, block if matcher === value
      end
      raise "no match for (#{value.class}) '#{value}' by any of #{cases.map(&:first).join ', '}"
    end

    private

    def match_value(matcher, block)
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

    def ^(other)
      to_m ^ other
    end

    def !
      !to_m
    end

    def -(block)
      to_m - block
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

  class Type < Module
    include TypeCheck
    include Matching
    include MatcherDelegations

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

  class ProductConstructor
    include Value
    attr_reader :fields

    def initialize(*fields)
      if fields.size == 1 && fields.first.is_a?(Hash)
        fields = type.field_names.map { |k| fields.first[k] }
      end
      @fields = fields.zip(self.class.type.fields).map do |field, type|
        is_kind_of! field, type
      end.freeze
    end

    def to_s
      "#{self.class.type.name}[" +
          if type.field_names
            type.field_names.map { |name| "#{name}: #{self[name].to_s}" }.join(', ')
          else
            fields.map(&:to_s).join(',')
          end + ']'
    end

    def to_ary
      @fields
    end

    def to_a
      @fields
    end

    def to_hash
      { TYPE_KEY => self.class.type.name }.
          update(if type.field_names
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

  class ProductVariant < Type
    attr_reader :fields, :field_names, :field_indexes, :variants

    def set_fields(fields_or_hash)
      raise TypeError, 'can be set only once' if @fields
      fields, keys = if fields_or_hash.size == 1 && fields_or_hash.first.is_a?(Hash)
                       [fields_or_hash.first.values, fields_or_hash.first.keys]
                     else
                       [fields_or_hash, nil]
                     end

      set_field_names keys if keys

      fields.all? { |f| is_kind_of! f, Type, Class }
      raise TypeError, 'there is no product with zero fields' unless fields.size > 0
      define_method(:value) { @fields.first } if fields.size == 1
      @fields      = fields
      @constructor = Class.new(ProductConstructor).tap { |c| c.type = self }
    end

    def add_field_method_reader(field)
      raise TypeError, 'no field names' unless @field_names
      raise ArgumentError, "no field name #{field}" unless @field_names.include? field
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

    raise 'remove deprecation' if Algebrick.version >= Gem::Version.new('0.3')

    def add_all_field_method_accessors
      warn "add_all_field_method_accessors is deprecated, it'll be removed in 0.3\n#{caller[0]}"
      add_all_field_method_readers
    end

    def add_field_method_accessors(*fields)
      warn "add_all_field_method_accessors is deprecated, it'll be removed in 0.3\n#{caller[0]}"
      add_field_method_readers *fields
    end

    def add_field_method_accessor(field)
      warn "add_all_field_method_accessors is deprecated, it'll be removed in 0.3\n#{caller[0]}"
      add_field_method_reader field
    end

    def set_variants(variants)
      raise TypeError, 'can be set only once' if @variants
      variants.all? { |v| is_kind_of! v, Type, Class }
      @variants = variants
      variants.each do |v|
        if v.respond_to? :be_kind_of
          v.be_kind_of self
        else
          v.send :include, self
        end
      end
    end

    def new(*fields)
      raise TypeError unless @constructor
      @constructor.new *fields
    end

    alias_method :[], :new

    def ==(other)
      other.kind_of? ProductVariant and
          variants == other.variants and fields == other.fields
    end

    def be_kind_of(type)
      kind
      @constructor.send :include, type if @constructor
      variants.each { |v| v.be_kind_of type unless v == self } if @variants
    end

    def call(*field_matchers)
      raise TypeError unless @fields
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

    private

    def product_to_s
      fields_str = if field_names
                     field_names.zip(fields).map { |name, field| "#{name}: #{field.name}" }
                   else
                     fields.map(&:name)
                   end
      "#{name}(#{fields_str.join ', '})"
    end

    def set_field_names(names)
      @field_names = names
      names.all? { |k| is_kind_of! k, Symbol }
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
      is_kind_of! fields, Hash, Array

      case fields
      when Array
        self[*fields.map { |value| field_from_hash value }]
      when Hash
        self[fields.inject({}) do |h, (name, value)|
          raise ArgumentError unless @field_names.map(&:to_s).include? name.to_s
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

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
  end

  class TypeDefinitionScope
    attr_reader :new_type

    def initialize(&block)
      @new_type = ProductVariant.new nil
      instance_exec @new_type, &block
      @new_type.kind
    end

    def fields(*fields)
      @new_type.set_fields fields
      self
    end

    def variants(*variants)
      @new_type.set_variants variants
      self
    end

    def type(&block)
      Algebrick.type &block
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

  def self.type(&block)
    if block.nil?
      Atom.new nil
    else
      TypeDefinitionScope.new(&block).new_type
    end
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

      raise 'remove deprecation' if Algebrick.version >= Gem::Version.new('0.3')

      def -(block)
        warn "a 'matcher --> {}' and 'matcher +-> {}' is deprecated, it'll be removed in 0.3\n#{caller[0]}"
        self > block
      end

      def >(block)
        return self, block
      end

      alias_method :>>, :>
      alias_method :+, :-

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

      def ^(matcher)
        Xor.new self, matcher
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
        mine = @assign ? [@value] : []
        children.inject(mine) { |assigns, child| assigns + child.assigns }.tap do
          return yield *assigns if block_given?
        end
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
    end

    class Xor < Or
      def to_s
        matchers.join ' ^ '
      end

      alias_method :super_children, :children
      private :super_children

      def children
        super.select &:matched?
      end

      def assigns
        super.tap do |assigns|
          missing = assigns_size - assigns.size
          assigns.push(*::Array.new(missing))
        end
      end

      private

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

    # TODO Hash matcher
    # TODO Method matcher (:size, matcher)

    class Product < Abstract
      # TODO allow to match by field_name e.g. Address.(:street)
      attr_reader :algebraic_type, :field_matchers

      def initialize(algebraic_type, *field_matchers)
        super()
        @algebraic_type = is_kind_of! algebraic_type, Algebrick::ProductVariant
        raise ArgumentError unless algebraic_type.fields
        field_matchers  += ::Array.new(algebraic_type.fields.size) { Algebrick.any } if field_matchers.empty?
        @field_matchers = field_matchers
        raise ArgumentError unless algebraic_type.fields.size == field_matchers.size
      end

      def children
        find_children @field_matchers
      end

      def to_s
        assign_to_s + "#{@algebraic_type.name}.(#{@field_matchers.join(',')})"
      end

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
        is_kind_of! something, Algebrick::ProductVariant
        super something
      end

      def to_s
        assign_to_s + "#{@something.name}.to_m"
      end
    end

    class Atom < Wrapper
      def initialize(something)
        is_kind_of! something, Algebrick::Atom
        super something
      end

      def to_s
        assign_to_s + "#{@something.name}.to_m"
      end
    end
  end

  #class AbstractProductVariant < Type
  #  def be_kind_of(type = nil)
  #    if initialized?
  #      be_kind_of! type if type
  #      if @to_be_kind_of
  #        while (type = @to_be_kind_of.shift)
  #          be_kind_of! type
  #        end
  #      end
  #    else
  #      @to_be_kind_of ||= []
  #      @to_be_kind_of << type if type
  #    end
  #    self
  #  end
  #
  #  def add_field_method_accessor(field)
  #    raise TypeError, 'no field names' unless @field_names
  #    raise TypeError, "no field name #{field}" unless @field_names.include? field
  #    define_method(field) { self[field] }
  #    self
  #  end
  #
  #  def add_field_method_accessors(*fields)
  #    fields.each { |f| add_field_method_accessor f }
  #    self
  #  end
  #
  #  def add_all_field_method_accessors
  #    add_field_method_accessors *@field_names
  #  end
  #
  #  protected
  #
  #  def be_kind_of!(type)
  #    raise NotImplementedError
  #  end
  #
  #  private
  #
  #  def initialized?
  #    !!@initialized
  #  end
  #
  #  def initialize(name, &block)
  #    super name, &block
  #    @initialized = true
  #    be_kind_of
  #  end
  #
  #  def set_fields(fields_or_hash)
  #    fields, keys = if fields_or_hash.size == 1 && fields_or_hash.first.is_a?(Hash)
  #                     [fields_or_hash.first.values, fields_or_hash.first.keys]
  #                   else
  #                     [fields_or_hash, nil]
  #                   end
  #
  #    set_field_names keys if keys
  #
  #    fields.all? { |f| is_kind_of! f, Type, Class }
  #    raise TypeError, 'there is no product with zero fields' unless fields.size > 0
  #    define_method(:value) { @fields.first } if fields.size == 1
  #    @fields      = fields
  #    @constructor = Class.new(ProductConstructor).tap { |c| c.type = self }
  #  end
  #
  #  def set_field_names(names)
  #    @field_names = names
  #    names.all? { |k| is_kind_of! k, Symbol }
  #    dict = @field_indexes =
  #        Hash.new { |h, k| raise ArgumentError, "unknown field #{k.inspect} in #{self}" }.
  #            update names.each_with_index.inject({}) { |h, (k, i)| h.update k => i }
  #    define_method(:[]) { |key| @fields[dict[key]] }
  #  end
  #
  #  def set_variants(variants)
  #    variants.all? { |v| is_kind_of! v, Type, Class }
  #    @variants = variants
  #    variants.each do |v|
  #      if v.respond_to? :be_kind_of
  #        v.be_kind_of self
  #      else
  #        v.send :include, self
  #      end
  #    end
  #  end
  #
  #  def product_be_kind_of(type)
  #    @constructor.send :include, type
  #  end
  #
  #  def construct_product(*fields)
  #    @constructor.new *fields
  #  end
  #
  #  def product_to_s
  #    fields_str = if field_names
  #                   field_names.zip(fields).map { |name, field| "#{name}: #{field.name}" }
  #                 else
  #                   fields.map(&:name)
  #                 end
  #    "#{name}(#{fields_str.join ', '})"
  #  end
  #
  #  def product_from_hash(hash)
  #    (type_name = hash[TYPE_KEY] || hash[TYPE_KEY.to_s]) or
  #        raise ArgumentError, "hash does not have #{TYPE_KEY}"
  #    raise ArgumentError, "#{type_name} is not #{name}" unless type_name == name
  #
  #    fields = hash[FIELDS_KEY] || hash[FIELDS_KEY.to_s] ||
  #        hash.reject { |k, _| k.to_s == TYPE_KEY.to_s }
  #    is_kind_of! fields, Hash, Array
  #
  #    case fields
  #    when Array
  #      self[*fields.map { |value| field_from_hash value }]
  #    when Hash
  #      self[fields.inject({}) do |h, (name, value)|
  #        raise ArgumentError unless @field_names.map(&:to_s).include? name.to_s
  #        h.update name.to_sym => field_from_hash(value)
  #      end]
  #    end
  #  end
  #
  #  def field_from_hash(hash)
  #    return hash unless Hash === hash
  #    (type_name = hash[TYPE_KEY] || hash[TYPE_KEY.to_s]) or return hash
  #    type = constantize type_name
  #    type.from_hash hash
  #  end
  #
  #  def constantize(camel_cased_word)
  #    names = camel_cased_word.split('::')
  #    names.shift if names.empty? || names.first.empty?
  #
  #    constant = Object
  #    names.each do |name|
  #      constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
  #    end
  #    constant
  #  end
  #end
  #
  #class Product < AbstractProductVariant
  #  attr_reader :fields, :field_names, :field_indexes
  #
  #  def initialize(name, *fields, &block)
  #    set_fields fields
  #    super(name, &block)
  #  end
  #
  #  def new(*fields)
  #    construct_product(*fields)
  #  end
  #
  #  alias_method :[], :new
  #
  #  def be_kind_of!(type)
  #    product_be_kind_of type
  #  end
  #
  #  def call(*field_matchers)
  #    Matchers::Product.new self, *field_matchers
  #  end
  #
  #  def to_m
  #    call *::Array.new(fields.size) { Algebrick.any }
  #  end
  #
  #  def ==(other)
  #    other.kind_of? Product and fields == other.fields
  #  end
  #
  #  def to_s
  #    product_to_s
  #  end
  #
  #  def from_hash(hash)
  #    product_from_hash hash
  #  end
  #end
  #
  #class Variant < AbstractProductVariant
  #  attr_reader :variants
  #
  #  def initialize(name, *variants, &block)
  #    set_variants(variants)
  #    super name, &block
  #  end
  #
  #  def be_kind_of!(type)
  #    variants.each { |v| v.be_kind_of type }
  #  end
  #
  #  def to_m
  #    Matchers::Variant.new self
  #  end
  #
  #  def ==(other)
  #    other.kind_of? Variant and variants == other.variants
  #  end
  #
  #  def to_s
  #    "#{name}(#{variants.map(&:name).join ' | '})"
  #  end
  #
  #  def from_hash(hash)
  #    field_from_hash hash
  #  end
  #end
  #
  #class ProductVariant < AbstractProductVariant
  #  attr_reader :fields, :field_names, :field_indexes, :variants
  #
  #  def initialize(name, fields, variants, &block)
  #    set_fields fields
  #    raise unless variants.include? self
  #    set_variants variants
  #    super name, &block
  #  end
  #
  #  def be_kind_of!(type)
  #    variants.each { |v| v.be_kind_of type unless v == self }
  #    product_be_kind_of type
  #  end
  #
  #  def call(*field_matchers)
  #    Matchers::Product.new self, *field_matchers
  #  end
  #
  #  def to_m
  #    Matchers::Variant.new self
  #  end
  #
  #  def new(*fields)
  #    construct_product(*fields)
  #  end
  #
  #  alias_method :[], :new
  #
  #  def ==(other)
  #    other.kind_of? ProductVariant and
  #        variants == other.variants and fields == other.fields
  #  end
  #
  #  def to_s
  #    name + '(' +
  #        variants.map do |variant|
  #          if variant == self
  #            product_to_s
  #          else
  #            variant.name
  #          end
  #        end.join(' | ') +
  #        ')'
  #  end
  #
  #  def from_hash(hash)
  #    product_from_hash hash
  #  end
  #end

  #module DSL
  #  -> do
  #    maybe[:a] === none | some(:a)
  #    tree[:a] === tip | tree(:a, tree, tree)
  #  end
  #
  #  -> do
  #    maybe[:a].can_be none,
  #                     some.has(:a)
  #
  #    maybe[:a].can_be none,
  #                     some.having(:a)
  #
  #    maybe[:a].can_be none,
  #                     some.having(:a)
  #    tree.can_be tip,
  #                tree.having(Object, tree, tree)
  #
  #    tree.can_be empty,
  #                leaf.having(Object),
  #                node.having(left: tree, right: tree)
  #
  #    tree do
  #      # def ...
  #    end
  #  end
  #
  #  class PreType
  #    include TypeCheck
  #
  #    attr_reader :environment, :name, :fields, :variants, :definition, :variables
  #
  #    def initialize(environment, name)
  #      @environment = is_kind_of! environment, Environment
  #      @name        = is_kind_of! name, String
  #      @fields      = []
  #      @variables   = []
  #      @variants    = []
  #      @definition  = nil
  #    end
  #
  #    def const_name
  #      @const_name ||= name.to_s.split('_').map { |s| s.tap { s[0] = s[0].upcase } }.join
  #    end
  #
  #    #def |(other)
  #    #  [self, other]
  #    #end
  #    #
  #    #def to_ary
  #    #  [self]
  #    #end
  #
  #    def [](*variables)
  #      variables.all? { |var| is_kind_of! var, Symbol }
  #      @variables += variables
  #      self
  #    end
  #
  #    def fields=(fields)
  #      raise 'fields can be defined only once' unless @fields.empty?
  #      fields.each do |field|
  #        if Hash === field
  #          field.each do |k, v|
  #            is_kind_of! k, Symbol
  #            is_kind_of! v, PreType, Type, Class, Symbol
  #            @variables.push v if v.is_a? Symbol
  #          end
  #        else
  #          is_kind_of! field, PreType, Type, Class, Symbol
  #          @variables += fields.select { |v| v.is_a? Symbol }
  #        end
  #      end
  #      @fields += fields
  #    end
  #
  #    def having(fields)
  #      self.fields = fields
  #      self
  #    end
  #
  #    alias_method :has, :having
  #
  #    def fields_array
  #      if (hash = @fields.find { |f| Hash === f })
  #        hash.values
  #      else
  #        @fields
  #      end
  #    end
  #
  #    #def dependent(set = Set.new)
  #    #  children = @variants + @fields
  #    #  children.each do |a_type|
  #    #    next if set.include? a_type
  #    #    next unless a_type.respond_to? :dependent
  #    #    set.add a_type
  #    #    a_type.dependent set
  #    #  end
  #    #  set.to_a
  #    #end
  #
  #    def definition=(block)
  #      raise 'definition can be defined only once' if @definition
  #      @definition = block
  #    end
  #
  #    def can_be(*variants)
  #      raise 'variants can be defined only once' unless @variants.empty?
  #      @variants = variants
  #      self
  #    end
  #
  #    def no_variables?
  #      !variables? and fields_array.select { |f| Symbol === f }.empty?
  #    end
  #
  #    def variables?
  #      not @variables.empty?
  #    end
  #
  #    def kind
  #      unless @variants.empty?
  #        if @fields.empty?
  #          Variant
  #        else
  #          ProductVariant
  #        end
  #      else
  #        if @fields.empty?
  #          Atom
  #        else
  #          Product
  #        end
  #      end
  #    end
  #  end
  #
  #  class TypeConstructor
  #    include TypeCheck
  #    attr_reader :const_name
  #
  #    def initialize(pre_types, const_name, variables)
  #      warn "types with variables are experimental\n#{caller[0]}"
  #      @pre_types  = is_kind_of! pre_types, Hash
  #      @const_name = is_kind_of! const_name, String
  #      @variables  = is_kind_of! variables, Array
  #      @cache      = {}
  #    end
  #
  #    def [](*variables)
  #      variables.size == @variables.size or
  #          raise ArgumentError, "variables size differs from #{@variables}"
  #      @cache[variables] ||= begin
  #
  #        TypeFactory.new(@pre_types, Hash[@variables.zip(variables)]).define.tap do |types|
  #          types.each do |name, type|
  #
  #          end
  #        end
  #      end
  #    end
  #
  #    def to_s
  #      const_name + @variables.inspect
  #    end
  #
  #    def inspect
  #      to_s
  #    end
  #  end
  #
  #  class TypeFactory
  #    include TypeCheck
  #
  #    def initialize(pre_types, variable_mapping)
  #      @pre_types        = is_kind_of! pre_types, Hash
  #      @variable_mapping = is_kind_of! variable_mapping, Hash
  #      @types            = {}
  #    end
  #
  #    def define
  #      define_types
  #      define_fields_and_variants
  #      eval_definitions
  #
  #      @types
  #    end
  #
  #    private
  #
  #    def define_types
  #      @pre_types.each do |name, pre_type|
  #        @types[name] = pre_type.kind.allocate
  #      end
  #    end
  #
  #    def define_fields_and_variants
  #      select = ->(klass, &block) do
  #        @pre_types.select { |_, pre_type| pre_type.kind == klass }.each &block
  #      end
  #
  #      select.(Atom) do |name, pre_type|
  #        @types[name].send :initialize, type_name(pre_type)
  #      end
  #
  #      select.(Product) do |name, pre_type|
  #        @types[name].send :initialize, type_name(pre_type), *pre_type.fields.map { |f| get_class f }
  #      end
  #
  #      select.(Variant) do |name, pre_type|
  #        @types[name].send :initialize, type_name(pre_type), *pre_type.variants.map { |v| get_class v }
  #      end
  #
  #      select.(ProductVariant) do |name, pre_type|
  #        @types[name].send :initialize, type_name(pre_type),
  #                          pre_type.fields.map { |f| get_class f },
  #                          pre_type.variants.map { |v| get_class v }
  #      end
  #    end
  #
  #    def eval_definitions
  #      @pre_types.each do |name, pre_type|
  #        next unless pre_type.definition
  #        type = get_class name
  #        type.module_eval &pre_type.definition
  #      end
  #    end
  #
  #    def get_class(key)
  #      if key.kind_of? Symbol
  #        @variable_mapping[key] or raise "missing variable mapping for #{key}"
  #      elsif key.kind_of? String
  #        @types[key] or raise ArgumentError
  #      elsif key.kind_of? PreType
  #        @types[key.name]
  #      elsif key.kind_of? Hash
  #        key.each { |k, v| key[k] = get_class v }
  #      else
  #        key
  #      end
  #    end
  #
  #    def type_name(pre_type)
  #      pre_type.const_name + if pre_type.variables?
  #                              '[' + pre_type.variables.map { |v| @variable_mapping[v] } * ',' + ']'
  #                            else
  #                              ''
  #                            end
  #    end
  #  end
  #
  #  class Environment
  #    attr_reader :pre_types
  #    def initialize(&definition)
  #      @pre_types = {}
  #      @types     = {}
  #      instance_eval &definition
  #    end
  #
  #    def method_missing(method, *fields, &definition)
  #      name                        = method.to_s
  #      @pre_types[name]            ||= PreType.new(self, name)
  #      @pre_types[name].fields     = fields unless fields.empty?
  #      @pre_types[name].definition = definition if definition
  #      @pre_types[name]
  #    end
  #
  #    def run
  #      pre_types = @pre_types.select { |_, pt| pt.no_variables? }
  #      types     = TypeFactory.new(pre_types, {}).define
  #      constants = pre_types.inject({}) do |hash, (name, pre_type)|
  #        hash.update pre_type.const_name => types[name]
  #      end
  #
  #      pre_constructors = @pre_types.select { |_, pt| pt.variables? }
  #      constructors     = pre_constructors.inject({}) do |hash, (name, pt)|
  #        pre_types = Hash[([pt] + pt.dependent).map { |pt| [pt.name, pt] }]
  #        hash.update name => TypeConstructor.new(pre_types, pt.const_name, pt.variables)
  #      end
  #
  #      constants.update Hash[constructors.map { |name, c| [c.const_name, c] }]
  #
  #      @pre_types.map { |name, pre_type| types[name] || constructors[name] || raise("missing #{name}") }
  #    end
  #
  #    private
  #
  #    #def define_constants(map)
  #    #  map.each { |const_name, value| @base.const_set const_name.to_sym, value } if @base
  #    #end
  #  end
  #
  #  def type_def(&definition)
  #    Environment.new(&definition).run
  #  end
  #end

  #extend DSL
end
