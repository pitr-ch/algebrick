# Let's define some types
Maybe = Algebrick.type do
  variants None = atom,
           Some = type { fields Numeric }
end

# where the Maybe actually is:
Maybe.class
Maybe.class.superclass
Maybe.class.superclass.superclass
Maybe.class.superclass.superclass.superclass

# if there is a circular dependency you can define the dependent types inside the block like this:
Tree = Algebrick.type do |tree|
  variants Empty = type,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end
Empty
Leaf
Node
