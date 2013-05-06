# Using dsl is a preferred way
extend Algebrick::DSL                              # => main
type_def { maybe === none | some(Object) }         # => [Maybe(None | Some), None, Some(Object)]

# but lets see what it actually does. The `type_def` above is equivalent to:
None  = Algebrick::Atom.new                        # => None
Some  = Algebrick::Product.new(Object)             # => Some(Object)
Maybe = Algebrick::Variant.new(None, Some)         # => Maybe(None | Some)

# and to show what Maybe is
Maybe.class                                        # => Algebrick::Variant
Maybe.class.superclass                             # => Algebrick::AbstractProductVariant
Maybe.class.superclass.superclass                  # => Algebrick::Type
Maybe.class.superclass.superclass.superclass       # => Module

# DSL is preferred because it makes recursive definitions easy
type_def { tree === empty | leaf(Integer) | node(tree, tree) }
# => [Tree(Empty | Leaf | Node), Empty, Leaf(Integer), Node(Tree, Tree)]

# would have to be written this way
begin
  Empty = Algebrick::Atom.new
  Leaf  = Algebrick::Product.new Integer
  Tree  = Algebrick::Variant.allocate
  Node  = Algebrick::Product.new Tree, Tree
  Tree.send :initialize, Empty, Leaf, Node
  # and it can get much more complicated than one #allocate
end                                                # => Tree(Empty | Leaf | Node)





