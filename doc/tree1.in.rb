extend Algebrick::DSL
type_def { tree === empty | leaf(Integer) | node(tree, tree) }
# Which defines 4 modules representing these types in current module/class
Tree
Empty
Leaf
Node
