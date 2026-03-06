//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 18:49:30
// Design Name:
// Module Name: riscv_defines
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


`ifndef RISCV_DEFINES_V
`define RISCV_DEFINES_V


`define LUI    7'b0110111 // U-type: Load Upper Immediate
`define AUIPC  7'b0010111 // U-type: Add Upper Immediate to PC
`define JAL    7'b1101111 // J-type: Jump And Link
`define JALR   7'b1100111 // I-type: Jump And Link Register
`define BRANCH 7'b1100011 // B-type: 分支 (beq, bne...)
`define LOAD   7'b0000011 // I-type: 内存读取 (lw, lh, lb...)
`define STORE  7'b0100011 // S-type: 内存写入 (sw, sh, sb...)
`define OP_IMM 7'b0010011 // I-type: 立即数运算 (addi, ori...)
`define OP_REG 7'b0110011 // R-type: 寄存器运算 (add, sub...)

`define ALU_ADD  4'b0000 // 加法
`define ALU_SUB  4'b0001 // 减法
`define ALU_SLL  4'b0010 // 逻辑左移
`define ALU_SLT  4'b0011 // 有符号比较，小于置1
`define ALU_SLTU 4'b0100 // 无符号比较，小于置1
`define ALU_XOR  4'b0101 // 异或
`define ALU_SRL  4'b0110 // 逻辑右移
`define ALU_SRA  4'b0111 // 算术右移
`define ALU_OR   4'b1000 // 按位或
`define ALU_AND  4'b1001 // 按位与
`define ALU_B    4'b1111 // 直接输出操作数B

`define OPCODE_SYSTEM  7'b1110011
`define FENCE  7'b0001111 // MISC-MEM: fence指令

        // Funct3 (决定是哪种 CSR 操作)
`define FUNCT3_CSRRW   3'b001  // Read & Write (交换)
`define FUNCT3_CSRRS   3'b010  // Read & Set (置位)
`define FUNCT3_CSRRC   3'b011  // Read & Clear (清零)

        // 特权指令 Funct12 (System Instructions)
`define FUNCT12_ECALL  12'h000 // Environment Call
`define FUNCT12_MRET   12'h302 // Machine Return
`define FUNCT12_EBREAK  12'h001 // Breakpoint

`endif
