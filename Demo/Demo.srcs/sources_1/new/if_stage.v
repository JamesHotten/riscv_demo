`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/05 10:46:10
// Design Name:
// Module Name: if_stage
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


module if_stage(
           input  clk,
           input  rst_n,
           input  stall_if,

           // 从分支预测器收到的预测信息
           input         pred_taken_if,
           input  [31:0] pred_target_if,

           // 从EX级反馈的信息
           input         ex_is_branch,     // EX 阶段是否是分支或跳转指令
           input         ex_branch_taken,  // EX 阶段算出的实际是否该跳
           input  [31:0] ex_target_addr,   // EX 阶段算出的实际目标
           input         pred_taken_ex,    // 预测时给出的结果
           input  [31:0] pred_target_ex,   // 预测时给出的目标地址
           input  [31:0] ex_pc,            // EX 阶段的PC

           input         ex_ecall,         // EX 阶段 ECALL 异常
           input         ex_ebreak,        // EX 阶段 EBREAK 异常
           input         ex_mret,          // EX 阶段 MRET 指令
           input  [31:0] mtvec_out,        // 异常向量基地址 (来自 CSR 文件)
           input  [31:0] mepc_out,         // 异常返回地址 (来自 CSR 文件)
           input         irq_trap,         // 外部中断请求 (如定时器中断)

           output [31:0] if_pc,
           output        mispredict
       );

// 预测失败
// 方向预测错了 (该跳没跳，或不该跳跳了)
wire direction_mismatch = (pred_taken_ex != ex_branch_taken);
// 方向预测对了，都是跳转，但目标地址算错了 (专门针对 JALR/BTB 污染)
wire target_mismatch = pred_taken_ex && ex_branch_taken && (pred_target_ex != ex_target_addr);
// 只要方向错或者地址错，且当前是分支/跳转指令，就触发冲刷
assign mispredict = ex_is_branch && (direction_mismatch || target_mismatch);

// 正确的 PC 地址
wire [31:0] correct_pc = ex_branch_taken ? ex_target_addr : (ex_pc + 32'd4);

// 取指 PC 多路选择器
wire [31:0] pc_next;

assign pc_next = (ex_ecall || irq_trap || ex_ebreak) ? mtvec_out :      // 发生异常或外部中断，强制跳往 mtvec
       ex_mret                ? mepc_out :       // 异常返回，强制跳往 mepc
       mispredict             ? correct_pc :     // 分支预测失败修正
       pred_taken_if          ? pred_target_if : // 预测跳转
       (if_pc + 32'd4);                          // 默认顺序执行

reg [31:0] pc;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pc <= 32'b0;
    end
    else if (!stall_if) begin
        pc <= pc_next;
    end
end

assign if_pc = pc;

always @(posedge clk) begin
    if (mispredict) begin
        $display("Time %t: [Predictor] Mispredict detected! Target PC should be %h", $time, correct_pc);
    end
end

endmodule
