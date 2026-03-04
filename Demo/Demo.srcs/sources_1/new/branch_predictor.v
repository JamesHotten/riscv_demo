`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/22 11:06:09
// Design Name:
// Module Name: branch_predictor
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


module branch_predictor(
           input  clk,
           input  rst_n,

           // if_stage 预测
           input  [31:0] if_pc,
           output  pred_taken,
           output  [31:0] pred_target,

           // ex_stage 更新
           input  [31:0] ex_pc,
           input  ex_is_branch,
           input  ex_actual_taken,
           input  [31:0] ex_actual_target
       );

parameter INDEX_BITS = 6; // 64 entries
parameter DEPTH = 1 << INDEX_BITS;

reg [31:0] btb_tags [DEPTH-1:0]; // PC tag
reg [31:0] btb_targets [DEPTH-1:0]; // Target address
reg [1:0] bht_counters [DEPTH-1:0]; // 00: strongly not taken, 01: weakly not taken, 10: weakly taken, 11: strongly taken
reg valid [DEPTH-1:0]; // Valid bit to indicate if the entry is valid

// Index calculation 查表索引
wire [INDEX_BITS-1:0] if_index = if_pc[INDEX_BITS+1:2]; // Assuming word-aligned addresses
wire [31:0] if_tag = if_pc;

wire [31:0] stored_tag = btb_tags[if_index];
wire [31:0] stored_target = btb_targets[if_index];
wire [1:0] stored_counter = bht_counters[if_index];
wire stored_valid = valid[if_index];

wire hit = stored_valid && (stored_tag == if_tag);

assign pred_taken = hit && (stored_counter[1] == 1); // Predict taken if counter is 10 or 11
assign pred_target = hit ? stored_target : 32'b0; //交给mux

// EX 阶段更新
wire [INDEX_BITS-1:0] ex_index = ex_pc[INDEX_BITS+1 : 2];
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            valid[i] <= 0;
            bht_counters[i] <= 2'b01; // 默认弱不跳转
        end
    end
    else if (ex_is_branch) begin
        // 1. 更新 Tag 和 Target (无论跳没跳，都更新，建立索引)
        valid[ex_index] <= 1'b1;
        btb_tags[ex_index] <= ex_pc;
        btb_targets[ex_index] <= ex_actual_target;

        // 2. 更新饱和计数器
        if (ex_actual_taken) begin
            if (bht_counters[ex_index] != 2'b11)
                bht_counters[ex_index] <= bht_counters[ex_index] + 1;
        end
        else begin
            if (bht_counters[ex_index] != 2'b00)
                bht_counters[ex_index] <= bht_counters[ex_index] - 1;
        end
    end
end

endmodule
