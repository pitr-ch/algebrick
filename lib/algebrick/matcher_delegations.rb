module Algebrick
  module MatcherDelegations
    def ~
      ~to_m
    end

    def &(other)
      to_m & other
    end

    def |(other)
      to_m | other
    end

    def !
      !to_m
    end

    def case(&block)
      to_m.case &block
    end

    def >>(block)
      to_m >> block
    end

    def >(block)
      to_m > block
    end
  end
end
