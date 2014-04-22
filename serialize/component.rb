require_relative '../component/component'

module Circuits

class Component
   def serialize
      str = "component #{self.class.name}\n"
      str+= "   position= #{position.inspect}\n"
      self.class.properties.each do |property|
         str+= "   #{property.setter} #{property.get(self).inspect}\n"
      end

      inputs_current.each_with_index do |input, i|
         str+= "   in #{i} #{input.inspect}\n"
      end

      outputs.each_with_index do |output, i|
         str+= "   out #{i} #{output.inspect}\n"
      end

      str+="end\n"
      return str
   rescue Exception => e
      puts "An error occurred while serializing component"
      puts "Error: #{e}"
      puts e.backtrace
      puts "Component: #{self}"
      return "COMPONENT ERROR HERE\n"
   end

   def self.deserialize(lines, circuit)
      match = lines[0].match /^\s*component\s+(?<class>.*)$/
      return nil, 1 if match.nil?

      klass = match[:class].split("::").inject(::Object) { |o, c| o.const_get c }

      comp = klass.new(circuit) do |comp|
         comp.active = false
      end

      read = 1
      ended = false

      lines[1..-1].each do |line|
         break if ended
         case line
         when /\s*end\s*$/
            ended = true
         when /^\s*(in|out)\s+(\d+)\s+(.*)\s*$/
            func = ($1 == 'in') ? :inputs_current : :outputs
            index = $2.to_i
            value = eval($3)
            comp.send(func)[index] = value
         when /^\s*([^\s]+)\s+(.*)\s*$/
            setter = $1.to_sym
            value = eval($2)
            comp.send(setter, value)
         else
            puts "Error: Invalid line while reading component \"#{line}\""
         end
         read+=1
      end
      unless ended
         puts "Expected end while reading component"
      end
      return comp, read
   rescue Exception => e
      puts "An error occurred while deserializing component"
      puts "Error: #{e}"
      puts e.backtrace
      return nil, 1
   end
end

end
