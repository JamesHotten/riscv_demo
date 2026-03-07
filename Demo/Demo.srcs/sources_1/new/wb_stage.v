`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/20 11:11:13
// Design Name:
// Module Name: wb_stage
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


module wb_stage(
           input  [31:0] wb_alu_result,   // ALU 计算结果 (R-Type/I-Type 指令的运算结果)
           input  [31:0] wb_mem_data,     // 内存读出的数据 (LOAD 指令从 DMEM 读出的值)
           input  wb_mem_to_reg,          // 写回数据选择信号 (1=内存数据，0=ALU 结果)

           output [31:0] wb_final_data
       );

assign wb_final_data = wb_mem_to_reg ? wb_mem_data : wb_alu_result;

endmodule
