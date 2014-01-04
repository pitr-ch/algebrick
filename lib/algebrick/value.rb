module Algebrick
  # Any value of Algebraic type is kind of Value
  module Value
    include TypeCheck
    include Matching

    def ==(other)
      raise NotImplementedError
    end

    def type
      raise NotImplementedError
    end

    def to_s
      raise NotImplementedError
    end

    def pretty_print(q)
      raise NotImplementedError
    end

    def inspect
      to_s
    end
  end
end
