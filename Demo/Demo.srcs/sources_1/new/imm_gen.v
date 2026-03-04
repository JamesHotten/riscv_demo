`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 19:42:31
// Design Name:
// Module Name: imm_gen
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

module imm_gen(
           input [31:0] instr,
           output reg [31:0] imm // rs1[19:15], rs2[24:20], funct3[14:12], rd[11:7], opcode[6:0]
       );

wire [6:0] opcode = instr[6:0];

always @(*) begin
    imm = 32'b0;
    case (opcode)
        `OP_IMM, `LOAD, `JALR: begin // I-Type
            // {20个符号位, 12位立即数}
            imm = {{20{instr[31]}}, instr[31:20]};
        end

        `STORE: begin // S-Type
            // {20个符号位, 高7位, 低5位}
            imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        end

        `BRANCH: begin // B-Type
            // {19个符号位, 第31位, 第7位, 高6位, 低4位, 最低位补0}
            imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        end

        `LUI, `AUIPC: begin // U-Type
            // {20位立即数, 低12位补0}
            imm = {instr[31:12], 12'b0};
        end

        `JAL: begin // J-Type
            // {11个符号位, 第31位, 第19~12位, 第20位, 第30~21位, 最低位补0}
            imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        end

        default:
            imm = 32'd0;
    endcase
end

endmodule
