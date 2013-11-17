None  = Algebrick.type                             # => None
Some  = Algebrick.type { fields Object }           # => Some(Object)
Maybe = Algebrick.type { variants None, Some }     # => Maybe(None | Some)

# Types can be extended with usual module syntax
module Maybe
  def maybe(&block)
    case self
    when None
    when Some
      block.call value
    end
  end
end                                                # => nil

# #maybe method id defined on both values (None, Some) of Maybe
None.maybe { |_| raise 'never ever happens' }      # => nil
# block is called with the value
Some[1].maybe { |v| v*2 }                          # => 2

# when only subtypes are extended
module Some
  def i_am
    true
  end
end                                                # => nil

module None
  def i_am_not
    true
  end
end                                                # => nil

None.i_am rescue $!
# => #<NoMethodError: undefined method `i_am' for None:Algebrick::Atom>
None.i_am_not rescue $!                            # => true
Some[1].i_am rescue $!                             # => true
Some[1].i_am_not rescue $!
# => #<NoMethodError: undefined method `i_am_not' for Some[1]:#<Class:0x007fbfda8fe610>>
