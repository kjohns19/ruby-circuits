require_relative '../circuit'

require_relative 'component'
require_relative 'wire'

module Circuits

class Circuit
   def serialize
      str = ""
      components.each do |comp|
         str+=comp.serialize
      end
      wires.each do |wire|
         str+=wire.serialize
      end
      updates.each do |delay, set|
         str+="update #{delay}"
         set.sort { |a,b| a.id <=> b.id }.each do |comp|
            str+=" #{comp.id}"
         end
         str+="\n"
      end
      return str
   end

   def self.deserialize(lines)
      circuit = Circuit.new

      line_num = 0
      loop do
         break if line_num >= lines.length
         line = lines[line_num]

         next if line.strip.empty?

         case line
         when /^component/
            component, read = Component.deserialize(lines[line_num..-1], circuit)
         when /^wire/
            wire = Wire.deserialize(line, circuit)
            read = 1
         when /^update/
            split = line.split
            delay = split[1].to_i
            split[2..-1].each do |i|
               circuit.update_next(circuit.components[i.to_i], delay)
            end
            read = 1
         else
            puts "Error: Invalid line \"#{line}\""
            return nil
         end
         line_num+=read unless read.nil?
      end

      circuit.components.each { |c| c.active = true }
      circuit.changed = false

      return circuit
   end
end

end
