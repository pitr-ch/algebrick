extend Algebrick::DSL                              # => main

# lets define a tree to demonstrate the pattern matching abilities
type_def { tree === empty | leaf(Integer) | node(tree, tree) }
# => [Tree(Empty | Leaf | Node), Empty, Leaf(Integer), Node(Tree, Tree)]

extend Algebrick::Matching                         # => main

# Basic Examples
# Any object responding to #=== can be converted to matcher.
Empty.to_m === Empty                               # => true
Empty === Empty                                    # => true
# product matchers are using #.() syntax
Leaf === Leaf[1]                                   # => true
Leaf.(any) === Leaf[1]                             # => true
Leaf.(1) === Leaf[1]                               # => true
Leaf.(2) === Leaf[1]                               # => false

# Tree matches all its values same as its matcher
[Empty, Leaf[1], Node[Empty, Empty]].all? { |v| Tree === v }
# => true
[Empty, Leaf[1], Node[Empty, Empty]].all? { |v| Tree.to_m === v }
# => true

# to collect assigns from matching use #~ operator to mark the matchers to collect the value
(m = Leaf.(~any)) === Leaf[1]; m.assigns           # => [1]
(m = Leaf.(~any)) === Leaf[2]; m.assigns           # => [2]
(m = ~Leaf.(~any)) === Leaf[2]; m.assigns          # => [Leaf[2], 2]
# assigns returns array with length of ~ count and values in same order as its ~
# any is aliased as _
(m = ~Node.(_, ~Leaf.(~any))) === Node[Leaf[2], Leaf[3]]
# => true
m.assigns                                          # => [Node[Leaf[2],Leaf[3]], Leaf[3], 3]

# #assigns accepts block
(m = Node.(~any, ~any)) === Node[Leaf[2], Empty]   # => true
m.assigns { |l, r| Node[r, l] }                    # => Node[Empty,Leaf[2]]

# matcher can be combined with any object responding to #===
Leaf.(-> v { v > 1 }) === Leaf[2]                  # => true
# it has to be converted to matcher to access matchers features
(m = Leaf.(~-> v { v > 1 }.to_m)) === Leaf[2]; m.assigns
# => [2]

# case can be used as expected
case Leaf[1]
when Leaf.(-> v { v < 0 })
  :minus
when Leaf.(-> v { v >= 0 })
  :plus
end                                                # => :plus

# to access assigns
case Leaf[-1]
when m = Leaf.(~-> v { v < 0 }.to_m)
  m.assigns.first
when m = Leaf.(~-> v { v >= 0 }.to_m)
  m.assigns.first
end                                                # => -1

# using local variable in case is not quite nice, there is a helper #match to get around that
match Leaf[0],
      Leaf.(~-> v { v < 0 }.to_m)  => -> v { v-10 },
      Leaf.(~-> v { v >= 0 }.to_m) => -> v { v+10 }
# => 10

# match will fail when nothing matches
begin
  match Leaf[1],
        Node.to_m >> true
rescue => e
  e
end
# => #<RuntimeError: no match for Leaf[1] by any of Node.(any,any)>

# alternative syntax are
match Leaf[0],
      Leaf.(~-> v { v < 0 }.to_m).case { |v| v-10 },
      Leaf.(~-> v { v >= 0 }.to_m).case { |v| v+10 }
# => 10
# which evaluates to
match Leaf[0],
      [Leaf.(~-> v { v < 0 }.to_m), -> v { v-10 }],
      [Leaf.(~-> v { v >= 0 }.to_m), -> v { v+10 }]
# => 10
# operators may also be used
match Leaf[6],
      Leaf.(~-> v { v%2 == 0 }.to_m) >> 2,
      Leaf.(~-> v { v%3 == 0 }.to_m) --> v { 3 },

# Matchers support logical operations
# #& for and, #| for or, and #! for negation
(m = Leaf.(-> v { v > 1 }.to_m & ~-> v { v < 3 }.to_m)) === Leaf[2]; m.assigns
# => [2]
(m = Leaf.(~-> v { v > 1 }.to_m | ~-> v { v < 3 }.to_m)) === Leaf[2]; m.assigns
# => [2, nil]
(m = Leaf.(~!-> v { v > 1 }.to_m)) === Leaf[0]; m.assigns
# => [0]



