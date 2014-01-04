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
    end
  end
end
