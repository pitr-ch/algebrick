module Algebrick
  # Representation of Product and Variant types. The class behaves differently
  # based on #kind.
  #noinspection RubyTooManyMethodsInspection
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

    def field(name)
      fields[field_indexes[name]]
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
      #noinspection RubyCaseWithoutElseBlockInspection
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
          Hash.new { |_, k| raise ArgumentError, "unknown field #{k.inspect} in #{self}" }.
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

    def field_from_hash(hash, expected_type = nil)
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
end
