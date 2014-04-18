require_relative 'function'

# Main module for all circuit classes
module Circuits

# Module for mathematical components
module Math

# Basic Arithmetic
Add      = BinaryOperator.create(:+)
Subtract = BinaryOperator.create(:-)
Multiply = BinaryOperator.create(:*)
Divide   = BinaryOperator.create(:/)
Modulus  = BinaryOperator.create(:%)
Power    = BinaryOperator.create(:**) do
   def input_label(i)
      i == 0 ? 'value' : 'exp'
   end
end
Root     = Function.create(lambda { |a, b| a**(1.0/b) }, 2) do
   def input_label(i)
      i == 0 ? 'value' : 'root'
   end
end
Log = Function.create(lambda do |x, base|
         puts "Hey! X = #{x}, B = #{base}"
         return Math.log(x) if base.nil?
         return Math.log(x, base)
      end, 2) do
   def input_label(i)
      i == 0 ? 'value' : 'base'
   end
end

# Trigonometry
module Trig

Degrees = Function.create(Proc.new { |i| i*180/Math::PI }, 1)
Radians = Function.create(Proc.new { |i| i*Math::PI/180 }, 1)

Sin  = Function.create(::Math.method(:sin), 1)
Cos  = Function.create(::Math.method(:cos), 1)
Tan  = Function.create(::Math.method(:tan), 1)
ASin = Function.create(::Math.method(:asin), 1)
ACos = Function.create(::Math.method(:acos), 1)
ATan = Function.create(::Math.method(:atan), 1)
ATan2= Function.create(::Math.method(:atan2), 2) do
   def input_label(i)
      i == 0 ? 'x' : 'y'
   end
end

Sinh  = Function.create(::Math.method(:sinh), 1)
Cosh  = Function.create(::Math.method(:cosh), 1)
Tanh  = Function.create(::Math.method(:tanh), 1)
ASinh = Function.create(::Math.method(:asinh), 1)
ACosh = Function.create(::Math.method(:acosh), 1)
ATanh = Function.create(::Math.method(:atanh), 1)

end

end

end
