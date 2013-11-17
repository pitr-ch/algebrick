Tree = Algebrick.type do |tree|
  variants Empty = type,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end
# Which sets 4 modules representing these types in current module/class
Tree
Empty
Leaf
Node
