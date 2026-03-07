`timescale 1ns / 1ps

module tb_riscv_top;

reg clk;
reg rst_n;

riscv_top u_dut (
              .clk(clk),
              .rst_n(rst_n)
          );

initial begin
    clk = 0;
    forever
        #5 clk = ~clk;
end

integer trace_file;

initial begin
    // 读取机器码
    $readmemh("test.hex", u_dut.u_imem.rom);

    // 创建 trace.log 文件
    trace_file = $fopen("trace.log", "w");
    if (trace_file == 0) begin
        $display("Error: Failed to open trace.log!");
        $finish;
    end
    $fdisplay(trace_file, "========================================================================");
    $fdisplay(trace_file, " Time(ns) | Action Type | Details");
    $fdisplay(trace_file, "========================================================================");

    rst_n = 1;
    #10;
    rst_n = 0;  // 复位有效
    #20;
    rst_n = 1;  // 复位释放，CPU 开始运行

    $display("Simulation Start! Generating trace.log...");

    #5000; // 仿真时间

    $display("Simulation Timeout. Check trace.log for detailed execution trace!");
    $fclose(trace_file);
    $finish;
end

// 在时钟下降沿捕获稳定状态
always @(negedge clk) begin
    if (rst_n) begin
        // 监控寄存器写回 (WB 阶段)
        if (u_dut.wb_reg_write && u_dut.wb_rd != 0 && !u_dut.wb_fp_write) begin
            $fdisplay(trace_file, "%9t | REG_WRITE   | x%0d <= 0x%08h",
                      $time, u_dut.wb_rd, u_dut.wb_final_data);
            $display("Time %9t: Write Reg x%0d = %08h", $time, u_dut.wb_rd, u_dut.wb_final_data);
        end

        // 监控浮点寄存器写回
        if (u_dut.wb_fp_write) begin
            $fdisplay(trace_file, "%9t | FPR_WRITE   | f%0d <= 0x%08h",
                      $time, u_dut.wb_rd, u_dut.wb_final_data);
            $display("Time %9t: Write FPR f%0d = %08h", $time, u_dut.wb_rd, u_dut.wb_final_data);
        end

        // 监控内存写入 (MEM 阶段)
        if (u_dut.u_mem_ctrl.mem_write_en) begin
            $fdisplay(trace_file, "%9t | MEM_WRITE   | Addr: 0x%08h, Data: 0x%08h",
                      $time, u_dut.u_mem_ctrl.addr, u_dut.u_mem_ctrl.dmem_wdata);
        end

        // 监控异常与中断陷入
        if (u_dut.u_csr.irq_trap || u_dut.u_csr.trap_en) begin
            $fdisplay(trace_file, "%9t | TRAP_ENTRY  | PC: 0x%08h, Cause: %0d, Jump to: 0x%08h",
                      $time, u_dut.u_csr.trap_pc, u_dut.u_csr.mcause, u_dut.u_csr.mtvec_out);
        end

        // 监控异常返回
        if (u_dut.u_csr.is_mret) begin
            $fdisplay(trace_file, "%9t | TRAP_MRET   | Return to: 0x%08h",
                      $time, u_dut.u_csr.mepc_out);
        end

        // 监控分支预测纠错冲刷
        if (u_dut.mispredict) begin
            $fdisplay(trace_file, "%9t | MISPREDICT  | Flush Triggered, Redirect to: 0x%08h",
                      $time, u_dut.u_if_stage.correct_pc);
        end
    end
end

endmodule
