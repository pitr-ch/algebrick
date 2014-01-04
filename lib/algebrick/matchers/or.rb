module Algebrick
  module Matchers
    #noinspection RubyClassModuleNamingConvention
    class Or < AbstractLogic
      def to_s
        matchers.join ' | '
      end

      protected

      def matching?(other)
        matchers.any? { |m| m === other }
      end

      alias_method :super_children, :children
      private :super_children

      def children
        super.select &:matched?
      end

      private

      def collect_assigns
        super.tap do |assigns|
          missing = assigns_size - assigns.size
          assigns.push(*::Array.new(missing))
        end
      end

      def assigns_size
        # TODO is it efficient?
        super_children.map { |ch| ch.assigns.size }.max
      end
    end
  end
end
