# load DSL for type definition
extend Algebrick::DSL

# define algebraic types
type_def do
  tree === empty | leaf(Integer) | node(tree, tree)
end

# add some methods
module Tree
  # compute depth of a tree
  def depth
    match self,
          Empty >> 0,
          Leaf >> 1,
          # ~ will store and pass matched parts to variables left and right
          Node.(~any, ~any) --> left, right do
            1 + [left.depth, right.depth].max
          end
  end
end

# methods are defined on all values of type Tree
Empty.depth
Leaf[10].depth
Node[Leaf[4], Empty].depth
Node[Empty, Node[Leaf[1], Empty]].depth
