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
  module MatcherDelegations
    def ~
      ~to_m
    end

    def &(other)
      to_m & other
    end

    def |(other)
      to_m | other
    end

    def !
      !to_m
    end

    def case(&block)
      to_m.case &block
    end

    def >>(block)
      to_m >> block
    end

    def >(block)
      to_m > block
    end
  end
end
