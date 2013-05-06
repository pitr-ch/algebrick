extend Algebrick::DSL
# lets define some types
type_def do
  tree === empty | leaf(Integer) | node(tree, tree)
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

# Variants and ProductVariants does not have its own values,
# they use atoms and products

# Product also can have its fields named
type_def { b_tree === tip | b_tree(value: Integer, left: b_tree, right: b_tree) }
# values can be created with names
tree1 = BTree[value: 1, left: Tip, right: Tip]
# or without them
BTree[0, Tip, tree1]

# to read values use:
# method #value when type has only one field
Leaf[1].value
# multi-assign when type has more fields
v, left, right = *BTree[value: 1, left: Tip, right: Tip]
# or #[] when fields are named
BTree[value: 1, left: Tip, right: Tip][:value]
BTree[value: 1, left: Tip, right: Tip][:left]

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


