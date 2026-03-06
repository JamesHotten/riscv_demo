`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/20 11:24:11
// Design Name:
// Module Name: riscv_top
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

module riscv_top(
           input  clk,
           input  rst_n,

           output [31:0] current_pc,
           output [31:0] wb_data
       );

//  Hazard & Control Signals
wire        stall_if;
wire        stall_id;
wire        flush_id;
wire        flush_ex;
wire [1:0]  forward_a;
wire [1:0]  forward_b;

//  IF Stage Signals
wire [31:0] if_pc;
wire [31:0] if_instr;

//  IF/ID Register Signals
wire [31:0] id_pc;
wire [31:0] id_instr;

//  ID Stage Signals
wire [31:0] id_rdata1;
wire [31:0] id_rdata2;
wire [31:0] id_imm;
wire [4:0]  id_rs1 = id_instr[19:15];
wire [4:0]  id_rs2 = id_instr[24:20];
wire [4:0]  id_rd  = id_instr[11:7];

// ID Control Signals
wire        id_alu_src_a;
wire        id_alu_src_b;
wire [3:0]  id_alu_ctrl;
wire        id_mem_write;
wire        id_mem_read;
wire        id_branch;
wire        id_jump;
wire        id_reg_write;
wire        id_mem_to_reg;

//  ID/EX Register Signals
wire [31:0] ex_pc;
wire [31:0] ex_rdata1;
wire [31:0] ex_rdata2;
wire [31:0] ex_imm;
wire [4:0]  ex_rs1;
wire [4:0]  ex_rs2;
wire [4:0]  ex_rd;

wire        ex_alu_src_a;
wire        ex_alu_src_b;
wire [3:0]  ex_alu_ctrl;
wire        ex_mem_write;
wire        ex_mem_read;
wire        ex_branch;
wire        ex_jump;
wire        ex_reg_write;
wire        ex_mem_to_reg;

wire [2:0] id_funct3 = id_instr[14:12];
wire [2:0] ex_funct3;

//  EX Stage Signals
wire [31:0] ex_alu_result;
wire [31:0] ex_rs2_forwarded;
wire        ex_branch_taken;
wire [31:0] ex_target_addr;

//  EX/MEM Register Signals
wire [31:0] mem_alu_result;
wire [31:0] mem_wdata;
wire [4:0]  mem_rd;

wire        mem_mem_write;
wire        mem_mem_read;
wire        mem_reg_write;
wire        mem_mem_to_reg;

//  MEM Stage Signals
wire [31:0] mem_rdata;
wire [2:0]  mem_funct3;
wire [3:0]  dmem_we;
wire [31:0] dmem_wdata_aligned;
wire [31:0] dmem_rdata_actual;

// ==================== MMIO 与中断信号 ====================
// 只要内存地址前缀是 0x0200，说明要访问 CLINT 定时器
wire is_clint = (mem_alu_result[31:16] == 16'h0200);
wire clint_we = mem_mem_write && is_clint;

wire timer_irq;
wire [31:0] clint_rdata;

// 核心总线多路选择器：根据地址判断是读内存还是读外设
wire [31:0] raw_rdata_bus = is_clint ? clint_rdata : dmem_rdata_actual;
// ==========================================================

//  MEM/WB Register Signals
wire [31:0] wb_alu_result;
wire [31:0] wb_mem_data;
wire [4:0]  wb_rd;

wire        wb_reg_write;
wire        wb_mem_to_reg;

// 预测器信号
wire        pred_taken_id;
wire        pred_taken_ex;
wire        pred_taken_if;
wire [31:0] pred_target_if;
wire        mispredict;

//  WB Stage Signals
wire [31:0] wb_final_data;

// System & CSR Signals
wire        id_is_csr;
wire        id_ecall;
wire        id_mret;
wire [11:0] id_csr_addr = id_instr[31:20];

wire        ex_is_csr;
wire        ex_ecall;
wire        ex_mret;
wire [11:0] ex_csr_addr;

wire [31:0] csr_rdata;
wire        csr_we;
wire [31:0] csr_wdata;
wire [31:0] mepc_out;
wire [31:0] mtvec_out;
wire        mie_out;
wire        irq_trap;

// ==================== 模块例化区 ====================

hazard_detection_unit u_hazard_detect (
                          .id_rs1      (id_rs1),
                          .id_rs2      (id_rs2),
                          .ex_rd       (ex_rd),
                          .ex_mem_read (ex_mem_read),
                          .mispredict  (mispredict),

                          .stall_if    (stall_if),
                          .stall_id    (stall_id),
                          .flush_id    (flush_id),
                          .flush_ex    (flush_ex),

                          .ex_ecall    (ex_ecall),
                          .ex_mret     (ex_mret),
                          .irq_trap    (irq_trap)
                      );

forwarding_unit u_forwarding (
                    .ex_rs1       (ex_rs1),
                    .ex_rs2       (ex_rs2),
                    .mem_rd       (mem_rd),
                    .mem_reg_write(mem_reg_write),
                    .wb_rd        (wb_rd),
                    .wb_reg_write (wb_reg_write),
                    .forward_a    (forward_a),
                    .forward_b    (forward_b)
                );

// Stage 1: IF (取指)
if_stage u_if_stage (
             .clk             (clk),
             .rst_n           (rst_n),
             .stall_if        (stall_if),

             .pred_taken_if   (pred_taken_if),
             .pred_target_if  (pred_target_if),

             .ex_is_branch    (ex_branch || ex_jump),
             .ex_branch_taken (ex_branch_taken),
             .ex_target_addr  (ex_target_addr),
             .pred_taken_ex   (pred_taken_ex),
             .ex_pc           (ex_pc),

             .if_pc           (if_pc),
             .mispredict      (mispredict),

             .ex_ecall        (ex_ecall),
             .ex_mret         (ex_mret),
             .mtvec_out       (mtvec_out),
             .mepc_out        (mepc_out),
             .irq_trap        (irq_trap)
         );

imem u_imem (
         .pc   (if_pc),
         .instr(if_instr)
     );

// Pipe Reg: IF/ID
if_id_reg u_if_id_reg (
              .clk          (clk),
              .rst_n        (rst_n),
              .stall_id     (stall_id),
              .flush_id     (flush_id),
              .if_pc        (if_pc),
              .if_instr     (if_instr),

              .pred_taken_if(pred_taken_if),
              .pred_taken_id(pred_taken_id),

              .id_pc        (id_pc),
              .id_instr     (id_instr)
          );

// Stage 2: ID (译码)
reg_file u_reg_file (
             .clk   (clk),
             .rst_n (rst_n),
             .raddr1(id_rs1),
             .rdata1(id_rdata1),
             .raddr2(id_rs2),
             .rdata2(id_rdata2),
             .waddr (wb_rd),
             .wdata (wb_final_data),
             .wen   (wb_reg_write)
         );

imm_gen u_imm_gen (
            .instr(id_instr),
            .imm  (id_imm)
        );

ctrl_unit u_ctrl_unit (
              .instr     (id_instr),
              .alu_src_a (id_alu_src_a),
              .alu_src_b (id_alu_src_b),
              .alu_ctrl  (id_alu_ctrl),
              .mem_write (id_mem_write),
              .mem_read  (id_mem_read),
              .branch    (id_branch),
              .jump      (id_jump),
              .reg_write (id_reg_write),
              .mem_to_reg(id_mem_to_reg),
              .is_csr    (id_is_csr),
              .ecall     (id_ecall),
              .mret      (id_mret)
          );

// Pipe Reg: ID/EX
id_ex_reg u_id_ex_reg (
              .clk          (clk),
              .rst_n        (rst_n),
              .flush_ex     (flush_ex),

              .id_alu_src_a (id_alu_src_a),
              .id_alu_src_b (id_alu_src_b),
              .id_alu_ctrl  (id_alu_ctrl),
              .id_mem_write (id_mem_write),
              .id_mem_read  (id_mem_read),
              .id_branch    (id_branch),
              .id_jump      (id_jump),
              .id_reg_write (id_reg_write),
              .id_mem_to_reg(id_mem_to_reg),

              .id_pc        (id_pc),
              .id_rdata1    (id_rdata1),
              .id_rdata2    (id_rdata2),
              .id_imm       (id_imm),
              .id_rs1       (id_rs1),
              .id_rs2       (id_rs2),
              .id_rd        (id_rd),

              .pred_taken_id(pred_taken_id),
              .pred_taken_ex(pred_taken_ex),

              .id_is_csr   (id_is_csr),
              .id_ecall    (id_ecall),
              .id_mret     (id_mret),
              .id_csr_addr (id_csr_addr),
              .id_funct3   (id_funct3),

              .ex_alu_src_a (ex_alu_src_a),
              .ex_alu_src_b (ex_alu_src_b),
              .ex_alu_ctrl  (ex_alu_ctrl),
              .ex_mem_write (ex_mem_write),
              .ex_mem_read  (ex_mem_read),
              .ex_branch    (ex_branch),
              .ex_jump      (ex_jump),
              .ex_reg_write (ex_reg_write),
              .ex_mem_to_reg(ex_mem_to_reg),

              .ex_pc        (ex_pc),
              .ex_rdata1    (ex_rdata1),
              .ex_rdata2    (ex_rdata2),
              .ex_imm       (ex_imm),
              .ex_rs1       (ex_rs1),
              .ex_rs2       (ex_rs2),
              .ex_rd        (ex_rd),
              .ex_funct3    (ex_funct3),

              .ex_is_csr   (ex_is_csr),
              .ex_ecall    (ex_ecall),
              .ex_mret     (ex_mret),
              .ex_csr_addr (ex_csr_addr)
          );

// Stage 3: EX (执行)
ex_stage u_ex_stage (
             .ex_pc          (ex_pc),
             .ex_rdata1      (ex_rdata1),
             .ex_rdata2      (ex_rdata2),
             .ex_imm         (ex_imm),
             .ex_alu_src_a   (ex_alu_src_a),
             .ex_alu_src_b   (ex_alu_src_b),
             .ex_alu_ctrl    (ex_alu_ctrl),
             .ex_branch      (ex_branch),
             .ex_jump        (ex_jump),
             .forward_a      (forward_a),
             .forward_b      (forward_b),
             .mem_alu_result (mem_alu_result),
             .wb_final_data  (wb_final_data),

             .alu_result     (ex_alu_result),
             .forward_rs2_out(ex_rs2_forwarded),
             .branch_en      (ex_branch_taken),
             .ex_funct3      (ex_funct3),
             .branch_target  (ex_target_addr),

             .ex_is_csr      (ex_is_csr),
             .ex_rs1         (ex_rs1),
             .csr_rdata      (csr_rdata),
             .csr_we         (csr_we),
             .csr_wdata      (csr_wdata)
         );

// Pipe Reg: EX/MEM
ex_mem_reg u_ex_mem_reg (
               .clk           (clk),
               .rst_n         (rst_n),
               .ex_mem_write  (ex_mem_write),
               .ex_mem_read   (ex_mem_read),
               .ex_reg_write  (ex_reg_write),
               .ex_mem_to_reg (ex_mem_to_reg),
               .ex_alu_result (ex_alu_result),
               .ex_rs2_data   (ex_rs2_forwarded),
               .ex_rd         (ex_rd),
               .ex_funct3     (ex_funct3),

               .mem_mem_write (mem_mem_write),
               .mem_mem_read  (mem_mem_read),
               .mem_reg_write (mem_reg_write),
               .mem_mem_to_reg(mem_mem_to_reg),
               .mem_alu_result(mem_alu_result),
               .mem_wdata     (mem_wdata),
               .mem_rd        (mem_rd),
               .mem_funct3    (mem_funct3)
           );

// Stage 4: MEM (访存)
mem_ctrl u_mem_ctrl (
             .funct3       (mem_funct3),
             .addr         (mem_alu_result),
             .wdata_in     (mem_wdata),
             .mem_write_en (mem_mem_write),
             .dmem_we      (dmem_we),
             .dmem_wdata   (dmem_wdata_aligned),
             .dmem_rdata   (raw_rdata_bus), // ✅ 接入整理好的核心总线
             .rdata_out    (mem_rdata)
         );

dmem u_dmem (
         .clk  (clk),
         .we   (is_clint ? 4'b0000 : dmem_we),
         .re   (mem_mem_read && !is_clint),
         .addr (mem_alu_result),
         .wdata(dmem_wdata_aligned),
         .rdata(dmem_rdata_actual)
     );

clint u_clint (
          .clk      (clk),
          .rst_n    (rst_n),
          .mem_addr (mem_alu_result),
          .mem_wdata(mem_wdata),
          .mem_we   (clint_we),
          .mem_rdata(clint_rdata),
          .timer_irq(timer_irq)
      );

// Pipe Reg: MEM/WB
mem_wb_reg u_mem_wb_reg (
               .clk           (clk),
               .rst_n         (rst_n),
               .mem_reg_write (mem_reg_write),
               .mem_mem_to_reg(mem_mem_to_reg),
               .mem_alu_result(mem_alu_result),
               .mem_rdata     (mem_rdata),
               .mem_rd        (mem_rd),

               .wb_reg_write  (wb_reg_write),
               .wb_mem_to_reg (wb_mem_to_reg),
               .wb_alu_result (wb_alu_result),
               .wb_rdata      (wb_mem_data),
               .wb_rd         (wb_rd)
           );

// Stage 5: WB (写回)
wb_stage u_wb_stage (
             .wb_alu_result(wb_alu_result),
             .wb_mem_data  (wb_mem_data),
             .wb_mem_to_reg(wb_mem_to_reg),
             .wb_final_data(wb_final_data)
         );

// 预测模块
branch_predictor u_bp (
                     .clk             (clk),
                     .rst_n           (rst_n),
                     .if_pc           (if_pc),
                     .pred_taken      (pred_taken_if),
                     .pred_target     (pred_target_if),

                     .ex_pc           (ex_pc),
                     .ex_is_branch    (ex_branch || ex_jump),
                     .ex_actual_taken (ex_branch_taken),
                     .ex_actual_target(ex_target_addr)
                 );

csr_file u_csr (
             .clk        (clk),
             .rst_n      (rst_n),

             .csr_addr   (ex_csr_addr),
             .csr_we     (csr_we),
             .csr_wdata  (csr_wdata),
             .csr_rdata  (csr_rdata),

             .trap_en    (ex_ecall),
             .trap_pc    (ex_pc),
             .trap_cause (32'd11),

             .mepc_out   (mepc_out),
             .mtvec_out  (mtvec_out),
             .mie_out    (mie_out),

             .timer_irq  (timer_irq),
             .is_mret    (ex_mret),
             .irq_trap   (irq_trap)
         );

endmodule
