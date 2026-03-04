`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 21:15:55
// Design Name:
// Module Name: dmem
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


module dmem(
           input  clk,

           input  [3:0] we,
           input  re,

           input [31:0] addr,
           input [31:0] wdata,

           output [31:0] rdata
       );

reg [31:0] mem [0:1023];

integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        mem[i] = 32'h0;
    end
end // 仿真

// 字节 --> 字地址，地址最低两位不参与寻址
assign rdata = re ? mem[addr[31:2]] : 32'h0;

always @(posedge clk) begin
    // Test Begin
    if (we != 4'b0000 && addr == 32'h10000000) begin
        if (we[0])
            $write("%c", wdata[7:0]);
    end
    // Test End
    else begin
        // 根据 4-bit 掩码，按字节写入
        if (we[0])
            mem[addr[31:2]][7:0]   <= wdata[7:0];
        if (we[1])
            mem[addr[31:2]][15:8]  <= wdata[15:8];
        if (we[2])
            mem[addr[31:2]][23:16] <= wdata[23:16];
        if (we[3])
            mem[addr[31:2]][31:24] <= wdata[31:24];
    end
end

endmodule
