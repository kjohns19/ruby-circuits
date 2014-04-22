require_relative '../component/wire'

module Circuits

class Wire
   def serialize
      str = "wire #{comp_in.id}:#{input} #{comp_out.id}:#{output}"

      points[1..-2].each do |(x, y)|
         str+= " (#{x} #{y})"
      end
      str+="\n"

      return str
   rescue Exception => e
      puts "An error occurred while serializing wire"
      puts "Error: #{e}"
      puts e.backtrace
      puts "Wire: #{self}"
      return "WIRE ERROR HERE\n"
   end
   def self.deserialize(line, circuit)
      match = line.match(
         /^\s*wire (?<in_id>\d+):(?<in>\d+)\s+(?<out_id>\d+):(?<out>\d+)(?:\s+(?<points>.*))?$/)
      return nil if match.nil?

      comp_in = circuit.components[match[:in_id].to_i]
      comp_out = circuit.components[match[:out_id].to_i]

      wire = Circuits::Wire.new(comp_in, match[:in].to_i)

      match[:points].scan(/\((-?\d+)\s+(-?\d+)\)/).each do |x, y|
         x = x.to_i
         y = y.to_i
         wire.add([x, y])
      end

      wire.connect(comp_out, match[:out].to_i)
      return wire
   rescue Exception => e
      puts "An error occurred while deserializing wire"
      puts "Error: #{e}"
      puts e.backtrace
      return nil, 1
   end
end

end
