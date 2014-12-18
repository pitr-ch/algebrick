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
Tree.class                                         # => Algebrick::ParametrizedType
[Tree, Leaf, Node]
    # => [Tree[value_type], Leaf[value_type], Node[value_type]]
# which servers as factories to actual types.
Tree[Float]                                        # => Tree[Float](Empty | Leaf[Float] | Node[Float])
Tree[String]                                       # => Tree[String](Empty | Leaf[String] | Node[String])

# Types cannot be mixed.
Leaf[Integer]['1'] rescue $!
    # => #<TypeError: Value (String) '1' is not any of: Integer.>
Node[Integer][Leaf[String]['a'], Empty] rescue $!
    # => #<TypeError: Value (Leaf[String](value: String)) 'Leaf[String][value: a]' is not any of: Tree[Integer](Empty | Leaf[Integer] | Node[Integer]).>
Leaf[String]['1']                                  # => Leaf[String][value: 1]

# Depth method works as before.
integer_tree = Node[Integer][Leaf[Integer][2], Empty]
    # => Node[Integer][left: Leaf[Integer][value: 2], right: Empty]
integer_tree.depth                                 # => 2
string_tree = Node[String][Empty, Empty]           # => Node[String][left: Empty, right: Empty]
string_tree.depth                                  # => 1

