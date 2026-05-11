ALU — Parameterized Arithmetic Logic Unit
A parameterized, synchronous ALU implemented and verified in Verilog.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

This is an 8-bit ALU that supports arithmetic and logical operations, written in Verilog. The design is parameterized so the data width and command width can be adjusted. A complete directed testbench was written to verify the design, and coverage was measured using Questa Simulator.

The ALU has two modes selected by a MODE pin:
Arithmetic mode — addition, subtraction, increment/decrement, comparison, multiply (with pre-shift or pre-increment), and signed addition/subtraction
Logical mode — AND, NAND, OR, NOR, XOR, XNOR, NOT, shift left/right, and rotate left/right

It also handles:
A carry-in input for add/subtract with carry
Operand validity checking via INP_VALID — raises an error if the wrong operands are driven for a given command
Clock enable (CE) — freezes outputs when deasserted
Asynchronous reset — clears all outputs
