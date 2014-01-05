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
  # Return any modules we +extend+
  def extended_modules
    class << self
      self
    end.included_modules
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

    it { Named[1, :a].to_hash.must_equal a: 1, b: :a }
    it { Named[1, Node[Empty, Empty]].to_hash.must_equal a: 1, b: Node[Empty, Empty] }
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

  describe 'inspecting' do
    let :tree do
      tree = Node[Leaf[1], Node[Leaf[2], Empty]]
      tree = Node[tree, tree]
      Node[tree, tree]
    end

    it { tree.to_s.must_equal 'Node[Node[Node[Leaf[1], Node[Leaf[2], Empty]], Node[Leaf[1], Node[Leaf[2], Empty]]], Node[Node[Leaf[1], Node[Leaf[2], Empty]], Node[Leaf[1], Node[Leaf[2], Empty]]]]' }
    it { tree.inspect.must_equal tree.to_s }
    it do
      tree.pretty_inspect.must_equal <<-TXT
Node[
 Node[
  Node[Leaf[1], Node[Leaf[2], Empty]],
  Node[Leaf[1], Node[Leaf[2], Empty]]],
 Node[
  Node[Leaf[1], Node[Leaf[2], Empty]],
  Node[Leaf[1], Node[Leaf[2], Empty]]]]
      TXT
    end

    let :named do
      n = Named[-1, 'as'*40]
      4.times do |i|
        n = Named[i, n]
      end
      n
    end

    it { named.to_s.must_equal 'Named[a: 3, b: Named[a: 2, b: Named[a: 1, b: Named[a: 0, b: Named[a: -1, b: asasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasas]]]]]' }
    it { named.inspect.must_equal named.to_s }
    it do
      named.pretty_inspect.must_equal <<-TXT
