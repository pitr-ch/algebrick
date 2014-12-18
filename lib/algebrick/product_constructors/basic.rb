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
  module ProductConstructors
    class Basic < Abstract
      def to_s
        "#{self.class.type.name}[" +
            fields.map(&:to_s).join(', ') + ']'
      end

      def pretty_print(q)
        q.group(1, "#{self.class.type.name}[", ']') do
          fields.each_with_index do |value, i|
            if i == 0
              q.breakable ''
            else
              q.text ','
              q.breakable ' '
            end
            q.pp value
          end
        end
      end

      def self.type=(type)
        super(type)
        raise if type.field_names?
      end

      def update(fields)
        type[*fields]
      end
    end
  end
end
