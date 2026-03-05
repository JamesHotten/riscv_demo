`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/03/05 18:55:30
// Design Name:
// Module Name: clint
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


module clint(
           input  clk,
           input  rst_n,

           // MMIO interface (0x0200_xxxx)
           input  [31:0] mem_addr,
           input  [31:0] mem_wdata,
           input  mem_we,

           output reg [31:0] mem_rdata,

           output timer_irq
       );

reg [63:0] mtime; // timer
reg [63:0] mtimecmp; // timer compare trigger

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mtime <= 64'b0;
    else
        mtime <= mtime + 1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mtimecmp <= 64'hFFFFFFFF_FFFFFFFF; // 复位时默认永远不触发
    else if (mem_we) begin
        // 规定: 0x02004000 写入 mtimecmp 低32位，0x02004004 写入高32位
        if (mem_addr == 32'h02004000)
            mtimecmp[31:0]  <= mem_wdata;
        if (mem_addr == 32'h02004004)
            mtimecmp[63:32] <= mem_wdata;
    end
end

// 操作系统的读取请求
always @(*) begin
    if      (mem_addr == 32'h02004000)
        mem_rdata = mtimecmp[31:0];
    else if (mem_addr == 32'h02004004)
        mem_rdata = mtimecmp[63:32];
    else if (mem_addr == 32'h0200BFF8)
        mem_rdata = mtime[31:0];
    else if (mem_addr == 32'h0200BFFC)
        mem_rdata = mtime[63:32];
    else
        mem_rdata = 32'b0;
end

// 拉高中断信号
assign timer_irq = (mtime >= mtimecmp);

endmodule
