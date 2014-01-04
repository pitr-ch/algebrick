module Algebrick
  module Serializers
    class Abstract
      include TypeCheck

      def parse(data)
        raise NotImplementedError
      end

      def generate(object)
        raise NotImplementedError
      end
    end
  end
end
