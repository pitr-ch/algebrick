require 'bundler/setup'
require 'minitest/autorun'
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

  #type_def do
  #  maybe === none | some(Object)

  #  message === success | failure
  #  sucess === int(Integer) | str(String)
  #  failure === error | str_error(String)

  #user = user(String, address) do
  #  def name
  #    fields[0]
  #  end
  #
  #  def address
  #    fields[1]
  #  end
  #end
  #
  #psc     = psc(String) do
  #  REG = /\d{5}/
  #
  #  def initialize(*fields)
  #    raise TypeError unless fields[0] =~ REG
  #  end
  #
  #  def schema
  #    super << { pattern: REG.to_s }
  #  end
  #end
  #
  ##                 street, num,      city
  #address = address(street(String), street_number(Integer), city(String), psc)
  #
  #message1 === user
  #
  #User['pepa',
  #     Adress[
  #         Street['Stavebni'],
  #         StreetNumber[5],
  #         City['Brno']]]
  #
  #{ user: ['pepa',
  #         { address: [{ street: 'Stavebni' },
  #                     { street_number: 5 }] }] }

  #sucess === int(Integer) | str(String)
  #failure === error | str_error(String)
  #message === success | failure


  #list === empty | list_item(Integer, list)
  #end

  #Empty = Algebrick::Atom.new
  #Leaf  = Algebrick::Product.new(Integer)
  #Tree  = Algebrick::Variant.allocate
  #Node  = Algebrick::Product.new(Tree, Tree)
  #Tree.send :initialize, Empty, Leaf, Node do
  #  def a
  #    :a
  #  end
  #end
  #List = Algebrick::ProductVariant.allocate
  #List.send :initialize, [Integer, List], [Empty, List]

  extend Algebrick::DSL

  type_def do
    tree === empty | leaf(Integer) | node(tree, tree)
    tree do
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

    list === empty | list(Integer, list)
  end

  Empty = self::Empty
  Node  = self::Node
  Leaf  = self::Leaf
  Tree  = self::Tree
  List  = self::List

  describe 'type definition' do
    module Asd
      Algebrick.type_def self do
        b === c | d
      end
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
    it { lambda { Node[Empty, nil] }.must_raise TypeError }

    describe 'named field' do
      type_def { named(a: Integer, b: Object) }
      Named = self::Named
      Named.add_all_field_method_accessors
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
    it { Named[1, Leaf[1]].to_hash.must_equal 'Named' => { a: 1, b: { 'Leaf' => [1] } } }
    it { Named.from_hash(Named[1, Leaf[1]].to_hash).must_equal Named[1, Leaf[1]] }

  end

  describe 'variant' do
    it { Tree.must_be_kind_of Algebrick::Type }
    it { Empty.must_be_kind_of Tree }
    it { Empty.a.must_equal :a }
    it { Leaf[1].must_be_kind_of Tree }
    it { Leaf[1].a.must_equal :a }
    it { Node[Empty, Empty].must_be_kind_of Tree }
    #it { assert Empty.kind_of? List }

    it { assert Tree === Empty }
    it { assert Tree === Leaf[1] }

    describe 'inherit behavior deep' do
      type_def do
        a === a1 | a2
        a1 === b1 | b2
        a do
          def a
            :a
          end
        end
      end

      it { self.class::B1.a.must_equal :a }
    end

    describe 'a klass as a variant' do
      MaybeString = Algebrick::Variant.new Empty, String
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
    type_def do
      maybe === none | some(Object)
      maybe do
        def maybe(&block)
          case self
          when None
          when Some
            block.call self.value
          end
        end
      end
    end

    None = self::None
    Some = self::Some

    it { refute None.maybe { true } }
    it { assert Some[nil].maybe { true } }
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
        Algebrick.match(Empty, Empty.to_m.case { 1 }).must_equal 1
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
                             Leaf.(any).case {} }.must_raise RuntimeError
      end

      it 'does not pass any values when no matcher' do
        Algebrick.match(Empty, Empty => -> *a { a }).must_equal []
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

  describe 'and-or matching' do
    it do
      m = ~Leaf.(1) | ~Leaf.(~any)
      assert m === Leaf[1]
      m.assigns.must_equal [Leaf[1], nil, nil]
    end
    it do
      m = ~Leaf.(1) | ~Leaf.(~any)
      assert m === Leaf[2]
      m.assigns.must_equal [nil, Leaf[2], 2]
    end
    it do
      m = ~Leaf.(->(v) { v > 1 }) & Leaf.(~any)
      assert m === Leaf[2]
      m.assigns.must_equal [Leaf[2], 2]
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

  describe 'binary tree' do
    type_def { b_tree === tip | b_node(Object, b_tree, b_tree) }
  end

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
