# lets define a Tree
Tree = Algebrick.type do |tree|
  Empty = type
  Leaf  = type { fields Integer }
  Node  = type { fields tree, tree }

  variants Empty, Leaf, Node
end

# values of atomic types are represented by itself,
# they are theirs own value
Empty.kind_of? Algebrick::Value
Empty.kind_of? Algebrick::Type
Empty.kind_of? Empty

# values of product types are constructed with #[]
Leaf[1].kind_of? Algebrick::Value
Leaf[1].kind_of? Leaf
Leaf[1].kind_of? Tree

# Variant does not have its own values, it uses atoms and products

# Product also can have its fields named
BTree = Algebrick.type do |bt|
  Tip = type
  fields value: Integer, left: bt, right: bt
  variants Tip, bt
end

# Then values can be created with names
tree1 = BTree[value: 1, left: Tip, right: Tip]
# or without them
BTree[0, Tip, tree1]

# To read the values use:
# 1. method #value when type has only one field.
Leaf[1].value
# 2. multi-assign when type has more fields
v, left, right = *BTree[value: 1, left: Tip, right: Tip]
# 3. or #[] when fields are named
BTree[value: 1, left: Tip, right: Tip][:value]
BTree[value: 1, left: Tip, right: Tip][:left]

# BTree can also by made to create method accessors for its named fields
BTree.add_all_field_method_readers
BTree[1, Tip, Tip].value
BTree[1, Tip, Tip].left

# it raises TypeError when being constructed with wrong type
try = -> &b do
  begin
    b.call
  rescue TypeError => e
    e
  end
end
try.call { Leaf['a'] }
try.call { Node[nil, Empty] }


