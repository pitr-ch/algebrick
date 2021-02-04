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
  #noinspection RubyInstanceMethodNamingConvention
  module TypeCheck
    # FIND: type checking of collections?

    def Type?(value, *types)
      types.any? do |t|
        value.is_a?(t) || value.class.name.objectize.ancestors.include?(t)
      end
    end

    def Type!(value, *types)
      Type?(value, *types) or
          TypeCheck.error(value, 'is not', types)
      value
    end

    def Match?(value, *types)
      types.any? { |t| t === value }
    end

    def Match!(value, *types)
      Match?(value, *types) or
          TypeCheck.error(value, 'is not matching', types)
      value
    end

    def Child?(value, *types)
      Type?(value, Class) &&
          types.any? { |t| value <= t }
    end

    def Child!(value, *types)
      Child?(value, *types) or
          TypeCheck.error(value, 'is not child', types)
      value
    end

    private

    def self.error(value, message, types)
      raise TypeError,
            "Value (#{value.class}) '#{value}' #{message} any of: #{types.join('; ')}."
    end
  end

  class ::String
    def objectize
      self.split("::").reduce(Object) do |o, token|
        /(.*)\(.*\)/ =~ token
        o.const_get($1 || token)
      end
    end
  end
end
