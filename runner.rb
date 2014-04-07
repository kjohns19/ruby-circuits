#!/usr/bin/ruby

require_relative 'circuit'
require_relative 'component/all_components'

# Add function to get a list of all subclasses of a class
class Class
   def subclasses
      ObjectSpace.each_object(Class).select { |klass| klass < self }
   end
end

def update_loop(circuit)
   def print_info(circuit)
      circuit.components.each do |comp|
         puts "Component: #{comp.class}"
         puts "Inputs: #{comp.inputs_current.to_s}"
         puts "Outputs: #{comp.outputs.to_s}"
         puts
      end
   end

   loop do
      break unless circuit.has_updates?
      print_info(circuit)
      yield if block_given?
      gets
      puts "---------- UPDATING ----------\n\n"
      circuit.update { print_info(circuit) }
   end
   puts "---------- FINISHED ----------\n\n"
   print_info(circuit)
   yield if block_given?
end

include Circuits

#puts Component.subclasses.inspect

circuit = Circuits::Circuit.new

const = Circuits::Input::Constant.new(circuit)
const.output_count = 3
const.values = ["Hello", " ", "World"]

add = Circuits::Math::Add.new(circuit)
add.input_count = 3
3.times { |i| add.connect_input(i, const, i) }

update_loop(circuit)

require 'irb'

IRB.start

=begin
class Adder < Component
   def initialize(circuit)
      super(3, 2, circuit)
   end

   def update_outputs
      in1 = inputs_current[0]
      in2 = inputs_current[1]
      carry = inputs_current[2]

      in1 ||= 0
      in2 ||= 0
      carry ||= 0

      outputs[0] = (in1+in2+carry)%2
      outputs[1] = (in1+in2+carry)/2
   end
end
def to_binary(number, bits=8)
   arr = Array.new(bits)
   arr.fill(0)
   bits.times do |i|
      arr[i] = number % 2
      number /= 2
   end
   return arr
end

def to_number(array)
   number = 0
   array.reverse_each do |n|
      number *= 2
      number += n
   end
   return number
end

bits = 8

num1 = Circuits::Input::Constant.new(to_binary(25, bits), circuit)
num2 = Circuits::Input::Constant.new(to_binary(123, bits), circuit)

adders = []

last = nil

bits.times do |i|
   adder = Adder.new(circuit)
   adder.connect_input(0, num1, i)
   adder.connect_input(1, num2, i)
   adder.connect_input(2, last, 1) unless last.nil?

   last = adder
   adders << adder
end

update_loop(circuit) do
   arr = []
   adders.each do |a|
      arr << a.outputs[0]
      #puts "Value: #{a.outputs[0]} (Carry #{a.outputs[1]})"
   end
   puts "Result: #{to_number(arr)}"
end
=end
