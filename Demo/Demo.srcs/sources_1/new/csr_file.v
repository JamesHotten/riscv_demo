`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/02 22:43:40
// Design Name:
// Module Name: csr_file
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

module csr_file(
           input  clk,
           input  rst_n,

           input  [11:0] csr_addr, // csr地址
           input  csr_we,   // csr写使能
           input  [31:0] csr_wdata, // csr写数据
           output  reg [31:0] csr_rdata, // csr读数据

           input  trap_en, // 异常使能
           input  [31:0] trap_pc, // 异常pc
           input  [31:0] trap_cause, // 异常cause

           input  timer_irq, //来自 CLINT 的中断信号
           input  is_mret,  // 流水线正在执行 MRET
           input  ex_valid,

           output irq_trap, //中断冲刷
           output [31:0] mepc_out, // 返回地址
           output [31:0] mtvec_out, // 异常向量地址
           output mie_out //全局中断使能
       );

reg [31:0] mstatus;
reg [31:0] mtvec;
reg [31:0] mepc;
reg [31:0] mcause;
reg [31:0] mscratch;

wire do_trap = trap_en || irq_trap;
assign mie_out = mstatus[3]; // mstatus 的第 3 位是 MIE (全局中断使能)
// 只有当定时器请求 + CPU允许中断 + EX阶段有一条真实的有效指令时，才触发中断打断它
assign irq_trap = timer_irq && mie_out && ex_valid;

// 读
always @(*) begin
    case (csr_addr)
        12'h300:
            csr_rdata = mstatus;
        12'h305:
            csr_rdata = mtvec;
        12'h340:
            csr_rdata = mscratch;
        12'h341:
            csr_rdata = mepc;
        12'h342:
            csr_rdata = mcause;
        default:
            csr_rdata = 32'b0;
    endcase
end

// 写
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mstatus <= 32'b0;
        mtvec   <= 32'b0;
        mepc    <= 32'b0;
        mcause  <= 32'b0;
        mscratch<= 32'b0;
    end
    else if (do_trap) begin
        // 硬件自动更新 (发生同步异常 异步中断)
        mepc   <= trap_pc;

        // 如果是定时器中断，写死 Cause 为 0x80000007；如果是 ECALL，用传入的 trap_cause
        mcause <= irq_trap ? 32'h80000007 : trap_cause;

        mstatus[7] <= mstatus[3]; // 将 MIE (全局使能) 备份到 MPIE (mstatus[7])
        mstatus[3] <= 1'b0;       // 关闭 MIE
    end
    else if (is_mret) begin
        // 异常返回
        mstatus[3] <= mstatus[7]; // 恢复现场：把备份的 MPIE 恢复给 MIE
        mstatus[7] <= 1'b1;       // RISC-V 规范规定 MPIE 置 1
    end
    else if (csr_we) begin
        // 软件指令写
        case (csr_addr)
            12'h300:
                mstatus <= csr_wdata;
            12'h305:
                mtvec   <= csr_wdata;
            12'h340:
                mscratch<= csr_wdata;
            12'h341:
                mepc    <= csr_wdata;
            12'h342:
                mcause  <= csr_wdata;
            default:
                ;
        endcase
    end
end

assign mepc_out  = mepc;
assign mtvec_out = mtvec;

endmodule
