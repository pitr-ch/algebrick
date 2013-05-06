# Algebrick

Is a small gem providing algebraic types and pattern matching on them for Ruby.

## Quick example with Maybe type

{include:file:doc/maybe.out.rb}

## Algebraic types: what is it?

If you ever read something about Haskell that you probably know:

    data Tree = Empty
              | Leaf Int
              | Node Tree Tree

which is an algebraic type. This snippet defines type `Tree` which has 3 possible values:
`Empty`, `Leaf` with and extra value of type `Int`, `Node` with two values of type `Tree`. 
See {https://en.wikipedia.org/wiki/Algebraic_data_type}.

Same thing can be defined with this gem:

{include:file:doc/tree1.out.rb}

There are 4 kinds of algebraic types in Algebrick gem:

-   **Atom** a type that has only one value e.g. `Empty`.
-   **Product** a type that has a set nuber of fields with given type e.g. `Leaf(Integer)`
-   **Variant** a type that does have set number of variants e.g. `Tree(Empty | Leaf(Integer) | Node(Tree, Tree)`.
    It means that values of `Empty`, `Leaf[1]`, `Node[Empty, Empry]` have all type `Tree`.
-   **ProductVariant** will be created when a recursive type like `list === empty | list(Object, list)` is defined.
    `List` has two variants `Empty` and itself simultaneously it has fields as product type.

### Type definition

{include:file:doc/type_def.out.rb}

### Value creation

{include:file:doc/values.out.rb}

### Extending behavior

{include:file:doc/extending_behavior.out.rb}

### Pattern matching

Algebraic matchers are helper objects to match algebraic objects and others with
`#===` method based on theirs initialization values.

{include:file:doc/pattern_matching.out.rb}

## What is it good for?

### Null Object Pattern

see {http://en.wikipedia.org/wiki/Null_Object_pattern#Ruby}.

{include:file:doc/null.out.rb}

### TODO

-   Definition of messages between processes
-   Massage matching in Actor pattern
-   Menu model

        module Menu
          type_def do
            menu === delimiter | item(String) | empty | menu(value: menu, next: menu)
          end
        end


-   modeling any data (replace struct, small classes)

        type_def { cmd_result === success(out: String, err: String) | failure(code: Integer, out: String, err: String) }


-   Pretty print example, see {http://homepages.inf.ed.ac.uk/wadler/papers/prettier/prettier.pdf}

