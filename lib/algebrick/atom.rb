module Algebrick
  # Representation of Atomic types
  class Atom < Type
    include Value

    def initialize(name, &block)
      super name, &block
      extend self
    end

    def to_m
      Matchers::Atom.new self
    end

    def be_kind_of(type)
      extend type
    end

    def ==(other)
      self.equal? other
    end

    def type
      self
    end

    def to_s
      name
    end

    def pretty_print(q)
      q.text to_s
    end
  end
end
