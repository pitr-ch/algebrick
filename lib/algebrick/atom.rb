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
  # Representation of Atomic types
  class Atom < Type
    include Value

    def initialize(name, &block)
      super name, &block
      extend self
    end

    def to_m
      Matchers::Atom.new self
    end

    def be_kind_of(type)
      extend type
    end

    def ==(other)
      self.equal? other
    end

    def type
      self
    end

    def to_s
      name || 'nameless-atom'
    end

    def pretty_print(q)
      q.text to_s
    end
  end
end
