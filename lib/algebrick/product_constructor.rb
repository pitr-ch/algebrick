module Algebrick
  # A private class used for Product values creation
  class ProductConstructor
    include Value
    attr_reader :fields

    def initialize(*fields)
      if fields.size == 1 && fields.first.is_a?(Hash)
        fields = type.field_names.map { |k| fields.first[k] }
      end
      @fields = fields.zip(self.class.type.fields).map { |field, type| Type! field, type }.freeze
    end

    def to_s
      "#{self.class.type.name}[" +
          if type.field_names?
            type.field_names.map { |name| "#{name}: #{self[name].to_s}" }.join(', ')
          else
            fields.map(&:to_s).join(', ')
          end + ']'
    end

    def pretty_print(q)
      q.group(1, "#{self.class.type.name}[", ']') do
        if type.field_names?
          type.field_names.each_with_index do |name, i|
            if i == 0
              q.breakable ''
            else
              q.text ','
              q.breakable ' '
            end
            q.text name.to_s
            q.text ':'
            q.group(1) do
              q.breakable ' '
              q.pp self[name]
            end
          end
        else
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
    end

    def to_ary
      @fields
    end

    def to_a
      @fields
    end

    def to_hash
      { TYPE_KEY => self.class.type.name }.
          update(if type.field_names?
                   type.field_names.inject({}) { |h, name| h.update name => hashize(self[name]) }
                 else
                   { FIELDS_KEY => fields.map { |v| hashize v } }
                 end)
    end

    def ==(other)
      return false unless other.kind_of? self.class
      @fields == other.fields
    end

    def self.type
      @type || raise
    end

    def type
      self.class.type
    end

    def self.name
      @type.to_s
    end

    def self.to_s
      name
    end

    def self.type=(type)
      raise if @type
      @type = type
      include type
    end

    private

    def hashize(value)
      (value.respond_to? :to_hash) ? value.to_hash : value
    end
  end
end
