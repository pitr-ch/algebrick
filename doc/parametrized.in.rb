# Let's define Tree but this time parameterized by :value_type,
Tree = Algebrick.type(:value_type) do |tree|
  variants Empty = atom,
           Leaf  = type(:value_type) { fields value: :value_type },
           Node  = type(:value_type) { fields left: tree, right: tree }
end

# with method depth defined as before.
module Tree
  def depth
    match self,
          Empty >> 0,
          Leaf >> 1,
          Node.(~any, ~any) >-> left, right do
            1 + [left.depth, right.depth].max
          end
  end
end

# Then Tree, Leaf, Node are
Tree.class
[Tree, Leaf, Node]
# which servers as factories to actual types.
Tree[Float]
Tree[String]

# Types cannot be mixed.
Leaf[Integer]['1'] rescue $!
Node[Integer][Leaf[String]['a'], Empty] rescue $!
Leaf[String]['1']

# Depth method works as before.
integer_tree = Node[Integer][Leaf[Integer][2], Empty]
integer_tree.depth
string_tree = Node[String][Empty, Empty]
string_tree.depth

