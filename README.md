# Algebrick

[![Build Status](https://travis-ci.org/pitr-ch/algebrick.png?branch=master)](https://travis-ci.org/pitr-ch/algebrick)

It's a gem providing **algebraic types** and **pattern matching** seamlessly integrates with standard features Ruby.

-   Documentation: <http://blog.pitr.ch/algebrick>
-   Source: <https://github.com/pitr-ch/algebrick>
-   Blog: <http://blog.pitr.ch/blog/categories/algebrick/>

## What is it good for?

-   Defining data structures.
-   Algebraic types play nice with JSON serialization and deserialization. It is ideal for defining message-based cross-process communication.
-   and more...

## Quick example

Let's define a Tree

```ruby
Tree = Algebrick.type do |tree|
  variants Empty = atom,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end
```

Now types `Tree(Empty | Leaf | Node)`, `Empty`, `Leaf(Integer)` and `Node(Tree, Tree)` are defined.
Let's add a method, don't miss the **pattern matching** example.

```ruby
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
end
```

Method defined in module `Tree` are passed down to **all** values of type Tree

```ruby
Empty.depth                                        # => 0
Leaf[10].depth                                     # => 1
Node[Leaf[4], Empty].depth                         # => 2
Node[Empty, Node[Leaf[1], Empty]].depth            # => 3
```
