module Algebrick
  module Matchers
    class Atom < Wrapper
      def initialize(something)
        Type! something, Algebrick::Atom
        super something
      end

      def to_s
        assign_to_s + "#{@something.name}.to_m"
      end
    end
  end
end
