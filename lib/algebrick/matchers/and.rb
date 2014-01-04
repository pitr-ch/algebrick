module Algebrick
  module Matchers
    class And < AbstractLogic
      def to_s
        matchers.join ' & '
      end

      protected

      def matching?(other)
        matchers.all? { |m| m === other }
      end
    end
  end
end
