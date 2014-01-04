module Algebrick
  module Serializers
    class Chain < Abstract
      attr_reader :serializer, :chain_to

      def initialize(serializer, chain_to)
        @serializer = Type! serializer, Abstract
        @chain_to   = Type! chain_to, Abstract
      end

      def parse(data)
        serializer.parse chain_to.parse(data)
      end

      def generate(object)
        chain_to.generate serializer.generate(object)
      end
    end
  end
end
