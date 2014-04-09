require_relative 'function'

# Main module for all circuit classes
module Circuits

# Module for bitwise functions
module Bitwise

# Basic bitwise functions
And  = BinaryOperator.create(:&)
Or   = BinaryOperator.create(:|)
XOr  = BinaryOperator.create(:^)
Nand = BinaryOperator.create(lambda {|a, b| ~(a & b)})
Nor  = BinaryOperator.create(lambda {|a, b| ~(a | b)})
XNor = BinaryOperator.create(lambda {|a, b| ~(a ^ b)})
Not  = Function.create(:~, 0)

ShiftLeft  = BinaryOperator.create(:<<)
ShiftRight = BinaryOperator.create(:>>)

end

end
