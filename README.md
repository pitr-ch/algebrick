# Algebrick

[![Build Status](https://travis-ci.org/pitr-ch/algebrick.png?branch=master)](https://travis-ci.org/pitr-ch/algebrick)

Typed structs on steroids based on algebraic types and pattern matching seamlessly integrating with standard Ruby features.

-   Documentation: <http://blog.pitr.ch/algebrick>
-   Source: <https://github.com/pitr-ch/algebrick>
-   Blog: <http://blog.pitr.ch/tag/algebrick.html>

## What is it good for?

-   Well defined data structures.
-   Actor messages see [new Actor implementation](http://rubydoc.info/gems/concurrent-ruby/Concurrent/Actress) 
    in [concurrent-ruby](concurrent-ruby.com).
-   Describing message protocols in message-based cross-process communication. 
    Algebraic types play nice with JSON de/serialization.
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
