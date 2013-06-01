## Algebrick

Is a small gem providing **algebraic types** and **pattern matching** on them for Ruby.

-   Documentation: <http://blog.pitr.ch/algebrick>
-   Source: <https://github.com/pitr-ch/algebrick>
-   Blog: <http://blog.pitr.ch/blog/categories/algebrick/>

### What is it good for?

-   Defining data structures.
-   Algebraic types play nice with JSON serialization and deserialization. It is ideal for defining
    message-based cross-process communication.
-   and more...

### Quick example

Load DSL for type definition and define some algebraic types

```ruby
extend Algebrick::DSL

type_def do
  tree === empty | leaf(Integer) | node(tree, tree)
end
```

Now types `Tree(Empty | Leaf | Node)`, `Empty`, `Leaf(Integer)` and `Node(Tree, Tree)` are defined.
Lets add some methods, don't miss the **pattern matching** example.

```ruby
module Tree
  # compute depth of a tree
  def depth
    match self,
          Empty >> 0,
          Leaf >> 1,
          Node.(~any, ~any) --> left, right do
            1 + [left.depth, right.depth].max
          end
  end
end
```

Methods are defined on **all** values of type Tree

```ruby
Empty.depth                                        # => 0
Leaf[10].depth                                     # => 1
Node[Leaf[4], Empty].depth                         # => 2
Node[Empty, Node[Leaf[1], Empty]].depth            # => 3
```
