Tree = Algebrick.type(:v) do |tree|
  variants Empty = atom,
           Leaf  = type(:v) { fields value: :v },
           Node  = type(:v) { fields left: tree, right: tree }
end

module Tree
  def depth
    match self,
          Empty >> 0,
          Leaf >> 1,
          Node.(~any, ~any) >-> left, right do
            1 + [left.depth, right.depth].max
          end
  end
end

Leaf[Integer]['1'] rescue $!
Node[Integer][Leaf[String]['a'], Empty] rescue $!
Leaf[String]['1']

itree = Node[Integer][Leaf[Integer][2], Empty]
itree.depth
stree = Node[String][Empty, Empty]
stree.depth

