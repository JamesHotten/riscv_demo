`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 20:02:09
// Design Name:
// Module Name: ctrl_unit
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

module ctrl_unit(
           input [31:0] instr,

           output reg alu_src_a,
           output reg alu_src_b,
           output reg [3:0] alu_ctrl,

           output reg mem_write,      // 内存写使能 (SW 指令)
           output reg mem_read,       // 内存读使能 (LW 指令)
           output reg branch,         // 分支指令标志 (BEQ, BNE 等)
           output reg jump,           // 跳转指令标志 (JAL, JALR)

           output reg reg_write,
           output reg mem_to_reg,

           output reg is_csr,
           output reg ecall,
           output reg ebreak,
           output reg mret
       );

wire [6:0] opcode = instr[6:0];
wire [2:0] funct3 = instr[14:12];
wire [6:0] funct7 = instr[31:25];

always @(*) begin
    alu_src_a  = 1'b0;
    alu_src_b  = 1'b0;
    alu_ctrl   = `ALU_ADD;
    mem_write  = 1'b0;
    mem_read   = 1'b0;
    branch     = 1'b0;
    jump       = 1'b0;
    reg_write  = 1'b0;
    mem_to_reg = 1'b0;
    is_csr     = 1'b0;
    ecall      = 1'b0;
    ebreak = 1'b0;
    mret       = 1'b0; //default

    case (opcode)
        `OP_REG: begin // R-Type: add, sub, and, or...
            reg_write = 1'b1;
            // 根据 funct3 和 funct7 决定具体的 ALU 操作
            case (funct3)
                3'b000:
                    alu_ctrl = (funct7 == 7'b0100000) ? `ALU_SUB : `ALU_ADD;
                3'b111:
                    alu_ctrl = `ALU_AND;
                3'b110:
                    alu_ctrl = `ALU_OR;
                3'b100:
                    alu_ctrl = `ALU_XOR;
                3'b001:
                    alu_ctrl = `ALU_SLL;
                3'b101:
                    alu_ctrl = (funct7 == 7'b0100000) ? `ALU_SRA : `ALU_SRL;
                3'b010:
                    alu_ctrl = `ALU_SLT;
                3'b011:
                    alu_ctrl = `ALU_SLTU;
                default:
                    alu_ctrl = `ALU_ADD;
            endcase
        end

        `OP_IMM: begin // I-Type: addi, andi, ori...
            reg_write = 1'b1;
            alu_src_b = 1'b1; // 操作数 B 来自立即数
            case (funct3)
                3'b000:
                    alu_ctrl = `ALU_ADD; // addi
                3'b111:
                    alu_ctrl = `ALU_AND; // andi
                3'b110:
                    alu_ctrl = `ALU_OR;  // ori
                3'b100:
                    alu_ctrl = `ALU_XOR; // xori
                3'b001:
                    alu_ctrl = `ALU_SLL; // slli
                3'b101:
                    alu_ctrl = (funct7 == 7'b0100000) ? `ALU_SRA : `ALU_SRL; // srai/srli
                3'b010:
                    alu_ctrl = `ALU_SLT; // slti
                3'b011:
                    alu_ctrl = `ALU_SLTU;// sltiu
                default:
                    alu_ctrl = `ALU_ADD;
            endcase
        end

        `LOAD: begin // I-Type: lw, lh, lb
            reg_write  = 1'b1;
            alu_src_b  = 1'b1;   // ALU 用来计算内存地址: rs1 + imm
            alu_ctrl   = `ALU_ADD;
            mem_read   = 1'b1;
            mem_to_reg = 1'b1;   // 写回的数据来自 Memory，不是 ALU
        end

        `STORE: begin // S-Type: sw, sh, sb
            alu_src_b  = 1'b1;   // ALU 计算内存地址: rs1 + imm
            alu_ctrl   = `ALU_ADD;
            mem_write  = 1'b1;
        end

        `BRANCH: begin // B-Type: beq, bne...
            branch   = 1'b1;
            alu_ctrl = `ALU_SUB; // 用减法来比较 rs1 和 rs2 是否相等
        end

        `LUI: begin // U-Type: lui
            reg_write = 1'b1;
            alu_src_b = 1'b1;
            alu_ctrl  = `ALU_B;  // ALU 直接输出操作数 B (即立即数)
        end

        `AUIPC: begin // U-Type: auipc
            reg_write = 1'b1;
            alu_src_a = 1'b1;    // 操作数 A 来自 PC
            alu_src_b = 1'b1;    // 操作数 B 来自立即数
            alu_ctrl  = `ALU_ADD; // PC + imm
        end

        `JAL: begin // J-Type: jal
            reg_write = 1'b1;
            jump      = 1'b1;
        end

        `JALR: begin // I-Type: jalr
            reg_write = 1'b1;
            jump      = 1'b1;
            alu_src_b = 1'b1;     // JALR 需要立即数 (rs1 + imm)
            alu_ctrl  = `ALU_ADD; // 计算跳转目标地址
        end

        `FENCE: begin
            // FENCE 对于单核无缓存架构就是 NOP
            // 不需要做任何事情，所有控制信号保持顶部的默认值 0 即可
        end

        `OPCODE_SYSTEM: begin
            if (funct3 == 3'b000) begin
                // 异常与中断控制指令
                if (instr[31:20] == `FUNCT12_ECALL) begin
                    ecall = 1'b1;
                end
                else if (instr[31:20] == `FUNCT12_EBREAK) begin
                    ebreak = 1'b1;
                end
                else if (instr[31:20] == `FUNCT12_MRET) begin
                    mret = 1'b1;
                end
            end
            else begin
                // CSR 读写指令 (CSRRW, CSRRS, CSRRC 及其立即数版本)
                is_csr    = 1'b1;
                reg_write = 1'b1; // CSR 指令需要把读出的旧 CSR 值写回到通用寄存器 rd
            end
        end

        default:
            ; // 保持默认值 (全0)
    endcase
end

endmodule
