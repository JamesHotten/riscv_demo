`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 19:26:15
// Design Name:
// Module Name: imem
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


module imem (
           input clk,
           input [31:0] pc,
           output [31:0] instr
       );

reg [31:0] rom [0:1023];

initial begin
    $readmemh("test.hex", rom);
end

assign instr = rom[pc[31:2]];

endmodule
