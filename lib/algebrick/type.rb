module Algebrick
  # Any Algebraic type defined by Algebrick is kind of Type
  class Type < Module
    include TypeCheck
    include Matching
    include MatcherDelegations
    include Reclude

    def initialize(name, &definition)
      super &definition
      @name = name
    end

    def name
      super || @name || raise('missing name')
    end

    def to_m(*args)
      raise NotImplementedError
    end

    def ==(other)
      raise NotImplementedError
    end

    def be_kind_of(type)
      raise NotImplementedError
    end

    def to_s
      raise NotImplementedError
    end

    def inspect
      to_s
    end
  end
end
