# Let's define some types
None  = Algebrick.type                             # => None
Some  = Algebrick.type { fields Object }           # => Some(Object)
Maybe = Algebrick.type { variants None, Some }     # => Maybe(None | Some)

# where the Maybe actually is:
Maybe.class                                        # => Algebrick::ProductVariant
Maybe.class.superclass                             # => Algebrick::Type
Maybe.class.superclass.superclass                  # => Module
Maybe.class.superclass.superclass.superclass       # => Object

# if there is a circular dependency you can define the dependent types inside the block like this:
Tree = Algebrick.type do |tree|
  Empty = type
  Leaf  = type { fields Integer }
  Node  = type { fields tree, tree }

  variants Empty, Leaf, Node
end                                                # => Tree(Empty | Leaf | Node)
Empty                                              # => Empty
Leaf                                               # => Leaf(Integer)
Node                                               # => Node(Tree, Tree)
