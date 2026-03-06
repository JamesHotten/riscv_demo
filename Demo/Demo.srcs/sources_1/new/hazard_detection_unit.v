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

           input  ex_ecall,
           input  ex_mret,

           input  irq_trap,

           output reg stall_if,
           output reg stall_id,
           output reg flush_id,
           output reg flush_ex,
           output reg flush_mem
       );

always @(*) begin
    stall_id = 0;
    stall_if = 0;
    flush_ex = 0;
    flush_id = 0;
    flush_mem = 0;

    // 异步中断或系统调用(ECALL)：
    // 正在 EX 阶段的指令被中止，保存其 PC，因此要杀掉它不让它进 MEM 阶段生效
    if (irq_trap || ex_ecall) begin
        flush_id = 1;
        flush_ex = 1;
        flush_mem = 1;
    end
    // 分支预测失败或异常返回(MRET)：
    // 分支指令和 MRET 本身正在 EX 阶段，它们必须正常执行完毕，只冲刷前面的流水线
    else if (mispredict || ex_mret) begin
        flush_id = 1;
        flush_ex = 1;
    end
    // Load-Use 数据冒险停顿
    else if(ex_mem_read && (ex_rd != 0) && (ex_rd == id_rs1 || ex_rd == id_rs2)) begin
        stall_id = 1;
        stall_if = 1;
        flush_ex = 1;
    end

end

endmodule
