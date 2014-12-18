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
  # fix module to re-include itself to where it was already included when a module is included into it
  #noinspection RubySuperCallWithoutSuperclassInspection
  module Reclude
    def included(base)
      included_into << base
      super(base)
    end

    def include(*modules)
      super(*modules)
      modules.reverse.each do |module_being_included|
        included_into.each do |mod|
          mod.send :include, module_being_included
        end
      end
    end

    private

    def included_into
      @included_into ||= []
    end
  end
end
