module Algebrick
  #noinspection RubyConstantNamingConvention
  module Types
    Maybe = Algebrick.type(:v) do
      variants None = atom,
               Some = type(:v) { fields :v }
    end

    module Maybe
      def maybe
        match self,
              None >> nil,
              Some >-> { yield value }
      end
    end

    #List = Algebrick.type(:value_type) do |list|
    #  fields! value: :value_type, next: list
    #  variants EmptyList = atom, list
    #end
    #
    #module List
    #  def each(&block)
    #    it = self
    #    loop do
    #      break if EmptyList === it
    #      block.call it.value
    #      it = it.next
    #    end
    #  end
    #end
  end

  include Types
end
