Tree = Algebrick.type(:v) do |tree|
  Empty = atom
  Leaf  = type(:v) { fields value: :v }
  Node  = type(:v) { fields left: tree, right: tree }
  variants Empty, Leaf, Node
end                                                # => Tree[v]

module Tree
  def depth
    match self,
          Empty >> 0,
          Leaf >> 1,
          Node.(~any, ~any) >-> left, right do
            1 + [left.depth, right.depth].max
          end
  end
end                                                # => nil

Leaf[Integer]['1'] rescue $!
# => #<TypeError: value (String) '1' is not #kind_of? any of Integer>
Node[Integer][Leaf[String]['a'], Empty] rescue $!
# => #<TypeError: value (#<Class:0x007fd968aad8b0>) 'Leaf[String][value: a]' is not #kind_of? any of Tree[Integer](Empty | Leaf[Integer] | Node[Integer])>
Leaf[String]['1']                                  # => Leaf[String][value: 1]

itree = Node[Integer][Leaf[Integer][2], Empty]
# => Node[Integer][left: Leaf[Integer][value: 2], right: Empty]
itree.depth                                        # => 2
stree = Node[String][Empty, Empty]                 # => Node[String][left: Empty, right: Empty]
stree.depth                                        # => 1

