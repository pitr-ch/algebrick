module Algebrick
  module Serializers
    class Abstract
      include TypeCheck

      def parse(data, options = {})
        raise NotImplementedError
      end

      def generate(object, options = {})
        raise NotImplementedError
      end
    end
  end
end
