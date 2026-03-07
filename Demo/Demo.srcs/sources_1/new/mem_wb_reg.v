module mem_wb_reg(
           input clk,
           input rst_n,

           input  mem_reg_write,
           input  mem_mem_to_reg,

           input [31:0] mem_alu_result,
           input [31:0] mem_rdata,
           input  [4:0] mem_rd,

           output reg wb_reg_write,
           output reg wb_mem_to_reg,

           output reg [31:0] wb_alu_result,
           output reg [31:0] wb_rdata,
           output reg [4:0] wb_rd,

           //FPU
           input  wire mem_fp_write,
           output reg  wb_fp_write
       );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wb_reg_write <= 1'b0;
        wb_mem_to_reg <= 1'b0;

        wb_alu_result <= 32'h0;
        wb_rdata <= 32'h0;
        wb_rd <= 5'h0;

        wb_fp_write <= 1'b0;
    end
    else begin
        wb_reg_write <= mem_reg_write;
        wb_mem_to_reg <= mem_mem_to_reg;

        wb_alu_result <= mem_alu_result;
        wb_rdata <= mem_rdata;
        wb_rd <= mem_rd;

        wb_fp_write <= mem_fp_write;
    end
end
endmodule
