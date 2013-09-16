Tree = Algebrick.type do |tree|
  Empty = type
  Leaf  = type { fields Integer }
  Node  = type { fields tree, tree }

  variants Empty, Leaf, Node
end
# Which sets 4 modules representing these types in current module/class
Tree
Empty
Leaf
Node
