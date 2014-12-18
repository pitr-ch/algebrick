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
  module FieldMethodReaders
    def field_names
      @field_names or raise TypeError, "field names not defined on #{self}"
    end

    def field_names?
      !!@field_names
    end

    def add_field_method_reader(field)
      raise TypeError, 'no field names' unless field_names?
      raise ArgumentError, "no field name #{field}" unless field_names.include? field
      raise ArgumentError, "method #{field} already defined" if instance_methods.include? field
      define_method(field) { self[field] }
      self
    end

    def add_field_method_readers(*fields)
      fields.each { |f| add_field_method_reader f }
      self
    end

    def add_all_field_method_readers
      add_field_method_readers *field_names
      self
    end
  end
end
