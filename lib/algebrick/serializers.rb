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
  module Serializers

    require 'algebrick/serializers/abstract'
    require 'algebrick/serializers/abstract_to_hash'
    require 'algebrick/serializers/chain'
    require 'algebrick/serializers/strict_to_hash'
    require 'algebrick/serializers/benevolent_to_hash'

  end
end
