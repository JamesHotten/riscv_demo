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

           output [31:0] mepc_out, // 返回地址
           output [31:0] mtvec_out, // 异常向量地址
           output mie_out //全局中断使能
       );

reg [31:0] mstatus;
reg [31:0] mtvec;
reg [31:0] mepc;
reg [31:0] mcause;
reg [31:0] mscratch;

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
            csr_rdata = 32'b0; // 读不存在的寄存器返回 0
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
    else if (trap_en) begin
        // --- 硬件自动更新 (发生异常时) ---
        mepc   <= trap_pc;    // 保存当前 PC
        mcause <= trap_cause; // 记录原因
        // 注意：标准 RISC-V 还需要更新 mstatus 的 MIE/MPIE 位，这里先简化
        mstatus[7] <= 0;      // 禁用中断 (MPIE <= MIE; MIE <= 0)
        mstatus[3] <= mstatus[3]; // 简化: 保存旧的中断状态
    end
    else if (csr_we) begin
        // --- 软件指令写 (CSRRW 等) ---
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
                ; // 写不存在的寄存器忽略
        endcase
    end
end

assign mepc_out  = mepc;
assign mtvec_out = mtvec;
assign mie_out   = mstatus[3]; // mstatus 的第 3 位是 MIE (全局中断使能)

endmodule
