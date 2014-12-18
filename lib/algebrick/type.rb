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
  # Any Algebraic type defined by Algebrick is kind of Type
  class Type < Module
    include TypeCheck
    include Matching
    include MatcherDelegations
    include Reclude

    def initialize(name, &definition)
      super &definition
      @name = name
    end

    def name
      super || @name || 'NoName'
    end

    def to_m(*args)
      raise NotImplementedError
    end

    def ==(other)
      raise NotImplementedError
    end

    def be_kind_of(type)
      raise NotImplementedError
    end

    def to_s
      raise NotImplementedError
    end

    def inspect
      to_s
    end

    def match(value, *cases)
      Type! value, self
      super value, *cases
    end

    #def pretty_print(q) TODO
    #  raise NotImplementedError
    #end
  end
end
