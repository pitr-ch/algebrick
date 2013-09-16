# Let's define some types
None  = Algebrick.type
Some  = Algebrick.type { fields Object }
Maybe = Algebrick.type { variants None, Some }

# where the Maybe actually is:
Maybe.class
Maybe.class.superclass
Maybe.class.superclass.superclass
Maybe.class.superclass.superclass.superclass

# if there is a circular dependency you can define the dependent types inside the block like this:
Tree = Algebrick.type do |tree|
  Empty = type
  Leaf  = type { fields Integer }
  Node  = type { fields tree, tree }

  variants Empty, Leaf, Node
end

