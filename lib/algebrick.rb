# TODO method definition in variant type defines methods on variants based on match

class Module
  # Return any modules we +extend+
  def extended_modules
    class << self
      self
    end.included_modules
  end
end

module Algebrick

  module TypeCheck
    #def is_kind_of?(value, *types)
    #  a_type_check :kind_of?, false, value, *types
    #end



    def is_kind_of!(value, *types)
      types.any? { |t| value.kind_of? t } or
          raise TypeError, "value (#{value.class}) '#{value}' is not any kind of #{types.inspect}"
      value
    end

    #def is_matching?(value, *types)
    #  a_type_check :===, false, value, *types
    #end

    #def is_matching!(value, *types)
    #  a_type_check :===, true, value, *types
    #end

    #private
    #
    #def a_type_check(which, bang, value, *types)
    #  ok = types.any? do |t|
    #    case which
    #    when :===
    #      t === value
    #    when :kind_of?
    #      value.kind_of? t
    #    else
    #      raise ArgumentError
    #    end
    #  end
    #  raise TypeError, "value (#{value.class}) '#{value}' is not #{which} of #{types.inspect}" if bang && !ok
    #  value
    #end
  end

  module Matching
    def any
      Matchers::Any.new
    end

    alias_method :_, :any # TODO make it optional

    #match Empty,
    #      Node + lambda {},
    #      Empty / ->() {},
    #      Leaf.(~any) >> ->(value) do
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
      raise "no match for #{value} by any of #{cases.map(&:first).join ', '}"
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

    def !
      !to_m
    end
  end

  class Type < Module
    include TypeCheck
    include Matching
    include MatcherDelegations

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

    def as_json
      raise NotImplementedError # TODO
    end
  end

  class Atom < Type
    include Value

    def initialize(&block)
      super &block
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
            type.field_names.map { |name| "#{name}: #{self[name]}" }.join(', ')
          else
            fields.join(',')
          end + ']'
    end

    def to_a
      @fields
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
  end

  class AbstractProductVariant < Type
    def be_kind_of(type = nil)
      if initialized?
        be_kind_of! type if type
        if @to_be_kind_of
          while (type = @to_be_kind_of.shift)
            be_kind_of! type
          end
        end
      else
        @to_be_kind_of ||= []
        @to_be_kind_of << type if type
      end
      self
    end

    protected

    def be_kind_of!(type)
      raise NotImplementedError
    end

    private

    def initialized?
      !!@initialized
    end

    def initialize(&block)
      super &block
      @initialized = true
      be_kind_of
    end

    def set_fields(fields_or_hash)
      fields = if fields_or_hash.size == 1 && fields_or_hash.first.is_a?(Hash)
                 keys = fields_or_hash.first.keys
                 fields_or_hash.first.values
               else
                 fields_or_hash
               end

      if keys
        @field_names = keys
        keys.all? { |k| is_kind_of! k, Symbol }
        dict = keys.each_with_index.inject({}) { |h, (k, i)| h.update k => i }
        define_method(:[]) { |key| @fields[dict[key]] }
      end

      fields.all? { |f| is_kind_of! f, Type, Class }
      raise TypeError, 'there is no product with zero fields' unless fields.size > 0
      define_method(:value) { @fields.first } if fields.size == 1
      @fields      = fields
      @constructor = Class.new(ProductConstructor).tap { |c| c.type = self }
    end

    def set_variants(variants)
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

    def product_be_kind_of(type)
      @constructor.send :include, type
    end

    def construct_product(*fields)
      @constructor.new *fields
    end

    def product_to_s
      fields_str = if field_names
                     field_names.zip(fields).map { |name, field| "#{name}: #{field.name}" }
                   else
                     fields.map(&:name)
                   end
      "#{name}(#{fields_str.join ', '})"
    end

  end

  class Product < AbstractProductVariant
    attr_reader :fields, :field_names

    def initialize(*fields, &block)
      set_fields fields
      super(&block)
    end

    def [](*fields)
      construct_product(*fields)
    end

    def be_kind_of!(type)
      product_be_kind_of type
    end

    def call(*field_matchers)
      Matchers::Product.new self, *field_matchers
    end

    def to_m
      call *::Array.new(fields.size) { Algebrick.any }
    end

    def ==(other)
      other.kind_of? Product and fields == other.fields
    end

    def to_s
      product_to_s
    end
  end

  class Variant < AbstractProductVariant
    attr_reader :variants

    def initialize(*variants, &block)
      set_variants(variants)
      super &block
    end

    def be_kind_of!(type)
      variants.each { |v| v.be_kind_of type }
    end

    def to_m
      Matchers::Variant.new self
    end

    def ==(other)
      other.kind_of? Variant and variants == other.variants
    end

    def to_s
      "#{name}(#{variants.map(&:name).join ' | '})"
    end
  end

  class ProductVariant < AbstractProductVariant
    attr_reader :fields, :field_names, :variants

    def initialize(fields, variants, &block)
      set_fields fields
      raise unless variants.include? self
      set_variants variants
      super &block
    end

    def be_kind_of!(type)
      variants.each { |v| v.be_kind_of type unless v == self }
      product_be_kind_of type
    end

    def call(*field_matchers)
      Matchers::Product.new self, *field_matchers
    end

    def to_m
      Matchers::Variant.new self
    end

    def [](*fields)
      construct_product(*fields)
    end

    def ==(other)
      other.kind_of? ProductVariant and
          variants == other.variants and fields == other.fields
    end

    def to_s
      name + '(' +
          variants.map do |variant|
            if variant == self
              product_to_s
            else
              variant.name
            end
          end.join(' | ') +
          ')'
    end
  end

  module Matchers

    class Abstract
      include TypeCheck
      attr_reader :value

      def initialize
        @assign, @value = nil
      end

      def case(&block)
        return self, block
      end

      def +(block)
        return self, block
      end

      alias_method :-, :+
      alias_method :>>, :+

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

      def children_including_self
        children.unshift self
      end

      def assigns
        mine = @assign && @value ? [@value] : []
        mine = @assign ? [@value] : []
        children.inject(mine) { |assigns, child| assigns + child.assigns }.tap do
          return yield *assigns if block_given?
        end
      end

      def ===(other)
        matching?(other).tap { |matched| @value = other if matched }
      end

      def assign_to_s
        assign? ? '~' : ''
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

    class Not < Abstract # TODO
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
      attr_reader :algebraic_type, :field_matchers

      def initialize(algebraic_type, *field_matchers)
        super()
        is_kind_of! algebraic_type, Algebrick::Product, Algebrick::ProductVariant
        @algebraic_type = algebraic_type
        field_matchers += ::Array.new(algebraic_type.fields.size) { Algebrick.any } if field_matchers.empty?
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
        is_kind_of! something, Algebrick::Variant, Algebrick::ProductVariant
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

  module DSL
    class PreType
      attr_reader :environment, :name, :fields, :variants, :definition

      def initialize(environment, name)
        @environment = environment
        @name        = name
        @fields      = []
        @variants    = nil
        @definition  = nil
      end

      def |(other)
        [self, other]
      end

      def to_ary
        [self]
      end

      def fields=(fields)
        raise unless @fields.empty?
        @fields += fields
      end

      def definition=(block)
        raise if @definition
        @definition = block
      end

      def is(variants)
        raise if @variants
        @variants = variants
        self
      end

      alias_method :===, :is

      def kind
        if @variants
          if @fields.empty?
            Variant
          else
            ProductVariant
          end
        else
          if @fields.empty?
            Atom
          else
            Product
          end
        end
      end
    end

    class Environment
      attr_reader :pre_types
      def initialize(base, &definition)
        @base      = if base.is_a?(Object) && base.to_s == 'main'
                       Object
                     else
                       base
                     end
        @pre_types = {}
        instance_eval &definition
      end

      def method_missing(method, *fields, &definition)
        const_name = method.to_s.split('_').map { |s| s[0] = s[0].upcase; s }.join

        @pre_types[const_name] ||= PreType.new(self, const_name)
        @pre_types[const_name].fields = fields unless fields.empty?
        @pre_types[const_name].definition = definition if definition
        @pre_types[const_name]
      end

      def run
        define_constants
        define_fields_and_variants
        eval_definitions
        @pre_types.map { |name, _| get_class name }
      end

      private

      def define_constants
        @pre_types.each do |name, pre_type|
          type = pre_type.kind.allocate
          if @base.const_defined? name
            defined = @base.const_get(name)
            #  #unless defined == type
            raise "#{name} already defined as #{defined}"
            #  #end
          else
            #puts "defining #{name.to_sym.inspect} in #{@base}"
            @base.const_set name.to_sym, type
          end
        end
      end

      def define_fields_and_variants
        select = ->(klass, &block) do
          @pre_types.select { |_, pre_type| pre_type.kind == klass }.
              map { |name, pre_type| [name, get_class(name), pre_type] }.
              each &block
        end

        select.(Atom) do |name, type, pre_type|
          type.send :initialize
        end

        select.(Product) do |name, type, pre_type|
          type.send :initialize, *pre_type.fields.map { |f| get_class f }
        end

        select.(Variant) do |name, type, pre_type|
          type.send :initialize, *pre_type.variants.map { |v| get_class v }
        end

        select.(ProductVariant) do |name, type, pre_type|
          type.send :initialize,
                    pre_type.fields.map { |f| get_class f },
                    pre_type.variants.map { |v| get_class v }
        end
      end

      def eval_definitions
        @pre_types.each do |name, pre_type|
          next unless pre_type.definition
          type = get_class name
          type.module_eval &pre_type.definition
        end
      end

      def get_class(key)
        if key.kind_of? String
          @base.const_get key
        elsif key.kind_of? PreType
          @base.const_get key.name
        elsif key.kind_of? Hash
          key.each { |k, v| key[k] = get_class v }
        else
          key
        end
      end
    end

    def type_def(&definition)
      Environment.new(self, &definition).run
    end
  end
end
