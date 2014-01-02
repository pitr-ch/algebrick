# Algebrick

It's a gem providing **algebraic types** and **pattern matching** and seamlessly integrating with standard features of Ruby.

-   Documentation: <http://blog.pitr.ch/algebrick>
-   Source: <https://github.com/pitr-ch/algebrick>
-   Blog: <http://blog.pitr.ch/blog/categories/algebrick/>

## Quick example

{include:file:doc/quick_example.out.rb}

## Algebraic types

Algebraic type is a kind of composite type, i.e. a type formed by combining other types.
In Haskell algebraic type looks like this:

    data Tree = Empty
              | Leaf Int
              | Node Tree Tree
			  
	depth :: Tree -> Int
	      depth Empty = 0
	      depth (Leaf n) = 1
	      depth (Node l r) = 1 + max (depth l) (depth r)
    
	depth (Node Empty (Leaf 5)) -- => 2

This snippet defines type `Tree` which has 3 possible values:

-  `Empty`
-  `Leaf` with and extra value of type `Int`
-  `Node` with two values of type `Tree` 

and function `depth` to calculate depth of a tree which is called on the last line and evaluates to `2`.

Same `Tree` type and `depth` method can be also defined with this gem as it was shown in {file:README_FULL.md#quick-example Quick Example}.

### Algebrick implementation

Algebrick distinguishes 4 kinds of algebraic types:

1.  **Atom** - type that has only one value, e.g. `Empty`.
2.  **Product** - type that has a set number of fields with given type, e.g. `Leaf(Integer)`
3.  **Variant** - type that is one of the set variants, e.g. `Tree(Empty | Leaf(Integer) | Node(Tree, Tree)`, meaning that values `Empty`, `Leaf[1]`, `Node[Empty, Empry]` have all type `Tree`.
4.  **ProductVariant** - will be created when a recursive type like `List(Empty | List(Integer, List))` is defined. `List` has two variants: `Empty` and itself. Simultaneously it has fields as a product type.

Atom type is implemented with {Algebrick::Atom} and the rest is implemented with {Algebrick::ProductVariant} which behaves differently based on what is set: fields, variants, or both.

More information can be found at <https://en.wikipedia.org/wiki/Algebraic_data_type>.

## Documentation

### Type definition

{include:file:doc/type_def.out.rb}

### Value creation

{include:file:doc/values.out.rb}

### Behaviour extending

{include:file:doc/extending_behavior.out.rb}

### Pattern matching

Pattern matching is implemented with helper objects defined in `ALgebrick::Matchers`.
They use standard `#===` method to match against values.

{include:file:doc/pattern_matching.out.rb}

### Parametrized types

{include:file:doc/parametrized.out.rb}

## What is it good for?

### Defining data structures

<!-- {include:file:doc/data.out.rb} -->

- Simple data structures like trees
- Whenever you find yourself to pass around too many fragile Hash-Array structures

_Examples are coming shortly._

### Serialization

Algebraic types also play nice with JSON serialization and de-serialization making it ideal for defining message-based cross-process communication.

{include:file:doc/json.out.rb}

### Message matching in Actor pattern

Just a small snippet how it can be used in Actor model world.

    class Worker < AbstractActor
      def initialize(executor)
        super()
        @executor = executor
      end

      def on_message(message)
        match message,
              Work.(~any, ~any) >-> actor, work do
                @executor.tell Finished[actor, work.call, self.reference]
              end
      end
    end

<!--
### Null Object Pattern

see {http://en.wikipedia.org/wiki/Null_Object_pattern#Ruby}.

{include:file:doc/null.out.rb}

This has advantage over a classical approach that the methods are defined
on one place, no need to track methods in two separate classes `User` and `NullUser`.
-->
