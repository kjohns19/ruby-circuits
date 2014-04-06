require_relative 'function'

# Main module for all circuit classes
module Circuits

# Module for bitwise functions
module Bitwise


# Basic bitwise functions
# Variables:
#     inputs - The number of inputs (2-10 inclusive)
# Inputs:
#     in1-in10 - inputs. May be any values that respond to the following:
#                &, |, ^, ~, <<, and >>
# Outputs:
#     value - the operation (&, |, ^, etc) applied to each input
#             for example (using And): ((...((in1 & in2) & in3)...) & inN)
And  = BinaryOperator.create(:&)
Or   = BinaryOperator.create(:|)
XOr  = BinaryOperator.create(:^)
Nand = BinaryOperator.create(Proc.new {|a, b| ~(a & b)})
Nor  = BinaryOperator.create(Proc.new {|a, b| ~(a | b)})
XNor = BinaryOperator.create(Proc.new {|a, b| ~(a ^ b)})
Not  = Function.create(:~, 0)
ShiftLeft  = BinaryOperator.create(:<<)
ShiftRight = BinaryOperator.create(:>>)

end

end
