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
      used_by << base
      super(base)
    end

    def extended(base)
      used_by << base
      super(base)
    end

    def include(*modules)
      super(*modules)
      modules.reverse.each do |module_being_included|
        used_by.each do |mod|
          mod.send :include, module_being_included
        end
      end
    end

    private

    def used_by
      @used_by ||= []
    end
  end
end
