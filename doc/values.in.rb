# Let's define a Tree
Tree = Algebrick.type do |tree|
  variants Empty = type,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end

# Values of atomic types are represented by itself,
# they are theirs own value.
Empty.kind_of? Algebrick::Value
Empty.kind_of? Algebrick::Type
Empty.kind_of? Empty

# Values of product types are constructed with #[] and they are immutable.
Leaf[1].kind_of? Algebrick::Value
Leaf[1].kind_of? Leaf
Node[Empty, Empty].kind_of? Node

# Variant does not have its own values, it uses atoms and products.
Leaf[1].kind_of? Tree
Empty.kind_of? Tree

# Product can have its fields named.
BinaryTree = BTree = Algebrick.type do |btree|
  fields! value: Integer, left: btree, right: btree
  variants Tip = atom, btree
end

# Then values can be created with names
tree1      = BTree[value: 1, left: Tip, right: Tip]
# or without them as before.
BTree[0, Tip, tree1]

# Fields of products can be read as follows:
# 1. When type has only one field method #value is defined
Leaf[1].value
# 2. By multi-assign
v, left, right = BTree[value: 1, left: Tip, right: Tip]
[v, left, right]
# 3. With #[] method when fields are named
BTree[value: 1, left: Tip, right: Tip][:value]
BTree[value: 1, left: Tip, right: Tip][:left]
# 4. With methods named by fields when fields are named
#    (it can be disabled if fields are defined with #fields instead of #fields!)
BTree[1, Tip, Tip].value
BTree[1, Tip, Tip].left

# Product instantiation raises TypeError when being constructed with wrong type.
Leaf['a'] rescue $!
Node[nil, Empty] rescue $!


