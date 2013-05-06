# Using dsl is a preferred way
extend Algebrick::DSL
type_def { maybe === none | some(Object) }

# but lets see what it actually does. The `type_def` above is equivalent to:
None  = Algebrick::Atom.new
Some  = Algebrick::Product.new(Object)
Maybe = Algebrick::Variant.new(None, Some)

# and to show what Maybe is
Maybe.class
Maybe.class.superclass
Maybe.class.superclass.superclass
Maybe.class.superclass.superclass.superclass

# DSL is preferred because it makes recursive definitions easy
type_def { tree === empty | leaf(Integer) | node(tree, tree) }

# would have to be written this way
begin
  Empty = Algebrick::Atom.new
  Leaf  = Algebrick::Product.new Integer
  Tree  = Algebrick::Variant.allocate
  Node  = Algebrick::Product.new Tree, Tree
  Tree.send :initialize, Empty, Leaf, Node
  # and it can get much more complicated than one #allocate
end





