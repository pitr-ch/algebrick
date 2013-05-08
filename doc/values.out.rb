extend Algebrick::DSL                              # => main
# lets define some types
type_def do
  tree === empty | leaf(Integer) | node(tree, tree)
end
# => [Tree(Empty | Leaf | Node), Empty, Leaf(Integer), Node(Tree, Tree)]

# values of atomic types are represented by itself,
# they are theirs own value
Empty.kind_of? Algebrick::Value                    # => true
Empty.kind_of? Algebrick::Type                     # => true
Empty.kind_of? Empty                               # => true

# values of product types are constructed with #[]
Leaf[1].kind_of? Algebrick::Value                  # => true
Leaf[1].kind_of? Leaf                              # => true
Leaf[1].kind_of? Tree                              # => true

# Variants and ProductVariants does not have its own values,
# they use atoms and products

# Product also can have its fields named
type_def { b_tree === tip | b_tree(value: Integer, left: b_tree, right: b_tree) }
# => [BTree(Tip | BTree(value: Integer, left: BTree, right: BTree)), Tip]
# values can be created with names
tree1 = BTree[value: 1, left: Tip, right: Tip]     # => BTree[value: 1, left: Tip, right: Tip]
# or without them
BTree[0, Tip, tree1]
# => BTree[value: 0, left: Tip, right: BTree[value: 1, left: Tip, right: Tip]]

# to read values use:
# method #value when type has only one field
Leaf[1].value                                      # => 1
# multi-assign when type has more fields
v, left, right = *BTree[value: 1, left: Tip, right: Tip]
# => [1, Tip, Tip]
# or #[] when fields are named
BTree[value: 1, left: Tip, right: Tip][:value]     # => 1
BTree[value: 1, left: Tip, right: Tip][:left]      # => Tip

# it raises TypeError when being constructed with wrong type
try = -> &b do
  begin
    b.call
  rescue TypeError => e
    e
  end
end
# => #<Proc:0x007fe0919089a8@/Users/pitr/Workspace/personal/algebrick/doc/values.in.rb:44 (lambda)>
try.call { Leaf['a'] }
# => #<TypeError: value (String) 'a' is not #kind_of? any of Integer>
try.call { Node[nil, Empty] }
# => #<TypeError: value (NilClass) '' is not #kind_of? any of Tree(Empty | Leaf | Node)>


