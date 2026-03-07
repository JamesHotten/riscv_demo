`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/20 11:14:13
// Design Name:
// Module Name: forwarding_unit
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


module forwarding_unit(
           input [4:0] ex_rs1,
           input [4:0] ex_rs2,

           // mem stage
           input  [4:0] mem_rd,       // MEM 阶段要写回的目标寄存器地址
           input  mem_reg_write,      // MEM 阶段寄存器写使能

           // wb stage
           input  [4:0] wb_rd,        // WB 阶段要写回的目标寄存器地址
           input  wb_reg_write,       // WB 阶段寄存器写使能

           output reg [1:0] forward_a, // rs1
           output reg [1:0] forward_b  //rs2
       );

// rs1
always @(*) begin
    forward_a = 0;

    // EX冒险
    if (mem_reg_write && mem_rd != 0 && mem_rd == ex_rs1) begin
        forward_a = 2'b10;
    end

    // MEM冒险
    else
        if (wb_reg_write && wb_rd != 0 && wb_rd == ex_rs1) begin
            forward_a = 2'b01;
        end
end

// rs2
always @(*) begin
    forward_b = 0;

    // EX冒险
    if (mem_reg_write && mem_rd != 0 && mem_rd == ex_rs2) begin
        forward_b = 2'b10;
    end

    // MEM冒险
    else
        if (wb_reg_write && wb_rd != 0 && wb_rd == ex_rs2) begin
            forward_b = 2'b01;
        end
end

endmodule
