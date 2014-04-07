module Circuits

class Property
   attr_reader :label, :type, :values, :getter, :setter

   def self.create(label, type, getter, setter)
      klass = Class.new(Property)

      klass.class_eval %Q(
         def initialize(values)
            super(#{label.inspect}, #{type}, values,
                  #{getter.inspect}, #{setter.inspect})
         end
      )

      return klass
   end

   def initialize(label, type, values, getter, setter)
      @label = label
      @type = type
      @values = values
      @getter = getter
      @setter = setter
   end

   def get(component)
      begin
         component.send(@getter)
      rescue
         nil
      end
   end

   def set(component, value)
      begin
         component.send(@setter, value)
      rescue
         nil
      end
   end

   def to_s
      "#{self.class.name} - #{values}"
   end
end

end
