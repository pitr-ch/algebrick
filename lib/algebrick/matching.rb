#  Copyright 2013 Petr Chalupa <git+algebrick@pitr.ch>
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
