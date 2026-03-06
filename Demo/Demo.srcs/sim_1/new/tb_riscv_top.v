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

initial begin

    $readmemh("test.hex", u_dut.u_imem.rom);

    rst_n = 1;
    #10;
    rst_n = 0;  // 复位有效
    #20;
    rst_n = 1;  // 复位释放，CPU 开始运行

    $display("Simulation Start!");

    #5000;

    $display("Simulation Timeout.");
    $finish;
end

always @(posedge clk) begin
    if (u_dut.wb_reg_write && u_dut.wb_rd != 0) begin
        $display("Time %t: Write Reg x%0d = %h", $time, u_dut.wb_rd, u_dut.wb_final_data);
    end
end

always @(posedge clk) begin
    if (u_dut.u_csr.irq_trap) begin
        $display("==================================================");
        $display("Time %t: [TRAP] Timer Interrupt Triggered!", $time);
        $display("  -> Saving to MEPC   : %h", u_dut.u_csr.trap_pc);
        $display("  -> ID Stage PC      : %h", u_dut.id_pc);
        $display("  -> EX Stage PC      : %h (Valid: %b)", u_dut.ex_pc, u_dut.ex_valid);
        $display("  -> EX Stage Op      : Write Reg x%0d", u_dut.u_id_ex_reg.ex_rd); // 假设你的 id_ex_reg 例化名为 u_id_ex_reg
        $display("==================================================");
    end

    // 监视一下 MRET 异常返回的瞬间
    if (u_dut.u_csr.is_mret) begin
        $display("Time %t: [MRET] Return from Interrupt! Jumping back to: %h", $time, u_dut.u_csr.mepc_out);
    end
end

endmodule
