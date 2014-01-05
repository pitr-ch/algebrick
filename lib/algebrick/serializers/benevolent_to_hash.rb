module Algebrick
  module Serializers
    class BenevolentToHash < AbstractToHash
      def generate(object, options = {})
        object
      end

      def parse(object, options = {})
        expected_type = Type! options[:expected_type], Module
        could? { can_be? expected_type, object }.tap do |v|
          raise "type mismatch #{object} is not #{expected_type} " unless can? v
        end
      end

      private

      CANNOT = Algebrick.atom

      def can_be?(type, object)
        Type! type, Module

        could? do
          cannot! unless object.is_a?(::Hash)
          cannot! unless object[type_key] || object[type_key.to_s]
          return object
        end

        could? { return can_be_atom? type, object }
        could? { return can_be_product_variant? type, object }

        return object if object.is_a?(type)

        cannot!
      end

      def many_can_by?(hash)
        hash.map do |type, value|
          can_be? type, value
        end
      end

      def can_be_product_variant?(type, object)
        Type! type, Module
        cannot! unless type.is_a? ProductVariant

        if type.variants
          self_variant   = type.variants.find { |v| v == type }
          other_variants = type.variants - [self_variant]
          possibilities  = [
              *other_variants.map { |v| could? { can_be? v, object } },
              could? do
                cannot! unless self_variant
                can_be_atom? self_variant, object
              end,
              could? do
                cannot! unless self_variant
                can_be_product? self_variant, object
              end
          ].select { |v| can? v }

          cannot! if possibilities.empty?
          raise "multiple options #{possibilities}" if possibilities.size > 1
          possibilities.first
        else
          can_be_product? type, object
        end
      end

      def can_be_atom?(type, object)
        Type! type, Module
        cannot! unless type.is_a?(Atom)
        cannot! unless object.is_a?(String) || object.is_a?(Symbol)

        last_name = type.name.split('::').last
        possible_representations = [type.name, last_name.downcase, underscore(last_name)]
        cannot! unless possible_representations.any? { |v| v == object.to_s }

        return type_key => type.name
      end

      def can_be_product?(type, object)
        Type! type, Module
        could? do
          cannot! unless object.is_a?(::Array) && !type.field_names?
          cannot! unless type.fields.size == object.size

          fields = many_can_by? type.fields.zip(object)
          return { type_key => type.name, fields_key => fields }
        end

        could? do
          cannot! unless object.is_a?(::Hash) && type.field_names?

          candidates = type.field_names.map do |field_name|
            v1 = object.fetch(field_name, CANNOT)
            v2 = object.fetch(field_name.to_s, CANNOT)
            (v = [v1, v2].find { |v| v != CANNOT }) or cannot!
          end

          values = many_can_by? type.fields.zip(candidates)

          fields = type.field_names.zip(values).
              each_with_object({}) { |(name, value), fields| fields[name] = value }

          return { type_key => type.name }.update(fields)
        end

        cannot!
      end

      def could?
        catch CANNOT do
          yield
        end
      end

      def can?(v)
        v != CANNOT
      end

      def cannot!
        throw CANNOT, CANNOT
      end

      def underscore(string)
        string[0].downcase + string[1..-1].gsub(/([A-Z])/) { |m| '_' + m.downcase }
      end
    end
  end
end
