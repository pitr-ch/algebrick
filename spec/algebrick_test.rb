#  Copyright 2013 Petr Chalupa <git@pitr.ch>
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Reporters.use!

require 'pp'
require 'algebrick'
require 'pry'

class Module
  def const_missing const
    raise "no constant #{const.inspect} in #{self}"
  end
end

describe 'AlgebrickTest' do
  i_suck_and_my_tests_are_order_dependent!

  Algebrick.types do
    Tree = type do |tree|
      Empty = type
      Leaf  = type { fields Integer }
      Node  = type { fields tree, tree }

      variants Empty, Leaf, Node
    end

    BTree = type do |btree|
      fields! value: Comparable, left: btree, right: btree
      variants Empty, btree
    end
  end

  module Tree
    def a
      :a
    end

    def depth
      case self
      when Empty
        0
      when Leaf
        1
      when Node
        left, right = *self
        1 + [left.depth, right.depth].max
      end
    end

    def each(&block)
      return to_enum :each unless block
      case self
      when Empty
      when Leaf
        block.call self.value
      when Node
        left, right = *self
        left.each &block
        right.each &block
      end
    end

    def sum
      each.inject(0) { |sum, v| sum + v }
    end
  end

  List = Algebrick.type do |list|
    variants Empty, list
    fields Integer, list
  end

  describe 'type definition' do
    module Asd
      C = Algebrick.type
      D = Algebrick.type
      B = Algebrick.type { variants C, D }
    end

    it 'asd' do
      assert Asd::B
    end
  end

  describe 'type.to_s' do
    it { Empty.to_s.must_equal 'Empty' }
    it { Node.to_s.must_equal 'Node(Tree, Tree)' }
    it { Leaf.to_s.must_equal 'Leaf(Integer)' }
    it { Tree.to_s.must_equal 'Tree(Empty | Leaf | Node)' }
    it { List.to_s.must_equal 'List(Empty | List(Integer, List))' }
  end

  describe 'atom' do
    it { Empty.must_be_kind_of Algebrick::Type }
    it { Empty.must_be_kind_of Algebrick::Value }
    it { assert Empty.kind_of? Empty }

    it { assert Empty == Empty }
    it { assert Empty === Empty }
    it { eval(Empty.to_s).must_equal Empty }
    it { eval(Empty.inspect).must_equal Empty }

    it { Empty.from_hash(Empty.to_hash).must_equal Empty }
  end

  describe 'product' do
    it { Leaf[1].must_be_kind_of Algebrick::Value }
    it { Leaf.must_be_kind_of Algebrick::Type }
    it { Leaf[1].wont_be_kind_of Algebrick::Type }
    it { Leaf.wont_be_kind_of Algebrick::Value }

    it { assert Leaf[1] == Leaf[1] }
    it { assert Leaf[1] != Leaf[0] }
    it { assert Leaf === Leaf[1] }
    it { assert Leaf[1].kind_of? Leaf }
    it { eval(Leaf[1].to_s).must_equal Leaf[1] }
    it { eval(Leaf[1].inspect).must_equal Leaf[1] }
    it { eval(Node[Leaf[1], Empty].to_s).must_equal Node[Leaf[1], Empty] }
    it { eval(Node[Leaf[1], Empty].inspect).must_equal Node[Leaf[1], Empty] }

    it 'field assign' do
      value = Leaf[1].value
      value.must_equal 1

      left, right = *Node[Empty, Leaf[1]]
      left.must_equal Empty
      right.must_equal Leaf[1]

      lambda { Node[Empty, Empty].value }.must_raise NoMethodError
    end

    it { lambda { Leaf['a'] }.must_raise TypeError }
    it { lambda { Leaf[nil] }.must_raise TypeError }
    it { lambda { Node['a'] }.must_raise TypeError }
    ComparableItem = Class.new { include Comparable }
    it { BTree[1.0, Empty, Empty] }
    it { BTree['s', Empty, Empty] }
    it { BTree[ComparableItem.new, Empty, Empty] }
    it { lambda { BTree[Object.new, Empty, Empty] }.must_raise TypeError }
    it { lambda { Node[Empty, nil] }.must_raise TypeError }

    describe 'named field' do
      Named = Algebrick.type do
        fields! a: Integer, b: Object
      end

      it { -> { Named[:a, 1] }.must_raise TypeError }
      it { Named[1, :a][:a].must_equal 1 }
      it { Named[1, :a][:b].must_equal :a }
      it { Named[a: 1, b: :a][:a].must_equal 1 }
      it { Named[b: :a, a: 1][:a].must_equal 1 }
      it { Named[a: 1, b: :a][:b].must_equal :a }
      it { Named[a: 1, b: 2].to_s.must_equal 'Named[a: 1, b: 2]' }
      it { Named[a: 1, b: 2].a.must_equal 1 }
      it { Named[a: 1, b: 2].b.must_equal 2 }
    end

    it { Leaf.from_hash(Leaf[1].to_hash).must_equal Leaf[1] }
    it { Named.from_hash(Named[1, :a].to_hash).must_equal Named[1, :a] }
    it do
      Named[1, Node[Leaf[1], Empty]].to_hash.
          must_equal algebrick: 'Named', a: 1, b: { algebrick: 'Node',
                                                    fields:    [{ algebrick: 'Leaf', fields: [1] },
                                                                { algebrick: 'Empty' }] }
    end
    it do
      Named.from_hash(Named[1, Node[Leaf[1], Empty]].to_hash).
          must_equal Named[1, Node[Leaf[1], Empty]]
    end

  end

  describe 'variant' do
    it { Tree.must_be_kind_of Algebrick::Type }
    it { Empty.must_be_kind_of Tree }
    it { Empty.a.must_equal :a }
    it { Leaf[1].must_be_kind_of Tree }
    it { Leaf[1].a.must_equal :a }
    it { Node[Empty, Empty].must_be_kind_of Tree }
    it { assert Empty.kind_of? List }

    it { assert Empty > List }
    it { assert Leaf > Tree }
    it { assert Node > Tree }

    it { assert Tree === Empty }
    it { assert Tree === Leaf[1] }

    describe 'inherit behavior deep' do
      module Deep
        B1 = Algebrick.type
        B2 = Algebrick.type
        A1 = Algebrick.type { variants B1, B2 }
        A2 = Algebrick.type
        A  = Algebrick.type { variants A1, A2 }

        module A
          def a
            :a
          end
        end
      end

      it { Deep::B1.a.must_equal :a }
      it { Deep::B1 > Deep::A }
    end

    describe 'a klass as a variant' do
      MaybeString = Algebrick.type { variants Empty, String }
      it { 'a'.must_be_kind_of MaybeString }
    end
  end

  describe 'product_variant' do
    it { List[1, Empty].must_be_kind_of Algebrick::Value }
    it { List.must_be_kind_of Algebrick::Type }

    it { List[1, Empty].must_be_kind_of List }
    it { List[1, List[1, Empty]].must_be_kind_of List }
    it { Empty.must_be_kind_of List }

    it { assert List[1, Empty] == List[1, Empty] }
    it { assert List[1, Empty] != List[2, Empty] }
    it { assert List === List[1, Empty] }
    it { assert List === Empty }
    it { assert List[1, Empty].kind_of? List }
  end

  describe '#depth' do
    it do
      tree = Node[Node[Empty, Leaf[1]], Leaf[1]]
      tree.depth.must_equal 3
    end
    it do
      tree = Node[Empty, Leaf[1]]
      tree.depth.must_equal 2
    end
    it do
      tree = Empty
      tree.depth.must_equal 0
    end
  end

  describe '#sum' do
    it do
      tree = Node[Node[Empty, Leaf[1]], Leaf[1]]
      tree.sum.must_equal 2
    end
  end

  describe 'maybe' do
    None  = Algebrick.type
    Some  = Algebrick.type { fields Object }
    Maybe = Algebrick.type { variants None, Some }

    module Maybe
      def maybe(&block)
        case self
        when None
        when Some
          block.call self.value
        end
      end
    end

    it { refute None.maybe { true } }
    it { assert Some[nil].maybe { true } }
  end

  #describe 'parametrized types' do
  #  types = type_def do
  #    maybe[:v] === none | some(:v)
  #    tree[:v] === tip | tree(:v, tree, tree)
  #  end
  #
  #  maybe, none, some, tree, tip = types
  #
  #  p [maybe, none, some, tree, tip]
  #  maybe_integer = maybe[Integer]
  #  puts tree[Integer]
  #
  #  #puts some[Integer][1]
  #end

  extend Algebrick::Matching
  include Algebrick::Matching

  describe 'matchers' do
    it 'assigns' do
      m = ~Empty
      m === 2
      m.assigns.must_equal [nil]
      m === Empty
      m.assigns.must_equal [Empty]

      m = ~String.to_m
      m === 2
      m.assigns.must_equal [nil]
      m === 'a'
      m.assigns.must_equal %w(a)

      m = ~Leaf.(~any)
      m === Leaf[5]
      m.assigns.must_equal [Leaf[5], 5]
      m === Leaf[3]
      m.assigns.must_equal [Leaf[3], 3]

      m = BTree.(:value)
      m === BTree[1, Empty, Empty]
      m.assigns.must_equal [1]

      m = BTree.(value: ~any)
      m === BTree[1, Empty, Empty]
      m.assigns.must_equal [1]
    end

    it 'assigns in case' do
      case Leaf[5]
      when m = ~Leaf.(~any)
        m.assigns.must_equal [Leaf[5], 5]
        m.assigns do |leaf, value|
          leaf.must_equal Leaf[5]
          value.must_equal 5
        end
      else
        raise
      end
    end

    describe 'match' do
      it 'returns value from executed block' do
        Algebrick.match(Empty, Empty >-> { 1 }).must_equal 1
      end

      it 'passes assigned values' do
        v = Algebrick.match Leaf[5],
                            Leaf.(~any).case { |value| value }
        v.must_equal 5

        v = Algebrick.match Leaf[5],
                            Leaf.(~any) => -> value { value }
        v.must_equal 5
      end

      it 'raises when no match' do
        -> { Algebrick.match Empty,
                             Leaf.(any) >-> {} }.must_raise RuntimeError
      end

      it 'does not pass any values when no matcher' do
        Algebrick.match(Empty, Empty >-> *a { a }).must_equal []
      end
    end

    describe '#to_s' do
      [Empty.to_m,
       # leaf(Object)
       ~Leaf.(Integer),
       ~Empty.to_m,
       any,
       ~any,
       Leaf.(any),
       ~Leaf.(any),
       Node.(Leaf.(any), any),
       ~Node.(Leaf.(any), any),
       ~Leaf.(1) | Leaf.(~any),
       ~Leaf.(1) ^ Leaf.(~any),
       ~Leaf.(1) & Leaf.(~any)
      ].each do |matcher|
        it matcher.to_s do
          eval(matcher.to_s).must_equal matcher
        end
      end
    end

    { Empty.to_m                           => Empty,
      any                                  => Empty,
      any                                  => Leaf[1],

      Empty                                => Empty,
      Empty.to_m                           => Empty,

      Leaf                                 => Leaf[1],
      Leaf.(any)                           => Leaf[5],
      Leaf.(~any)                          => Leaf[5],

      Node                                 => Node[Empty, Empty],
      Node.(any, any)                      => Node[Leaf[1], Empty],
      Node.(Empty, any)                    => Node[Empty, Leaf[1]],
      Node.(Leaf.(any), any)               => Node[Leaf[1], Empty],
      Node.(Leaf.(any), any)               => Node[Leaf[1], Empty],

      Tree.to_m                            => Node[Leaf[1], Empty],
      Tree.to_m                            => Node[Leaf[1], Empty],
      Node                                 => Node[Leaf[1], Empty],

      Tree & Leaf.(_)                      => Leaf[1],
      Empty | Leaf.(_)                     => Leaf[1],
      Empty | Leaf.(_)                     => Empty,
      Empty ^ Leaf.(_)                     => Leaf[1],
      Empty ^ Leaf.(_)                     => Empty,
      !Empty & Leaf.(_)                    => Leaf[1],
      Empty & !Leaf.(_)                    => Empty,

      Array.()                             => [],
      Array.(1)                            => [1],
      Array.(Empty, Leaf.(-> v { v > 0 })) => [Empty, Leaf[1]],
      Array.(TrueClass)                    => [true],

    }.each do |matcher, value|
      it "#{matcher} === #{value}" do
        assert matcher === value
      end
    end
  end

  it {
    assert List.to_m === Empty
    assert List === Empty
    assert List.to_m === List[1, Empty]
    assert List === List[1, Empty]
    assert List.(1, _) === List[1, Empty]
    refute List.(_, _) === Empty
  }

  describe 'and-or-xor matching' do
    def assert_assigns(matcher, values)
      matcher.assigns.must_equal values
      matcher.assigns { |*assigns| assigns.must_equal values }
    end

    it do
      m = ~Leaf.(1) | ~Leaf.(~any)
      assert m === Leaf[1]
      assert_assigns m, [Leaf[1], nil, nil]
    end
    it do
      m = ~Leaf.(1) | ~Leaf.(~any)
      assert m === Leaf[2]
      assert_assigns m, [nil, Leaf[2], 2]
    end
    it do
      m = ~Leaf.(->(v) { v > 1 }) & Leaf.(~any)
      assert m === Leaf[2]
      assert_assigns m, [Leaf[2], 2]
    end
    it do
      m = ~Leaf.(1) ^ ~Leaf.(~any)
      assert m === Leaf[1]
      assert_assigns m, [Leaf[1], nil]
    end
    it do
      m = ~Leaf.(~->(v) { v > 1 }.to_m) ^ ~Leaf.(1)
      assert m === Leaf[1]
      assert_assigns m, [Leaf[1], nil]
    end
    it do
      m = ~Leaf.(1) ^ ~Leaf.(~any)
      assert m === Leaf[2]
      assert_assigns m, [Leaf[2], 2]
    end
  end

  describe 'equality' do
    data = (0..1).map do
      [Empty,
       Leaf[1],
       Node[Empty, Leaf[1]],
       Node[Node[Empty, Leaf[1]], Leaf[1]]]
    end
    data[0].zip(data[1]).each do |tree1, tree2|
      it "equals #{tree1}" do
        refute tree1.object_id == tree2.object_id, [tree1.object_id, tree2.object_id] unless tree1 == Empty
        assert tree1 == tree2
      end
    end
  end

  describe 'list' do
    it { List.(any, any) === List[1, Empty] }
    it { List.(any, List) === List[1, Empty] }
  end

  #describe 'binary tree' do
  #  type_def { b_tree === tip | b_node(Object, b_tree, b_tree) }
  #end

end


#require 'benchmark'
#
#include Algebrick
#
#class None < Atom
#end
#
#class Some < Product
#  fields Object
#end
#
#Maybe = Variant.new do
#  variants None, Some
#end
#count = 1000_000
#
#Benchmark.bmbm(10) do |b|
#  b.report('nil') do
#    count.times do
#      v = [Object.new, nil].sample
#      case v
#      when Object
#        true
#      when nil
#        false
#      end
#    end
#  end
#  b.report('Maybe') do
#    count.times do
#      v = [Some[Object.new], None].sample
#      case v
#      when Some
#        true
#      when Maybe
#        false
#      end
#    end
#  end
#
#
#end
