module Algebrick
  module Serializers
    require 'multi_json'

    class ToJson < Abstract
      def parse(data, options = {})
        MultiJson.load data
      end

      def generate(object, options = {})
        MultiJson.dump object
      end
    end
  end
end
