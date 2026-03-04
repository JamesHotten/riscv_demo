`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 19:23:03
// Design Name:
// Module Name: pc_reg
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


module pc_reg(
           input clk,
           input rst_n,

           input stall_if,

           input  [31:0]next_pc,

           output reg[31:0] pc
       );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc <= 0;
    end
    else if (!stall_if) begin
        pc <= next_pc;
    end
    else begin
        pc <= pc;
    end
end

endmodule
