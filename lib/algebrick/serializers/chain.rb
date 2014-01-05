module Algebrick
  module Serializers
    class Chain < Abstract
      attr_reader :serializer, :chain_to

      def initialize(serializer, chain_to)
        @serializer = Type! serializer, Abstract
        @chain_to   = Type! chain_to, Abstract
      end

      def parse(data, options = {})
        serializer.parse chain_to.parse(data, options), options
      end

      def generate(object, options = {})
        chain_to.generate serializer.generate(object, options), options
      end
    end
  end
end
