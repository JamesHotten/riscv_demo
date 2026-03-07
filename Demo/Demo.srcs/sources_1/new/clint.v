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
           input  [31:0] mem_addr,    // 访问地址
           input  [31:0] mem_wdata,   // 写入数据
           input  mem_we,             // 写使能

           output reg [31:0] mem_rdata,

           output timer_irq         // 定时器中断输出 (连接到 CPU 的 mtip 引脚)
       );

reg [63:0] mtime;    // 64 位自由运行计数器，每个时钟周期 +1
reg [63:0] mtimecmp; // 64 位比较值，当 mtime >= mtimecmp 时触发中断

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
        // 读取 mtimecmp 低 32 位
        mem_rdata = mtimecmp[31:0];
    else if (mem_addr == 32'h02004004)
        // 读取 mtimecmp 高 32 位
        mem_rdata = mtimecmp[63:32];
    else if (mem_addr == 32'h0200BFF8)
        // 读取 mtime 低 32 位 (只读)
        mem_rdata = mtime[31:0];
    else if (mem_addr == 32'h0200BFFC)
        // 读取 mtime 高 32 位 (只读)
        mem_rdata = mtime[63:32];
    else
        // 未映射地址返回 0
        mem_rdata = 32'b0;
end

// 拉高中断信号
assign timer_irq = (mtime >= mtimecmp);

endmodule
