extend Algebrick::DSL                              # => main
type_def { tree === empty | leaf(Integer) | node(tree, tree) }
# => [Tree(Empty | Leaf | Node), Empty, Leaf(Integer), Node(Tree, Tree)]
# Which defines 4 modules representing these types in current module/class
Tree                                               # => Tree(Empty | Leaf | Node)
Empty                                              # => Empty
Leaf                                               # => Leaf(Integer)
Node                                               # => Node(Tree, Tree)
