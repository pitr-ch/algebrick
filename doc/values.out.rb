# lets define a Tree
Tree = Algebrick.type do |tree|
  variants Empty = type,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end                                                # => Tree(Empty | Leaf | Node)

# values of atomic types are represented by itself,
# they are theirs own value
Empty.kind_of? Algebrick::Value                    # => true
Empty.kind_of? Algebrick::Type                     # => true
Empty.kind_of? Empty                               # => true

# values of product types are constructed with #[]
Leaf[1].kind_of? Algebrick::Value                  # => true
Leaf[1].kind_of? Leaf                              # => true
Leaf[1].kind_of? Tree                              # => true

# Variant does not have its own values, it uses atoms and products

# Product also can have its fields named
BTree = Algebrick.type do |bt|
  Tip = type
  fields value: Integer, left: bt, right: bt
  variants Tip, bt
end
# => BTree(Tip | BTree(value: Integer, left: BTree, right: BTree))

# Then values can be created with names
tree1 = BTree[value: 1, left: Tip, right: Tip]     # => BTree[value: 1, left: Tip, right: Tip]
# or without them
BTree[0, Tip, tree1]
# => BTree[value: 0, left: Tip, right: BTree[value: 1, left: Tip, right: Tip]]

# To read the values use:
# 1. method #value when type has only one field.
Leaf[1].value                                      # => 1
# 2. multi-assign when type has more fields
v, left, right = BTree[value: 1, left: Tip, right: Tip]
# => BTree[value: 1, left: Tip, right: Tip]
[v, left, right]                                   # => [1, Tip, Tip]
# 3. or #[] when fields are named
BTree[value: 1, left: Tip, right: Tip][:value]     # => 1
BTree[value: 1, left: Tip, right: Tip][:left]      # => Tip

# BTree can also by made to create method accessors for its named fields
BTree.add_all_field_method_readers
# => BTree(Tip | BTree(value: Integer, left: BTree, right: BTree))
BTree[1, Tip, Tip].value                           # => 1
BTree[1, Tip, Tip].left                            # => Tip

# it raises TypeError when being constructed with wrong type
try = -> &b do
  begin
    b.call
  rescue TypeError => e
    e
  end
end
# => #<Proc:0x007fbfda8bc120@/Users/pitr/Workspace/public/algebrick/doc/values.in.rb:55 (lambda)>
try.call { Leaf['a'] }
# => #<TypeError: value (String) 'a' is not any of Integer>
try.call { Node[nil, Empty] }
# => #<TypeError: value (NilClass) '' is not any of Tree(Empty | Leaf | Node)>


