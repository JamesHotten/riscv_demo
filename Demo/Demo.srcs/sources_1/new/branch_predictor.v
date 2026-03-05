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
parameter HIST_BITS = 4;

// BTB
reg [31:0] btb_tags [DEPTH-1:0];
reg [31:0] btb_targets [DEPTH-1:0];
reg        valid [DEPTH-1:0];

// BHT
reg [HIST_BITS-1:0] bht [DEPTH-1:0];

// PHT
parameter PHT_INDEX_BITS = INDEX_BITS + HIST_BITS; // 6 + 4 = 10 bits
parameter PHT_DEPTH = 1 << PHT_INDEX_BITS;         // 1024 个计数器
reg [1:0] pht [PHT_DEPTH-1:0];

// IF 阶段预测逻辑
wire [INDEX_BITS-1:0] if_idx = if_pc[INDEX_BITS+1:2];
wire [31:0]           if_tag = if_pc;

wire [HIST_BITS-1:0]  if_hist    = bht[if_idx];            // 查BHT拿到历史
wire [PHT_INDEX_BITS-1:0] if_pht_idx = {if_idx, if_hist};  // 拼接哈希

wire stored_valid = valid[if_idx];
wire hit = stored_valid && (btb_tags[if_idx] == if_tag);
wire [1:0] counter_if = pht[if_pht_idx];                   // 查PHT拿到计数器

assign pred_taken  = hit && (counter_if[1] == 1'b1);       // 预测状态 (10 或 11 预测跳)
assign pred_target = hit ? btb_targets[if_idx] : 32'b0;

// EX 阶段更新逻辑
wire [INDEX_BITS-1:0] ex_idx = ex_pc[INDEX_BITS+1:2];
wire [HIST_BITS-1:0]  ex_hist = bht[ex_idx];               // 拿到之前预测时用的旧历史
wire [PHT_INDEX_BITS-1:0] ex_pht_idx = {ex_idx, ex_hist};

integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            valid[i] <= 0;
            bht[i]   <= 0;
        end
        for (i = 0; i < PHT_DEPTH; i = i + 1) begin
            pht[i] <= 2'b01; // PHT默认弱不跳转
        end
    end
    else if (ex_is_branch) begin
        // 更新 BTB 目标
        valid[ex_idx]       <= 1'b1;
        btb_tags[ex_idx]    <= ex_pc;
        btb_targets[ex_idx] <= ex_actual_target;

        // 更新 PHT (2位饱和计数器)
        if (ex_actual_taken) begin
            if (pht[ex_pht_idx] != 2'b11)
                pht[ex_pht_idx] <= pht[ex_pht_idx] + 1;
        end
        else begin
            if (pht[ex_pht_idx] != 2'b00)
                pht[ex_pht_idx] <= pht[ex_pht_idx] - 1;
        end

        // 更新 BHT (左移，并把实际跳转结果挤入最低位)
        bht[ex_idx] <= {bht[ex_idx][HIST_BITS-2:0], ex_actual_taken};
    end
end

endmodule
