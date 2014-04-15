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
Power    = BinaryOperator.create(:**)
Root     = Function.create(Proc.new { |a, b| a**(1.0/b) }, 2)
Log = Function.create(lambda do |x, base|
         return Math.log(x) if base.nil?
         return Math.log(x, base)
      end, 2) do
   def input_label(i)
      i == 0 ? 'in' : 'base'
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
ATan2= Function.create(::Math.method(:atan2), 2)

Sinh  = Function.create(::Math.method(:sinh), 1)
Cosh  = Function.create(::Math.method(:cosh), 1)
Tanh  = Function.create(::Math.method(:tanh), 1)
ASinh = Function.create(::Math.method(:asinh), 1)
ACosh = Function.create(::Math.method(:acosh), 1)
ATanh = Function.create(::Math.method(:atanh), 1)

end

end

end
