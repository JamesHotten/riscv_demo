`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/04 17:00:33
// Design Name:
// Module Name: mem_ctrl
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


`timescale 1ns / 1ps

module mem_ctrl(
           input  [2:0]  funct3,
           input  [31:0] addr,         // mem_alu_result
           input  [31:0] wdata_in,     // mem_wdata (前递后的原始数据)
           input         mem_write_en, // mem_mem_write

           output reg [3:0]  dmem_we,    // 传给 dmem 的 4位写使能掩码
           output reg [31:0] dmem_wdata, // 经过移位对齐后传给 dmem 的数据

           input  [31:0] dmem_rdata,   // 从 dmem 读出的原始 32位 数据
           output reg [31:0] rdata_out   // 经过截取和符号扩展后，准备传给 WB 阶段的数据
       );

wire [1:0] offset = addr[1:0]; // 地址的最低两位，决定了在 32-bit 字中的字节偏移

// Store 数据对齐与写掩码生成 (SB, SH, SW)
always @(*) begin
    dmem_we    = 4'b0000;
    dmem_wdata = wdata_in;

    if (mem_write_en) begin
        case (funct3[1:0])
            2'b00: begin // SB (Store Byte)
                dmem_we    = 4'b0001 << offset;
                dmem_wdata = {4{wdata_in[7:0]}}; // 把最低字节复制 4 份，配合掩码写入
            end
            2'b01: begin // SH (Store Halfword)
                // 半字要求地址是对齐的，这里简化处理，直接根据 offset[1] 决定写低半字还是高半字
                dmem_we    = offset[1] ? 4'b1100 : 4'b0011;
                dmem_wdata = {2{wdata_in[15:0]}};
            end
            default: begin // SW (Store Word)
                dmem_we    = 4'b1111;
                dmem_wdata = wdata_in;
            end
        endcase
    end
end

// Load 数据截取与符号扩展 (LB, LH, LW, LBU, LHU)
always @(*) begin
    rdata_out = dmem_rdata; // 默认原样输出

    case (funct3)
        3'b000: begin // LB (Load Byte, 符号扩展)
            case (offset)
                2'b00:
                    rdata_out = {{24{dmem_rdata[7]}},  dmem_rdata[7:0]};
                2'b01:
                    rdata_out = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
                2'b10:
                    rdata_out = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
                2'b11:
                    rdata_out = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
            endcase
        end
        3'b001: begin // LH (Load Halfword, 符号扩展)
            case (offset[1])
                1'b0:
                    rdata_out = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
                1'b1:
                    rdata_out = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
            endcase
        end
        3'b010: begin // LW (Load Word)
            rdata_out = dmem_rdata;
        end
        3'b100: begin // LBU (Load Byte Unsigned, 零扩展)
            case (offset)
                2'b00:
                    rdata_out = {24'b0, dmem_rdata[7:0]};
                2'b01:
                    rdata_out = {24'b0, dmem_rdata[15:8]};
                2'b10:
                    rdata_out = {24'b0, dmem_rdata[23:16]};
                2'b11:
                    rdata_out = {24'b0, dmem_rdata[31:24]};
            endcase
        end
        3'b101: begin // LHU (Load Halfword Unsigned, 零扩展)
            case (offset[1])
                1'b0:
                    rdata_out = {16'b0, dmem_rdata[15:0]};
                1'b1:
                    rdata_out = {16'b0, dmem_rdata[31:16]};
            endcase
        end
        default:
            rdata_out = dmem_rdata;
    endcase
end

endmodule
