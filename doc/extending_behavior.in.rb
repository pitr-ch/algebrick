None  = Algebrick.type
Some  = Algebrick.type { fields Object }
Maybe = Algebrick.type { variants None, Some }

# Types can be extended with usual module syntax
module Maybe
  def maybe(&block)
    case self
    when None
    when Some
      block.call value
    end
  end
end

# #maybe method id defined on both values (None, Some) of Maybe
None.maybe { |_| raise 'never ever happens' }
# block is called with the value
Some[1].maybe { |v| v*2 }

# when only a Some is extended
module Some
  def i_am
    true
  end
end

begin
  None.i_am
rescue => e
  e
end
Some[1].i_am
