`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/07 12:21:46
// Design Name:
// Module Name: fpr_file
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


module fpr_file(
           input  wire        clk,
           input  wire        rst_n,

           // 读端口 1
           input  wire [4:0]  raddr1,
           output wire [31:0] rdata1,

           // 读端口 2
           input  wire [4:0]  raddr2,
           output wire [31:0] rdata2,

           // 读端口 3 ( fmadd.s 等融合乘加指令)
           input  wire [4:0]  raddr3,
           output wire [31:0] rdata3,

           // 写端口
           input  wire        we,
           input  wire [4:0]  waddr,
           input  wire [31:0] wdata
       );

// 32 个 32位 浮点寄存器 (注意：f0 就是普通的寄存器，不恒为 0)
reg [31:0] regs [0:31];
integer i;

// 读逻辑
assign rdata1 = (we && (waddr == raddr1)) ? wdata : regs[raddr1];
assign rdata2 = (we && (waddr == raddr2)) ? wdata : regs[raddr2];
assign rdata3 = (we && (waddr == raddr3)) ? wdata : regs[raddr3];

// 写逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] <= 32'b0;
        end
    end
    else if (we) begin
        regs[waddr] <= wdata;
    end
end

endmodule
