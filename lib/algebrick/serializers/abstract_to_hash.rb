module Algebrick
  module Serializers
    class AbstractToHash < Abstract
      attr_reader :type_key, :fields_key

      def initialize(type_key = :algebrick_type, fields_key = :algebrick_fields)
        @type_key   = type_key
        @fields_key = fields_key
      end
    end
  end
end
