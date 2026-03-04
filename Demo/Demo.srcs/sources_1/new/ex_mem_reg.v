`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 21:11:27
// Design Name:
// Module Name: ex_mem_reg
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


module ex_mem_reg(
           input clk,
           input rst_n,

           // MEM 阶段用
           input  wire        ex_mem_write,
           input  wire        ex_mem_read,
           // WB 阶段用
           input  wire        ex_reg_write,
           input  wire        ex_mem_to_reg,

           input  wire [31:0] ex_alu_result,   // ALU 算出的结果 (也就是内存地址)
           input  wire [31:0] ex_rs2_data,     // 准备写进内存的数据 (经过前递后的最新值)
           input  wire [4:0]  ex_rd,           // 目标寄存器地址

           output reg         mem_mem_write,
           output reg         mem_mem_read,

           output reg         mem_reg_write,
           output reg         mem_mem_to_reg,

           output reg  [31:0] mem_alu_result,
           output reg  [31:0] mem_wdata,       // Store 指令真正要写进内存的数据
           output reg  [4:0]  mem_rd
       );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位时，清空所有输出
        mem_mem_write  <= 1'b0;
        mem_mem_read   <= 1'b0;
        mem_reg_write  <= 1'b0;
        mem_mem_to_reg <= 1'b0;

        mem_alu_result <= 32'd0;
        mem_wdata      <= 32'd0;
        mem_rd         <= 5'd0;
    end
    else begin
        // 正常流水线步进：把 EX 阶段的成果打包送到 MEM 阶段
        mem_mem_write  <= ex_mem_write;
        mem_mem_read   <= ex_mem_read;

        mem_reg_write  <= ex_reg_write;
        mem_mem_to_reg <= ex_mem_to_reg;

        mem_alu_result <= ex_alu_result;
        mem_wdata      <= ex_rs2_data;
        mem_rd         <= ex_rd;
    end
end

endmodule