Named[
 a: 3,
 b:
  Named[
   a: 2,
   b:
    Named[
     a: 1,
     b:
      Named[
       a: 0,
       b:
        Named[
         a: -1,
         b:
          "asasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasasas"]]]]]
      TXT
    end


  end

  describe 'module including' do
    type = Algebrick.type { fields! Numeric }
    type.module_eval do
      include Comparable
      def <=>(other)
        value <=> other.value
      end
    end
    it 'compares' do
      type
      assert type[1] < type[2]
    end
  end


  describe 'tree' do
    it { assert Leaf > Tree }
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
    Maybe = Algebrick.type do
      variants None = atom,
               Some = type { fields Object }
    end

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

  describe 'parametrized types' do

    PTree = Algebrick.type(:v) do |p_tree|
      PEmpty = atom
      PLeaf  = type(:v) { fields value: :v }
      PNode  = type(:v) { fields left: p_tree, right: p_tree }

      variants PEmpty, PLeaf, PNode
    end

    module PTree
      def depth
        match self,
              PEmpty >> 0,
              PLeaf >> 1,
              PNode.(~any, ~any) >-> left, right do
                1 + [left.depth, right.depth].max
              end
      end
    end

    PTree[String].module_eval do
      def glue
        match self,
              PEmpty >> '',
              PLeaf.(value: ~any) >-> v { v },
              PNode.(~any, ~any) >-> l, r { l.glue + r.glue }
      end
    end

    it { [PTree, PLeaf, PNode].all? { |pt| pt > Algebrick::ParametrizedType } }

    it { PLeaf[Integer].to_s.must_equal 'PLeaf[Integer](value: Integer)' }
    it { PNode[Integer].to_s.must_equal 'PNode[Integer](left: PTree[Integer], right: PTree[Integer])' }
    it { PTree[Integer].to_s.must_equal 'PTree[Integer](PEmpty | PLeaf[Integer] | PNode[Integer])' }

    it { PLeaf[Integer].is_a? PLeaf }
    it { PLeaf[Integer][1].is_a? PLeaf }

    it { PLeaf[Integer][1].is_a? Tree }
    it { PLeaf[Integer][1].to_s.must_equal 'PLeaf[Integer][value: 1]' }
    it { PLeaf[Integer][1].value.must_equal 1 }
    it { PNode[Integer][PEmpty, PLeaf[Integer][1]].is_a? Tree }

    it { PLeaf[Integer][2].depth.must_equal 1 }
    it do
      PTree[Object] # FIXME without this it does not work
      PLeaf[Object][2].depth.must_equal 1
    end
    it do
      PNode[Integer][PLeaf[Integer][2],
                     PEmpty].depth.must_equal 2
    end
    it do
      PTree[String]
      PNode[String][PLeaf[String]['a'],
                    PNode[String][PLeaf[String]['b'],
                                  PEmpty]].glue.must_equal 'ab'
      refute PTree[Object].respond_to? :glue
    end
  end

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
        r = Algebrick.match Empty,
                            Empty >-> { 1 }
        r.must_equal 1
        r = Algebrick.match(Empty,
                            on(Empty) { 1 })
        r.must_equal 1
      end

      it 'passes assigned values' do
        v = Algebrick.match Leaf[5],
                            Leaf.(~any).case { |value| value }
        v.must_equal 5

        v = Algebrick.match Leaf[5],
                            Leaf.(~any) => -> value { value }
        v.must_equal 5

        v = Algebrick.match(Leaf[5],
                            on(Leaf.(~any)) do |value|
                              value
                            end)
        v.must_equal 5
      end

      it 'raises when no match' do
        -> { Algebrick.match Empty,
                             Leaf.(any) >-> {} }.must_raise RuntimeError
      end

      it 'does not pass any values when no matcher' do
        Algebrick.match(Empty, on(Empty) { |*a| a }).must_equal []
      end
    end

    describe '#to_s' do
      [Empty.to_m,
       ~Leaf.(Integer),
       ~Empty.to_m,
       any,
       ~any,
       Leaf.(any),
       ~Leaf.(any),
       Node.(Leaf.(any), any),
       ~Node.(Leaf.(any), any),
       ~Leaf.(1) | Leaf.(~any),
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

      Tree & Leaf.(any)                    => Leaf[1],
      Empty | Leaf.(any)                   => Leaf[1],
      Empty | Leaf.(any)                   => Empty,
      !Empty & Leaf.(any)                  => Leaf[1],
      Empty & !Leaf.(any)                  => Empty,

      Array.()                             => [],
      Array.(1)                            => [1],
      Array.(Empty, Leaf.(-> v { v > 0 })) => [Empty, Leaf[1]],
      Array.(TrueClass)                    => [true],

      BTree.(value: any)                   => BTree[1, Empty, Empty],
      BTree.(value: 1)                     => BTree[1, Empty, Empty],
      Named.(b: false)                     => Named[a: 1, b: false],
      !Named.(b: false)                    => Named[a: 1, b: true],

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
    assert List.(1, any) === List[1, Empty]
    refute List.(any, any) === Empty
  }

  describe 'and-or matching' do
    def assert_assigns(matcher, values)
      matcher.assigns.must_equal values
      matcher.assigns { |*assigns| assigns.must_equal values }
    end

    it do
      m = ~Leaf.(->(v) { v > 1 }) & Leaf.(~any)
      assert m === Leaf[2]
      assert_assigns m, [Leaf[2], 2]
    end
    it do
      m = ~Leaf.(1) | ~Leaf.(~any)
      assert m === Leaf[1]
      assert_assigns m, [Leaf[1], nil]
    end
    it do
      m = ~Leaf.(~->(v) { v > 1 }.to_m) | ~Leaf.(1)
      assert m === Leaf[1]
      assert_assigns m, [Leaf[1], nil]
    end
    it do
      m = ~Leaf.(1) | ~Leaf.(~any)
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

  it 'multi assigns all fields' do
    match Node[Empty, Empty],
          (on ~Node do |(left, right)|
            [left, right].must_equal [Empty, Empty]
          end)
  end

  describe 'list' do
    it { List.(any, any) === List[1, Empty] }
    it { List.(any, List) === List[1, Empty] }
  end

  describe 'serializers' do
    describe 'strict' do
      let(:serializer) { Algebrick::Serializers::StrictToHash.new }

      it { serializer.generate(Empty).must_equal :algebrick_type => 'Empty' }
      it { serializer.generate(Leaf[1]).must_equal :algebrick_type => 'Leaf', :algebrick_fields => [1] }
      it { serializer.generate(PLeaf[Integer][1]).must_equal :algebrick_type => 'PLeaf[Integer]', :value => 1 }
      it { serializer.generate(Named[1, :a]).must_equal algebrick_type: 'Named', a: 1, b: :a }

      [Empty, Leaf[1], PLeaf[Integer][1], Named[1, :a]].each do |v|
        it "serializes and de-serializes #{v}" do
          serializer.parse(serializer.generate(v)).must_equal v
        end
      end
    end

    Person = Algebrick.type do |person|
      person::Name = type do |name|
        variants name::Normal   = type { fields String, String },
                 name::AbNormal = type { fields String, String, String }
      end

      person::Address = type do |address|
        variants address::Homeless = atom, address
        fields street: String,
               zip:    Integer
      end

      fields name:    person::Name,
             address: person::Address
    end

    transformations = [
        [{ name: %w(a b), address: 'homeless' },
         { algebrick_type: "Person",
           name:           { algebrick_type: "Person::Name::Normal", algebrick_fields: %w(a b) },
           address:        { algebrick_type: "Person::Address::Homeless" } },
         Person[Person::Name::Normal['a', 'b'], Person::Address::Homeless],
         "{\"name\":[\"a\",\"b\"],\"address\":\"homeless\"}"
        ],
        [{ name: %w(a b c), address: 'homeless', metadata: :ignored },
         { algebrick_type: "Person",
           name:           { algebrick_type: "Person::Name::AbNormal", algebrick_fields: %w(a b c) },
           address:        { algebrick_type: "Person::Address::Homeless" } },
         Person[Person::Name::AbNormal['a', 'b', 'c'], Person::Address::Homeless],
         "{\"name\":[\"a\",\"b\",\"c\"],\"address\":\"homeless\",\"metadata\":\"ignored\"}"
        ],
        [{ name: %w(a b c), address: { street: 'asd', zip: 15 } },
         { algebrick_type: "Person",
           name:           { algebrick_type: "Person::Name::AbNormal", algebrick_fields: %w(a b c) },
           address:        { algebrick_type: "Person::Address", street: "asd", zip: 15 } },
         Person[Person::Name::AbNormal['a', 'b', 'c'], Person::Address['asd', 15]],
         "{\"name\":[\"a\",\"b\",\"c\"],\"address\":{\"street\":\"asd\",\"zip\":15}}"
        ]
    ]

    describe 'benevolent' do
      let(:serializer) { Algebrick::Serializers::BenevolentToHash.new }

      it { serializer.generate(Empty).must_equal Empty }
      it { serializer.generate(Leaf[1]).must_equal Leaf[1] }

      it { serializer.parse(1, expected_type: Integer).must_equal 1 }
      it do
        [:empty, :Empty, 'empty', 'Empty'].each do |v|
          serializer.parse(v, expected_type: Empty).must_equal :algebrick_type => 'Empty'
        end
        [:p_empty, :PEmpty, 'p_empty', 'PEmpty'].each do |v|
          serializer.parse(v, expected_type: PEmpty).must_equal :algebrick_type => 'PEmpty'
        end
      end

      it { serializer.parse([1], expected_type: Leaf).must_equal :algebrick_type => 'Leaf', :algebrick_fields => [1] }
      it { serializer.parse({ a: 1, b: 's' }, expected_type: Named).must_equal :algebrick_type => 'Named', a: 1, b: 's' }

      transformations.each do |from, to, _|
        it { serializer.parse(from, expected_type: Person).must_equal to }
      end
    end

    describe 'chain' do
      let(:serializer) do
        Algebrick::Serializers::Chain.new(Algebrick::Serializers::StrictToHash.new,
                                          Algebrick::Serializers::BenevolentToHash.new)
      end

      transformations.each do |from, _, to|
        it { serializer.parse(from, expected_type: Person).must_equal to }
      end

      transformations.each do |_, to, from|
        it { serializer.generate(from).must_equal to }
      end
    end

    require 'algebrick/serializers/to_json'

    describe 'json' do
      let(:serializer) do
        Algebrick::Serializers::Chain.build Algebrick::Serializers::StrictToHash.new,
                                            Algebrick::Serializers::BenevolentToHash.new,
                                            Algebrick::Serializers::ToJson.new
      end

      transformations.each do |_, _, to, from|
        it do
          serializer.parse(from, expected_type: Person).must_equal to
        end
      end
    end
  end

end
