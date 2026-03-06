`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 19:09:38
// Design Name:
// Module Name: alu
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`include "riscv_defines.v"

module alu(
           input [31:0] a,
           input [31:0] b,
           input [3:0] alu_ctrl,

           output reg [31:0] result
       );

always @(*) begin
    case (alu_ctrl)
        `ALU_ADD:
            result = a + b;
        `ALU_SUB:
            result = a - b;
        `ALU_AND:
            result = a & b;
        `ALU_OR:
            result = a | b;
        `ALU_XOR:
            result = a ^ b;
        `ALU_SLL:
            result = a << b[4:0];
        `ALU_SRL:
            result = a >> b[4:0];
        `ALU_SRA:
            result = $signed(a) >>> b[4:0];
        `ALU_SLT:
            result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
        `ALU_SLTU:
            result = (a < b) ? 32'b1 : 32'b0;
        `ALU_B:
            result = b;
        default:
            result = 32'b0;
    endcase
end

endmodule
