# Let's define a tree and binary tree to demonstrate the pattern matching abilities.
Tree = Algebrick.type do |tree|
  variants Empty = type,
           Leaf  = type { fields Integer },
           Node  = type { fields tree, tree }
end

BinaryTree = BTree = Algebrick.type do |btree|
  fields! value: Comparable, left: btree, right: btree
  variants Empty, btree
end

extend Algebrick::Matching

# Product matchers are constructed with #.() syntax.
Leaf.(any) === Leaf[1]
Leaf.(1) === Leaf[1]
Leaf.(2) === Leaf[1]
# There are also some shortcuts to use when product has more fields.
BTree.()
BTree.(value: any, left: Empty)
BTree.(value: any, left: Empty) === BTree[1, Empty, Empty]

# Any object responding to #=== can be converted to matcher.
(1..2).to_m
(1..2).to_m === 2
Empty.to_m
# As matchers are using standard #=== method it does not have to be always converted.
Empty === Empty
Leaf === Leaf[1]

# Tree matches all its values.
[Empty, Leaf[1], Node[Empty, Empty]].all? { |v| Tree === v }

# There is also a #match method in Matching module to make pattern matching easier.
match Leaf[1], # supply the value for matching
      # if Leaf.(0) matches :zero is returned
      (on Leaf.(0), :zero),
      # when computation of the result needs to be avoided use block
      # if Leaf.(1) matches block is called and its result is returned
      (on Leaf.(1) do
        (1..10000).inject(:*) # expensive computation
        :one # which is :one in this case
      end)

# Alternatively case can be used.
case Leaf[1]
when Leaf.(0)
  :zero
when Leaf.(1)
  (1..10000).inject(:*) # expensive computation
  :one
end

# But that won't work nicely with value deconstruction.
# Each matcher can be marked with #~ method to store value against which is being matched,
# each matched value is passed to the block, ...
match Leaf[0],
      (on ~Leaf.(~any) do |leaf, value|
        [leaf, value]
      end)

btree = BTree[1,
              BTree[0, Empty, Empty],
              Empty]
match btree,
      (on BTree.(any, ~any, ~any) do |left, right|
        [left, right]
      end)

# or alternatively you can use Ruby's multi-assignment feature.
match btree,
      (on ~BTree do |(_, left, right)|
        [left, right]
      end)


# Matchers also support logical operations #& for and, #| for or, and #! for negation.
Color = Algebrick.type do
  variants Black = atom,
           White = atom,
           Pink  = atom,
           Grey  = type { fields scale: Float }
end

def color?(color)
  match color,
        on(Black | Grey.(-> v { v < 0.2 }), 'black-ish'),
        on(White | Grey.(-> v { v > 0.8 }), 'white-ish'),
        on(Grey.(-> v { v >= 0.2 }) & Grey.(-> v { v <= 0.8 }), 'grey-ish'),
        on(Pink, "that's not a color ;)")
end

color? Black
color? Grey[0.1]
color? Grey[0.3]
color? Grey[0.9]
color? White
color? Pink

# A more complicated example of extracting node's value and values of its left and right side
# using also logical operators to allow Empty sides.
match BTree[0, Empty, BTree[1, Empty, Empty]],
      (on BTree.({ value: ~any,
                   left:  Empty | BTree.(value: ~any),
                   right: Empty | BTree.(value: ~any) }) do |value, left, right|
        { left: left, value: value, right: right }
      end)

# It also supports matching against Ruby Arrays
Array.() === []
Array.() === [1]
Array.(*any) === []
Array.(*any) === [1]
Array.(*any) === [1, 2]
Array.(1, *any) === []
Array.(1, *any) === [1]
Array.(1, *any) === [1, 2]

match [],
      on(~Array.to_m) { |v| v }
match [],
      on(~Array.()) { |v| v }
match [1, 2],
      on(~Array.(*any)) { |v| v }
match [1, 2],
      on(~Array.(*any)) { |(v, _)| v }
match [1, 2, 3],
      on(Array.(any, *~any)) { |v| v }
match [:first, 1, 2, 3],
      on(Array.(:first, ~any, *any)) { |v| v }
match [:+, 1, 2, :foo, :bar],
      (on Array.(:+, ~Integer.to_m, ~Integer.to_m, *~any) do |int1, int2, rest|
        { sum: int1 + int2, rest: rest }
      end)


# There is also a more funky syntax for matching
# using #>, #>> and Ruby 1.9 syntax for lambdas `-> {}`.
match Leaf[1],
      Leaf.(0) >> :zero,
      Leaf.(~any) >-> value do
        (1..value).inject(:*) # an expensive computation
      end
