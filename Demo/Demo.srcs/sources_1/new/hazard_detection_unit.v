`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/02/20 11:19:28
// Design Name:
// Module Name: hazard_detection_unit
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


module hazard_detection_unit(
           input  [4:0] id_rs1,
           input  [4:0] id_rs2,
           input  [4:0] ex_rd,
           input  ex_mem_read,

           input  mispredict,

           output reg stall_if,
           output reg stall_id,
           output reg flush_id,
           output reg flush_ex
       );

always @(*) begin
    stall_id = 0;
    stall_if = 0;
    flush_ex = 0;
    flush_id = 0;

    if(mispredict) begin
        flush_id = 1;
        flush_ex = 1;
    end

    else if(ex_mem_read && (ex_rd != 0) && (ex_rd == id_rs1 || ex_rd == id_rs2)) begin
        stall_id = 1;
        stall_if = 1;
        flush_ex = 1;
    end

end

endmodule
