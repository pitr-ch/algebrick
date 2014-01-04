module Algebrick
  module Serializers
    class StrictToHash < Abstract
      attr_reader :type_key, :fields_key

      def initialize(type_key = :algebrick_type, fields_key = :algebrick_fields)
        @type_key   = type_key
        @fields_key = fields_key
      end

      def parse(data)
        case data
        when ::Hash
          type_name = data[type_key] || data[type_key.to_s]
          if type_name
            type = constantize(type_name)

            fields = data[fields_key] || data[fields_key.to_s] ||
                data.dup.tap { |h| h.delete type_key; h.delete type_key.to_s }
            Type! fields, Hash, Array

            if type.is_a? Atom
              type
            else
              case fields
              when Array
                type[*fields.map { |value| parse value }]
              when Hash
                type[fields.inject({}) do |h, (name, value)|
                  raise ArgumentError unless type.field_names.map(&:to_s).include? name.to_s
                  h.update name.to_sym => parse(value)
                end]
              end
            end
          else
            data
          end
        when Numeric, String, ::Array, Symbol, TrueClass, FalseClass, NilClass
          data
        else
          parse_other(data)
        end
      end

      def generate(object)
        case object
        when Value
          { type_key => object.type.name }.
              update(case object
                     when Atom
                       {}
                     when ProductConstructors::Basic
                       { fields_key => object.fields.map { |v| generate v } }
                     when ProductConstructors::Named
                       object.type.field_names.inject({}) { |h, name| h.update name => generate(object[name]) }
                     else
                       raise
                     end)
        when Numeric, String, ::Array, ::Hash, Symbol, TrueClass, FalseClass, NilClass
          object
        else
          generate_other(object)
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
          constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
        constant = constant[constantize(parameter)] if parameter
        constant
      end

      private

      def parse_other(other)
        other
      end

      def generate_other(object)
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
