`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 19:15:13
// Design Name:
// Module Name: reg_file
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


module reg_file(
           input clk,
           input rst_n,

           input [4:0] raddr1,
           output [31:0] rdata1,

           input [4:0] raddr2,
           output [31:0] rdata2,

           input [4:0] waddr,
           input [31:0] wdata,
           input wen

       );

reg [31:0] regs [31:0];
integer i;

// x0 恒为 0 > 写转发 (同周期读写同一寄存器) > 正常读寄存器
assign rdata1 = (raddr1 == 5'd0) ? 32'b0 :          // x0 恒为 0
       (wen && waddr == raddr1) ? wdata :   // 写转发：同周期写同一寄存器，直接输出 wdata
       regs[raddr1];                        // 正常读寄存器

assign rdata2 = (raddr2 == 5'd0) ? 32'b0 :
       (wen && waddr == raddr2) ? wdata :
       regs[raddr2];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] <= 32'b0;
        end
    end
    else if (wen && waddr != 0) begin
        regs[waddr] <= wdata;
    end
end

endmodule
