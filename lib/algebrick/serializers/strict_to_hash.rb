module Algebrick
  module Serializers
    class StrictToHash < AbstractToHash
      def parse(data, options = {})
        case data
        when ::Hash
          parse_value(data, options)
        when Numeric, String, ::Array, Symbol, TrueClass, FalseClass, NilClass
          data
        else
          parse_other(data, options)
        end
      end

      def generate(object, options = {})
        case object
        when Value
          generate_value object, options
        when Numeric, String, ::Array, ::Hash, Symbol, TrueClass, FalseClass, NilClass
          object
        else
          generate_other(object, options)
        end
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
          constant = if constant.const_defined?(name)
                       constant.const_get(name)
                     else
                       constant.const_missing(name)
                     end
        end
        constant = constant[constantize(parameter)] if parameter
        constant
      end

      private

      def parse_value(value, options)
        type_name = value[type_key] || value[type_key.to_s]
        if type_name
          type = constantize(type_name)

          fields = value[fields_key] || value[fields_key.to_s] ||
              value.dup.tap { |h| h.delete type_key; h.delete type_key.to_s }
          Type! fields, Hash, Array

          if type.is_a? Atom
            type
          else
            case fields
            when Array
              type[*fields.map { |value| parse value, options }]
            when Hash
              type[fields.inject({}) do |h, (name, value)|
                raise ArgumentError unless type.field_names.map(&:to_s).include? name.to_s
                h.update name.to_sym => parse(value, options)
              end]
            end
          end
        else
          value
        end
      end

      def generate_value(value, options)
        { type_key => value.type.name }.
            update(case value
                   when Atom
                     {}
                   when ProductConstructors::Basic
                     { fields_key => value.fields.map { |v| generate v, options } }
                   when ProductConstructors::Named
                     value.type.field_names.inject({}) do |h, name|
                       h.update name => generate(value[name], options)
                     end
                   else
                     raise
                   end)
      end

      def parse_other(other, options = {})
        other
      end

      def generate_other(object, options = {})
        case
        when object.respond_to?(:to_h)
          object.to_h
        when object.respond_to?(:to_hash)
          object.to_hash
        else
          raise "do not know how to convert (#{object.class}) #{object}"
        end
      end
    end
  end
end
