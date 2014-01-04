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

    def to_hash
      { TYPE_KEY => name }
    end

    def from_hash(hash)
      if hash == to_hash
        self
      else
        raise ArgumentError
      end
    end
  end
end
