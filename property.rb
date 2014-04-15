module Circuits

class Property
   attr_reader :label, :type, :values, :getter, :setter

   def inherit?
      @inherit
   end

   def self.create(label, type, getter, setter)
      klass = Class.new(Property)

      klass.class_eval %Q(
         def initialize(values, inherit = true)
            super(#{label.inspect}, #{type.inspect}, values,
                  #{getter.inspect}, #{setter.inspect}, inherit)
         end
      )

      return klass
   end

   def initialize(label, type, values, getter, setter, inherit = true)
      @label = label
      @type = type
      @values = values
      @getter = getter
      @setter = setter
      @inherit = inherit
   end

   def get(component)
      value = nil
      begin
         #puts "Calling getter #{@getter} on #{component}"
         value = component.send(@getter)
      rescue Exception => e
         puts "Error calling getter #{@getter} on #{component}"
         puts "Error: #{e}"
         puts e.backtrace
      end
      value = value.to_s if type == String
      return value
   end

   def set(component, value)
      value = value.to_s if type == String
      #puts "Calling setter #{@setter} with #{value.inspect} on #{component}"
      component.send(@setter, value)
   rescue Exception => e
      puts "Error calling setter #{@setter} with #{value} on #{component}"
      puts "Error: #{e}"
      puts e.backtrace
      nil
   end
end

end
