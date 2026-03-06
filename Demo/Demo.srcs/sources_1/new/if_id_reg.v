`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/19 19:30:41
// Design Name:
// Module Name: if_id_reg
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


module if_id_reg(
           input clk,
           input rst_n,

           input stall_id,
           input flush_id,

           input [31:0] if_pc,
           input [31:0] if_instr,

           output reg [31:0] id_pc,
           output reg [31:0] id_instr,

           input  pred_taken_if,      // IF 阶段的预测结果
           output reg pred_taken_id,   // 传给 ID 阶段

           input  [31:0] pred_target_if,
           output reg [31:0] pred_target_id,

           output reg id_valid
       );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        id_pc <= 0;
        id_instr <= 32'h00000013; // NOP instruction: addi x0, x0, 0
        pred_taken_id <= 1'b0;
        pred_target_id <= 32'b0;
        id_valid <= 1'b0;
    end
    else if (flush_id) begin
        id_pc <= 0;
        id_instr <= 32'h00000013;
        pred_taken_id <= 1'b0;
        pred_target_id <= 32'b0;
        id_valid <= 1'b0;
    end
    else if (!stall_id) begin
        id_pc <= if_pc;
        id_instr <= if_instr;
        pred_taken_id <= pred_taken_if;
        pred_target_id <= pred_target_if;
        id_valid <= 1'b1;
    end
end

endmodule
