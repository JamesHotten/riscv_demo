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
wire [31:0] ex_rs2_forwarded; // Store 指令要写入内存的数据
wire        ex_branch_taken;  // 分支是否成立
wire [31:0] ex_target_addr;   // 跳转目标地址

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

//  MEM/WB Register Signals
wire [31:0] wb_alu_result;
wire [31:0] wb_mem_data;
wire [4:0]  wb_rd;

wire        wb_reg_write;
wire        wb_mem_to_reg;

// 预测器信号
wire        pred_taken_id; // 从 if_id_reg 输出
wire        pred_taken_ex; // 从 id_ex_reg 输出

// 修正信号
wire        mispredict;
wire [31:0] pc_next;      // 传给 pc_reg
wire [31:0] correct_pc;   // EX 阶段计算出的正确地址

//  WB Stage Signals
wire [31:0] wb_final_data;

hazard_detection_unit u_hazard_detect (
                          .id_rs1      (id_rs1),
                          .id_rs2      (id_rs2),
                          .ex_rd       (ex_rd),
                          .ex_mem_read (ex_mem_read),
                          //   .pc_src      (ex_branch_taken), // 来自 EX 级的跳转信号
                          .mispredict (mispredict),

                          .stall_if    (stall_if),
                          .stall_id    (stall_id),
                          .flush_id    (flush_id),
                          .flush_ex    (flush_ex)
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
pc_reg u_pc_reg (
           .clk          (clk),
           .rst_n        (rst_n),
           .stall_if     (stall_if),
           //    .branch_en    (ex_branch_taken), // 这里的信号来自 EX 级
           //    .branch_target(ex_target_addr),   // 这里的地址来自 EX 级
           .next_pc    (pc_next),
           .pc           (if_pc)
       );

imem u_imem (
         .pc   (if_pc),
         .instr(if_instr)
     );

// Pipe Reg: IF/ID
if_id_reg u_if_id_reg (
              .clk     (clk),
              .rst_n   (rst_n),
              .stall_id(stall_id),
              .flush_id(flush_id),
              .if_pc   (if_pc),
              .if_instr(if_instr),

              .pred_taken_if(pred_taken_if),
              .pred_taken_id(pred_taken_id),

              .id_pc   (id_pc),
              .id_instr(id_instr)
          );
// Stage 2: ID (译码)


reg_file u_reg_file (
             .clk   (clk),
             .rst_n (rst_n),
             .raddr1(id_rs1),
             .rdata1(id_rdata1),
             .raddr2(id_rs2),
             .rdata2(id_rdata2),
             .waddr (wb_rd),        // 写回地址来自 WB 级
             .wdata (wb_final_data),// 写回数据来自 WB 级
             .wen   (wb_reg_write)  // 写使能来自 WB 级
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
              .mem_to_reg(id_mem_to_reg)
          );

// Pipe Reg: ID/EX
id_ex_reg u_id_ex_reg (
              .clk          (clk),
              .rst_n        (rst_n),
              .flush_ex     (flush_ex),
              // Control Inputs
              .id_alu_src_a (id_alu_src_a),
              .id_alu_src_b (id_alu_src_b),
              .id_alu_ctrl  (id_alu_ctrl),
              .id_mem_write (id_mem_write),
              .id_mem_read  (id_mem_read),
              .id_branch    (id_branch),
              .id_jump      (id_jump),
              .id_reg_write (id_reg_write),
              .id_mem_to_reg(id_mem_to_reg),
              // Data Inputs
              .id_pc        (id_pc),
              .id_rdata1    (id_rdata1),
              .id_rdata2    (id_rdata2),
              .id_imm       (id_imm),
              .id_rs1       (id_rs1),
              .id_rs2       (id_rs2),
              .id_rd        (id_rd),

              .pred_taken_id(pred_taken_id),
              .pred_taken_ex(pred_taken_ex),

              // Outputs...
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

              .id_funct3(id_funct3),
              .ex_funct3(ex_funct3)
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
             .mem_alu_result (mem_alu_result), // Forwarding from MEM
             .wb_final_data  (wb_final_data),  // Forwarding from WB

             .alu_result     (ex_alu_result),
             .forward_rs2_out(ex_rs2_forwarded),
             .branch_en      (ex_branch_taken),
             .ex_funct3(ex_funct3),
             .branch_target  (ex_target_addr)
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

               .mem_mem_write (mem_mem_write),
               .mem_mem_read  (mem_mem_read),
               .mem_reg_write (mem_reg_write),
               .mem_mem_to_reg(mem_mem_to_reg),
               .mem_alu_result(mem_alu_result),
               .mem_wdata     (mem_wdata),
               .mem_rd        (mem_rd)
           );

// Stage 4: MEM (访存)
dmem u_dmem (
         .clk  (clk),
         .we   (mem_mem_write),
         .re   (mem_mem_read),
         .addr (mem_alu_result),
         .wdata(mem_wdata),
         .rdata(mem_rdata)
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

// dynamic predictor
wire        pred_taken_if;
wire [31:0] pred_target_if;

branch_predictor u_bp (
                     .clk(clk),
                     .rst_n(rst_n),
                     // IF 读
                     .if_pc(if_pc),
                     .pred_taken(pred_taken_if),
                     .pred_target(pred_target_if),
                     // EX 写 (反馈)
                     .ex_pc(ex_pc),
                     .ex_is_branch(ex_branch || ex_jump), // 是分支或跳转指令
                     .ex_actual_taken(ex_branch_taken),   // 实际是否跳转 (EX 阶段计算出的)
                     .ex_actual_target(ex_target_addr)    // 实际目标 (EX 阶段计算出的)
                 );

// 如果实际应该跳(ex_branch_taken)，则去目标地址；否则去 ex_pc + 4
assign correct_pc = ex_branch_taken ? ex_target_addr : (ex_pc + 4);

// 2. 判断是否预测错误 (Mispredict)
// 情况：(预测跳但实际没跳) OR (预测没跳但实际跳了)
// 注意：这里简化处理，假设预测的目标地址总是对的（BTB hit时）。如果想更严谨，还要比较地址。
assign mispredict = (ex_branch || ex_jump) && (pred_taken_ex != ex_branch_taken);

// 3. PC 最终选择逻辑 (优先级：修正 > 预测 > 顺序)
assign pc_next = mispredict    ? correct_pc :     // 只要EX阶段发现错了，立刻修正
       pred_taken_if ? pred_target_if : // 如果预测跳转，飞过去
       (if_pc + 4);                     // 默认 +4

endmodule
