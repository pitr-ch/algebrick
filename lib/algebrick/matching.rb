module Algebrick
  # include this module anywhere yoy need to use pattern matching
  module Matching
    def any
      Matchers::Any.new
    end

    def match(value, *cases)
      cases = if cases.size == 1 && cases.first.is_a?(Hash)
                cases.first
              else
                cases
              end

      cases.each do |matcher, block|
        return Matching.match_value matcher, block if matcher === value
      end
      raise "no match for (#{value.class}) '#{value}' by any of #{cases.map(&:first).join ', '}"
    end

    def on(matcher, value = nil, &block)
      matcher = if matcher.is_a? Matchers::Abstract
                  matcher
                else
                  matcher.to_m
                end
      raise ArgumentError, 'only one of block or value can be supplied' if block && value
      [matcher, value || block]
    end

    # FIND: #match! raise when match is not complete on a given type

    private

    def self.match_value(matcher, block)
      if block.kind_of? Proc
        if matcher.kind_of? Matchers::Abstract
          matcher.assigns &block
        else
          block.call
        end
      else
        block
      end
    end
  end

  include Matching
  extend Matching
end
