# Let's define some types
Maybe = Algebrick.type do
  variants None = atom,
           Some = type { fields Numeric }
end                                                # => Maybe(None | Some)

# where the Maybe actually is:
Maybe.class                                        # => Algebrick::ProductVariant
Maybe.class.superclass                             # => Algebrick::Type
Maybe.class.superclass.superclass                  # => Module
Maybe.class.superclass.superclass.superclass       # => Object

# if there is a circular dependency you can define the dependent types inside the block like this:
Tree = Algebrick.type do |tree|
  variants Empty = type,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end                                                # => Tree(Empty | Leaf | Node)
Empty                                              # => Empty
Leaf                                               # => Leaf(Integer)
Node                                               # => Node(Tree, Tree)
