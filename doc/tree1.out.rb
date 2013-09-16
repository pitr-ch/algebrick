Tree = Algebrick.type do |tree|
  Empty = type
  Leaf  = type { fields Integer }
  Node  = type { fields tree, tree }

  variants Empty, Leaf, Node
end                                                # => Tree(Empty | Leaf | Node)
# Which sets 4 modules representing these types in current module/class
Tree                                               # => Tree(Empty | Leaf | Node)
Empty                                              # => Empty
Leaf                                               # => Leaf(Integer)
Node                                               # => Node(Tree, Tree)
