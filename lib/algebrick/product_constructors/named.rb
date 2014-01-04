module Algebrick
  module ProductConstructors
    class Named < Abstract
      def to_s
        "#{self.class.type.name}[" +
            type.field_names.map { |name| "#{name}: #{self[name].to_s}" }.join(', ') +']'
      end

      def pretty_print(q)
        q.group(1, "#{self.class.type.name}[", ']') do
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
        end
      end

      def to_hash
        type.field_names.inject({}) { |h, name| h.update name => self[name] }
      end

      alias_method :to_h, :to_hash

      def self.type=(type)
        super(type)
        raise unless type.field_names?
      end
    end
  end
end
