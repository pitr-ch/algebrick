extend Algebrick::DSL

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
end

# or with usual module syntax
module Maybe
  def maybe2(&block)
    case self
    when None
    when Some
      block.call value
    end
  end
end

# #maybe and #mayby2 methods are defined on both Maybe`s values None and Some
None.maybe { |_| raise 'never ever happens' }
None.maybe2 { |_| raise 'never ever happens' }
# block is called with the value
Some[1].maybe { |v| v*2 }
Some[1].maybe2 { |v| v*2 }

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
