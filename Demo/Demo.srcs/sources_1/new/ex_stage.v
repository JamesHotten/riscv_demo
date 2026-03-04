`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 20:23:05
// Design Name:
// Module Name: ex_stage
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


module ex_stage(

           // inputs from id
           input [31:0] ex_pc,
           input [31:0] ex_rdata1,
           input [31:0] ex_rdata2,
           input [31:0] ex_imm,

           input  ex_alu_src_a,
           input  ex_alu_src_b,
           input  [3:0] ex_alu_ctrl,

           input [2:0] ex_funct3,

           input  ex_branch,
           input  ex_jump,

           // 前递数据
           input  [1:0]  forward_a,    // 00: 正常, 01: 来自WB阶段, 10: 来自MEM阶段
           input  [1:0]  forward_b,
           input  [31:0] mem_alu_result, // MEM 阶段前递回来的数据
           input  [31:0] wb_final_data,  // WB 阶段前递回来的数据

           // outputs
           output wire [31:0] alu_result, //to mem
           output wire [31:0] forward_rs2_out,

           output wire        branch_en, //to if
           output wire [31:0] branch_target
       );

reg  [31:0] forwarded_a;
reg  [31:0] forwarded_b;
wire [31:0] alu_in_a;
wire [31:0] alu_in_b;
wire [31:0] alu_calc_out;
wire        alu_zero;
wire [31:0] pc_plus_4;

// scra, scrb
always @(*) begin
    case (forward_a)
        2'b00:
            forwarded_a = ex_rdata1;      // 没有冒险，用译码阶段读出的旧数据
        2'b10:
            forwarded_a = mem_alu_result; // 冒险 用上一条指令 (MEM级) 刚算出的结果
        2'b01:
            forwarded_a = wb_final_data;  // 冒险 用上上条指令 (WB级) 准备写回的结果
        default:
            forwarded_a = ex_rdata1;
    endcase
end

always @(*) begin
    case (forward_b)
        2'b00:
            forwarded_b = ex_rdata2;
        2'b10:
            forwarded_b = mem_alu_result;
        2'b01:
            forwarded_b = wb_final_data;
        default:
            forwarded_b = ex_rdata2;
    endcase
end

// Store
assign forward_rs2_out = forwarded_b;

// A 端口：如果是 AUIPC/JAL，选 PC；否则选 rs1 (已前递)
assign alu_in_a = ex_alu_src_a ? ex_pc : forwarded_a;
// B 端口：如果是立即数指令 (如 addi, lw, sw)，选 imm；否则选 rs2 (已前递)
assign alu_in_b = ex_alu_src_b ? ex_imm : forwarded_b;

alu u_alu(
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(ex_alu_ctrl),
        .result(alu_calc_out),
        .zero(alu_zero)
    );

// branch

// PC + imm (用于 Branch 和 JAL)
assign pc_plus_4 = ex_pc + 32'd4;
assign alu_result = ex_jump ? pc_plus_4 : alu_calc_out;

// 1. 如果是无条件跳转 (JAL, JALR)，必定跳转 (ex_jump == 1)
// 2. 如果是条件分支 (Branch)，并且 ALU 算出来的结果为 0 (相等，即 beq 成立)，则跳转。
// JALR 的目标是 (rs1 + imm)，也就是 ALU 的计算结果 (alu_src_a=0, alu_src_b=1)
// JAL  的目标是 (PC  + imm)，我们需要专门的加法器
wire [31:0] pc_plus_imm = ex_pc + ex_imm;

// 跳转目标计算：
// 其他情况 (Branch, JAL)，目标地址是 PC + imm
// JALR 的目标地址是 {alu_result[31:1], 1'b0}
assign branch_target = (ex_jump && ex_alu_src_b) ? {alu_calc_out[31:1], 1'b0} : pc_plus_imm;

reg condition_met;
always @(*) begin
    case (ex_funct3)
        3'b000:
            condition_met = alu_zero;       // BEQ: 结果为0则跳
        3'b001:
            condition_met = ~alu_zero;      // BNE: 结果不为0则跳
        3'b100:
            condition_met = alu_calc_out[31]; // BLT: 结果为负则跳 
        3'b101:
            condition_met = ~alu_calc_out[31];// BGE: 结果为正则跳
        default:
            condition_met = 1'b0;
    endcase
end

assign branch_en = ex_jump | (ex_branch & condition_met);

endmodule
