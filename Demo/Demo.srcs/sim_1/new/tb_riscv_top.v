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
        forever #5 clk = ~clk; 
    end

    initial begin

        $readmemh("test.hex", u_dut.u_imem.rom); 
        
        rst_n = 1;
        #10;
        rst_n = 0;  // 复位有效
        #20;
        rst_n = 1;  // 复位释放，CPU 开始运行

        $display("Simulation Start!");
        
        #2000;
        
        $display("Simulation Timeout.");
        $finish;
    end

    always @(posedge clk) begin
        if (u_dut.wb_reg_write && u_dut.wb_rd != 0) begin
            $display("Time %t: Write Reg x%0d = %h", $time, u_dut.wb_rd, u_dut.wb_final_data);
        end
    end

endmodule