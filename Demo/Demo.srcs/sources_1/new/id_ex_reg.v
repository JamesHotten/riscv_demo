`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 20:09:17
// Design Name:
// Module Name: id_ex_reg
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


module id_ex_reg(
           input clk,
           input rst_n,
           input flush_ex,

           //ctrl signals
           // EX 阶段用
           input  wire        id_alu_src_a,
           input  wire        id_alu_src_b,
           input  wire [3:0]  id_alu_ctrl,
           // MEM 阶段用
           input  wire        id_mem_write,
           input  wire        id_mem_read,
           input  wire        id_branch,
           input  wire        id_jump,
           // WB 阶段用
           input  wire        id_reg_write,
           input  wire        id_mem_to_reg,
           // System
           input  wire        id_is_csr,
           input  wire        id_ecall,
           input  wire        id_ebreak,
           input  wire        id_mret,
           input  wire [11:0] id_csr_addr,

           //data addr
           input  wire [31:0] id_pc,
           input  wire [31:0] id_rdata1,
           input  wire [31:0] id_rdata2,
           input  wire [31:0] id_imm,
           input  wire [4:0]  id_rs1,
           input  wire [4:0]  id_rs2,
           input  wire [4:0]  id_rd,

           input  wire [2:0] id_funct3,
           output reg  [2:0] ex_funct3,

           output reg         ex_alu_src_a,
           output reg         ex_alu_src_b,
           output reg  [3:0]  ex_alu_ctrl,

           output reg         ex_mem_write,
           output reg         ex_mem_read,
           output reg         ex_branch,
           output reg         ex_jump,

           output reg         ex_reg_write,
           output reg         ex_mem_to_reg,

           output reg  [31:0] ex_pc,
           output reg  [31:0] ex_rdata1,
           output reg  [31:0] ex_rdata2,
           output reg  [31:0] ex_imm,
           output reg  [4:0]  ex_rs1,
           output reg  [4:0]  ex_rs2,
           output reg  [4:0]  ex_rd,

           input  pred_taken_id,      // 来自 ID
           output reg pred_taken_ex,   // 传给 EX (用于最终判决)
           input  [31:0] pred_target_id,
           output reg [31:0] pred_target_ex,

           input  id_valid,
           output reg ex_valid,

           output reg         ex_is_csr,
           output reg         ex_ecall,
           output reg         ex_ebreak,
           output reg         ex_mret,
           output reg  [11:0] ex_csr_addr,

           // FPU
           input  wire        id_fp_write,
           input  wire        id_is_fp_load,
           input  wire        id_is_fp_store,
           input  wire [31:0] id_fs2_data, //从浮点寄存器堆读出的数据

           output reg         ex_fp_write,
           output reg         ex_is_fp_load,
           output reg         ex_is_fp_store,
           output reg  [31:0] ex_fs2_data
       );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位时，清空所有输出
        ex_alu_src_a  <= 1'b0;
        ex_alu_src_b  <= 1'b0;
        ex_alu_ctrl   <= 4'b0;
        ex_mem_write  <= 1'b0;
        ex_mem_read   <= 1'b0;
        ex_branch     <= 1'b0;
        ex_jump       <= 1'b0;
        ex_reg_write  <= 1'b0;
        ex_mem_to_reg <= 1'b0;

        ex_pc     <= 32'd0;
        ex_rdata1 <= 32'd0;
        ex_rdata2 <= 32'd0;
        ex_imm    <= 32'd0;
        ex_rs1    <= 5'd0;
        ex_rs2    <= 5'd0;
        ex_rd     <= 5'd0;

        ex_funct3 <= 3'b0;

        pred_taken_ex <= 1'b0;
        pred_target_ex <= 32'b0;

        ex_is_csr   <= 1'b0;
        ex_ecall    <= 1'b0;
        ex_mret     <= 1'b0;
        ex_csr_addr <= 12'b0;
        ex_ebreak <= 1'b0;

        ex_valid <= 1'b0;

        ex_fp_write    <= 1'b0;
        ex_is_fp_load  <= 1'b0;
        ex_is_fp_store <= 1'b0;
        ex_fs2_data    <= 32'b0;
    end
    else if (flush_ex) begin
        // 发生冲刷时，把“写使能”相关信号清零，变成 NOP 操作
        ex_mem_write <= 1'b0;
        ex_reg_write <= 1'b0;
        ex_branch    <= 1'b0;
        ex_jump      <= 1'b0;

        ex_mem_read   <= 1'b0;
        ex_alu_ctrl   <= 4'b0;
        ex_alu_src_a  <= 1'b0;
        ex_alu_src_b  <= 1'b0;
        ex_mem_to_reg <= 1'b0;
        ex_rd         <= 5'd0;

        ex_funct3 <= 3'b0;

        pred_taken_ex <= 1'b0;
        pred_target_ex <= 32'b0;

        ex_is_csr   <= 1'b0; // 冲刷时必须清零，防止误触发系统调用
        ex_ecall    <= 1'b0;
        ex_mret     <= 1'b0;
        ex_csr_addr <= 12'b0;
        ex_valid     <= 1'b0;
        ex_ebreak <= 1'b0;

        ex_fp_write    <= 1'b0;
        ex_is_fp_load  <= 1'b0;
        ex_is_fp_store <= 1'b0;
        ex_fs2_data    <= 32'b0;

    end
    else begin
        // 正常流水线步进
        ex_alu_src_a  <= id_alu_src_a;
        ex_alu_src_b  <= id_alu_src_b;
        ex_alu_ctrl   <= id_alu_ctrl;

        ex_mem_write  <= id_mem_write;
        ex_mem_read   <= id_mem_read;
        ex_branch     <= id_branch;
        ex_jump       <= id_jump;

        ex_reg_write  <= id_reg_write;
        ex_mem_to_reg <= id_mem_to_reg;

        ex_pc     <= id_pc;
        ex_rdata1 <= id_rdata1;
        ex_rdata2 <= id_rdata2;
        ex_imm    <= id_imm;
        ex_rs1    <= id_rs1;
        ex_rs2    <= id_rs2;
        ex_rd     <= id_rd;

        ex_funct3 <= id_funct3;

        pred_taken_ex <= pred_taken_id;
        pred_target_ex <= pred_target_id;

        ex_is_csr   <= id_is_csr;
        ex_ecall    <= id_ecall;
        ex_mret     <= id_mret;
        ex_csr_addr <= id_csr_addr;
        ex_valid <= id_valid;
        ex_ebreak <= id_ebreak;

        ex_fp_write    <= id_fp_write;
        ex_is_fp_load  <= id_is_fp_load;
        ex_is_fp_store <= id_is_fp_store;
        ex_fs2_data    <= id_fs2_data;
    end
end

endmodule
