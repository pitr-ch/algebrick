# lets define a trees to demonstrate the pattern matching abilities
Tree = Algebrick.type do |tree|
  Empty = type
  Leaf  = type { fields Integer }
  Node  = type { fields tree, tree }

  variants Empty, Leaf, Node
end

BTree = Algebrick.type do |btree|
  fields value: Comparable, left: btree, right: btree
  all_readers
  variants Empty, btree
end

extend Algebrick::Matching

# Basic Examples
# Any object responding to #=== can be converted to matcher.
Empty.to_m === Empty
Empty === Empty
# product matchers are using #.() syntax
Leaf === Leaf[1]
Leaf.(any) === Leaf[1]
Leaf.(1) === Leaf[1]
Leaf.(2) === Leaf[1]

# Tree matches all its values same as its matcher
[Empty, Leaf[1], Node[Empty, Empty]].all? { |v| Tree === v }
[Empty, Leaf[1], Node[Empty, Empty]].all? { |v| Tree.to_m === v }

# to collect assigns from matching use #~ operator to mark the matchers to collect the value
(m = Leaf.(~any)) === Leaf[1]; m.assigns
(m = Leaf.(~any)) === Leaf[2]; m.assigns
(m = ~Leaf.(~any)) === Leaf[2]; m.assigns
# assigns returns array with length of ~ count and values in same order as its ~
# any is aliased as _
(m = ~Node.(_, ~Leaf.(~any))) === Node[Leaf[2], Leaf[3]]
m.assigns

# #assigns accepts block
(m = Node.(~any, ~any)) === Node[Leaf[2], Empty]
m.assigns { |l, r| Node[r, l] }

# matcher can be combined with any object responding to #===
Leaf.(-> v { v > 1 }) === Leaf[2]
# it has to be converted to matcher to access matchers features
(m = Leaf.(~-> v { v > 1 }.to_m)) === Leaf[2]; m.assigns

# case can be used as expected
case Leaf[1]
when Leaf.(-> v { v < 0 })
  :minus
when Leaf.(-> v { v >= 0 })
  :plus
end

# to access assigns
case Leaf[-1]
when m = Leaf.(~-> v { v < 0 }.to_m)
  m.assigns.first
when m = Leaf.(~-> v { v >= 0 }.to_m)
  m.assigns.first
end

# using local variable in case is not quite nice, there is a helper #match to get around that
match Leaf[0],
      Leaf.(~-> v { v < 0 }.to_m)  => -> v { v-10 },
      Leaf.(~-> v { v >= 0 }.to_m) => -> v { v+10 }

# match will fail when nothing matches
begin
  match Leaf[1],
        Node.to_m >> true
rescue => e
  e
end

# alternative syntax are
match Leaf[0],
      Leaf.(~-> v { v < 0 }.to_m).case { |v| v-10 },
      Leaf.(~-> v { v >= 0 }.to_m).case { |v| v+10 }
# which evaluates to
match Leaf[0],
      [Leaf.(~-> v { v < 0 }.to_m), -> v { v-10 }],
      [Leaf.(~-> v { v >= 0 }.to_m), -> v { v+10 }]
# operators may also be used as sugar to construct arrays above
match Leaf[6],
      Leaf.(~-> v { v%2 == 0 }.to_m) >> 2,
      Leaf.(~-> v { v%3 == 0 }.to_m) >-> v { 3 }
# the last example of using #>> for static values and #>-> for blocks in #match
# is the preferred matching syntax

# Matchers support logical operations
# #& for and, #| for or, and #! for negation
(m = Leaf.(-> v { v > 1 }.to_m & ~-> v { v < 3 }.to_m)) === Leaf[2]; m.assigns
(m = Leaf.(~-> v { v > 1 }.to_m | ~-> v { v < 3 }.to_m)) === Leaf[2]; m.assigns
(m = Leaf.(~-> v { v > 1 }.to_m ^ ~-> v { v < 3 }.to_m)) === Leaf[2]; m.assigns
(m = Leaf.(~!-> v { v > 1 }.to_m)) === Leaf[0]; m.assigns

Color = Algebrick.type do
  variants Black = atom,
           White = atom,
           Pink  = atom,
           Grey  = type { fields scale: Float }
end

def what_color?(color)
  match color,
        Black | Grey.(-> v { v < 0.2 }) >-> { 'black-ish' },
        White | Grey.(-> v { v > 0.8 }) >-> { 'white-ish' },
        Grey.(-> v { v >= 0.2 }.to_m & -> v { v <= 0.8 }.to_m) >-> { 'grey-ish' },
        Pink >> "that's not a color"
end

what_color? Black
what_color? Grey[0.1]
what_color? Grey[0.3]
what_color? Grey[0.9]
what_color? White
what_color? Pink

# There are also shortcuts to match on named fields
match BTree[1.5, Empty, Empty],
      BTree.(:value) >-> v { v }

match BTree[1.5, Empty, BTree[4.5, Empty, Empty]],
      BTree.(value: ~any, right: BTree.(:value)) >-> value, right_value do
        [value, right_value]
      end


