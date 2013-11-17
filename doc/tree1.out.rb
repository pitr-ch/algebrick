Tree = Algebrick.type do |tree|
  variants Empty = type,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end                                                # => Tree(Empty | Leaf | Node)
# Which sets 4 modules representing these types in current module/class
Tree                                               # => Tree(Empty | Leaf | Node)
Empty                                              # => Empty
Leaf                                               # => Leaf(Integer)
Node                                               # => Node(Tree, Tree)
