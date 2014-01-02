# Let's define a Tree
Tree = Algebrick.type do |tree|
  variants Empty = atom,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end                                                # => Tree(Empty | Leaf | Node)

# Now types `Tree(Empty | Leaf | Node)`, `Empty`, `Leaf(Integer)` and `Node(Tree, Tree)` are defined.
# Let's add a method, don't miss the **pattern matching** example.
module Tree
  # compute depth of a tree
  def depth
    match self,
          (on Empty, 0),
          (on Leaf, 1),
          # ~ will store and pass matched parts to variables left and right
          (on Node.(~any, ~any) do |left, right|
            1 + [left.depth, right.depth].max
          end)
  end
end                                                # => nil

# Method defined in module `Tree` are passed down to **all** values of type Tree.
Empty.depth                                        # => 0
Leaf[10].depth                                     # => 1
Node[Leaf[4], Empty].depth                         # => 2
Node[Empty, Node[Leaf[1], Empty]].depth            # => 3
