extend Algebrick::DSL                              # => main

# Types can be extended in dsl
type_def do
  maybe === none | some(Object)
  maybe do
    def maybe(&block)
      case self
      when None
      when Some
        block.call value
      end
    end
  end
end                                                # => [Maybe(None | Some), None, Some(Object)]

# or with usual module syntax
module Maybe
  def maybe2(&block)
    case self
    when None
    when Some
      block.call value
    end
  end
end                                                # => nil

# #maybe and #mayby2 methods are defined on both Maybe`s values None and Some
None.maybe { |_| raise 'never ever happens' }      # => nil
None.maybe2 { |_| raise 'never ever happens' }     # => nil
# block is called with the value
Some[1].maybe { |v| v*2 }                          # => 2
Some[1].maybe2 { |v| v*2 }                         # => 2

# when only a Some is extended
module Some
  def i_am
    true
  end
end                                                # => nil

begin
  None.i_am
rescue => e
  e
end
# => #<NoMethodError: undefined method `i_am' for None:Algebrick::Atom>
Some[1].i_am                                       # => true
