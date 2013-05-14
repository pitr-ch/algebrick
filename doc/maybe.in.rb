# load DSL for type definition
extend Algebrick::DSL
# define a Maybe type, which has two possible values:
# None or Some caring a value of Object type
type_def { maybe === none | some(Object) }
# Maybe, None and Some are now defined
[Maybe, None, Some]

# access #match and #any methods for pattern matching
extend Algebrick::Matching

match None,
      None >> nil,
      # ~ will match value of Some and pass it to the block
      Some.(~any) --> value { value }

match Some[1],
      None >> nil,
      Some.(~any) --> value { value*2 }

# lets add some method to the Maybe type
module Maybe
  def maybe(&block)
    case self
    when None
    when Some
      block.call value
    end
  end
end

# #maybe method is now defined on both None and Some
None.maybe { |_| raise 'never ever happens' }
# block is called with the value
Some[1].maybe { |v| v*2 }
