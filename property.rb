module Circuits

class Property
   attr_reader :label, :type, :bounds, :getter, :setter

   def self.create(label, type, getter, setter)
      klass = Class.new(Property)

      klass.class_eval %Q(
         def initialize(bounds)
            super(#{label.inspect}, #{type}, bounds,
                  #{getter.inspect}, #{setter.inspect})
         end
      )

      return klass
   end

   def initialize(label, type, bounds, getter, setter)
      @label = label
      @type = type
      @bounds = bounds
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
end

end
