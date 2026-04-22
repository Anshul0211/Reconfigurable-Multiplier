`timescale 1ns/1ps

module tb_reconfig_multi_check;

    parameter int MAX_TOTAL_BITS = 16;
    parameter int MAX_EXP_BITS   = 8;
    parameter int MAX_MAN_BITS   = 14;

    logic                        clk;
    logic                        rst_n;
    logic                        start;
    logic                        ready;
    logic                        valid;
    logic [4:0]                  total_bits;
    logic [3:0]                  exp_bits;
    logic [MAX_TOTAL_BITS-1:0]   A, B;
    logic [MAX_TOTAL_BITS-1:0]   result;

    // Instantiate the Top-Level Wrapper
    reconfig_fp_top #(
        .MAX_TOTAL_BITS(MAX_TOTAL_BITS),
        .MAX_EXP_BITS(MAX_EXP_BITS),
        .MAX_MAN_BITS(MAX_MAN_BITS)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .ready      (ready),
        .valid      (valid),
        .total_bits (total_bits),
        .exp_bits   (exp_bits),
        .A          (A),
        .B          (B),
        .result     (result)
    );

    // Clock Generation - 100MHz
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Statistics
    int pass_cnt = 0, fail_cnt = 0, test_num = 0;

    // Waveform Dump for Genus Power Analysis
    initial begin
        $dumpfile("fp_power_switching.vcd");
        $dumpvars(0, tb_reconfig_fp_top);
    end

    // Timeout Watchdog
    initial begin
        #500_000;
        $display("\n[TIMEOUT] Simulation exceeded 500 us.");
        $finish;
    end

    // -----------------------------------------------------------------------
    // Arbitrary Precision Floating-Point Reference Model
    // -----------------------------------------------------------------------
    function automatic logic [31:0] ref_fp_mult(
        input logic [31:0] valA, 
        input logic [31:0] valB, 
        input logic [4:0]  t_bits, 
        input logic [3:0]  e_bits
    );
        int m_bits, bias, max_exp;
        logic sign_a, sign_b, sign_res;
        int exp_a, exp_b;
        logic [31:0] man_a, man_b;
        logic [63:0] mult_res;
        int calc_exp;
        logic overflow;
        logic [31:0] norm_man;
        
        m_bits  = t_bits - e_bits - 1;
        bias    = (1 << (e_bits - 1)) - 1;
        max_exp = (1 << e_bits) - 1;

        // Zero Check
        if (valA == 0 || valB == 0) return 0;

        // Extract
        sign_a = (valA >> (t_bits - 1)) & 1;
        sign_b = (valB >> (t_bits - 1)) & 1;
        sign_res = sign_a ^ sign_b;

        exp_a = (valA >> m_bits) & max_exp;
        exp_b = (valB >> m_bits) & max_exp;

        man_a = valA & ((1 << m_bits) - 1);
        man_b = valB & ((1 << m_bits) - 1);

        // Inject Hidden Bits
        man_a = (1 << m_bits) | man_a;
        man_b = (1 << m_bits) | man_b;

        // Mantissa Multiply
        mult_res = man_a * man_b;

        // Normalize (Find where the hidden bit landed)
        overflow = (mult_res >> (m_bits * 2 + 1)) & 1;
        
        if (overflow) begin
            norm_man = (mult_res >> (m_bits + 1)) & ((1 << m_bits) - 1);
            calc_exp = exp_a + exp_b - bias + 1;
        end else begin
            norm_man = (mult_res >> m_bits) & ((1 << m_bits) - 1);
            calc_exp = exp_a + exp_b - bias;
        end

        // Exceptions
        if (calc_exp >= max_exp) begin
            return (sign_res << (t_bits - 1)) | (max_exp << m_bits); // Infinity
        end else if (calc_exp <= 0) begin
            return 0; // Underflow to Zero
        end

        // Pack
        return (sign_res << (t_bits - 1)) | (calc_exp << m_bits) | norm_man;
    endfunction

    // -----------------------------------------------------------------------
    // Core Test Task (Using valid/ready handshake)
    // -----------------------------------------------------------------------
    task automatic run_fp_test(
        input string       test_name,
        input logic [4:0]  t_bits,
        input logic [3:0]  e_bits,
        input logic [31:0] valA,
        input logic [31:0] valB
    );
        int start_time, end_time, latency;
        logic [31:0] expected_res;
        
        test_num++;
        
        // Calculate Software Expected Result
        expected_res = ref_fp_mult(valA, valB, t_bits, e_bits);

        // Wait for DUT to be ready
        wait(ready == 1'b1);
        @(negedge clk);
        
        // Drive Inputs
        total_bits = t_bits;
        exp_bits   = e_bits;
        A          = valA;
        B          = valB;
        start      = 1'b1;
        start_time = $time;
        
        @(negedge clk);
        start = 1'b0;
        
        // Wait for Valid signal
        wait(valid == 1'b1);
        end_time = $time;
        latency = (end_time - start_time) / 10;
        
        @(negedge clk);
        
        if (result === expected_res[MAX_TOTAL_BITS-1:0]) begin
            pass_cnt++;
            $display("[%04d PASS] %-25s | Prec: (%0d,%0d) | 0x%04h * 0x%04h = 0x%04h | Latency: %0d",
                     test_num, test_name, t_bits, e_bits, valA, valB, result, latency);
        end else begin
            fail_cnt++;
            $display("[%04d FAIL] %-25s | Prec: (%0d,%0d) | 0x%04h * 0x%04h",
                     test_num, test_name, t_bits, e_bits, valA, valB);
            $display("           GOT: 0x%04h  |  EXPECTED: 0x%04h", result, expected_res);
        end
    endtask

    // -----------------------------------------------------------------------
    // Main Stimulus Sequence
    // -----------------------------------------------------------------------
    initial begin
        rst_n = 0; start = 0;
        total_bits = 8; exp_bits = 4;
        A = 0; B = 0;
        
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        $display("\n============================================================");
        $display("  Reconfigurable FP Datapath Testbench (FP4 to FP16)");
        $display("============================================================\n");

        // --- 1. Ultra-Low Precision (FP4) ---
        // Format (4, 2): 1 Sign, 2 Exp (Bias 1), 1 Man
        // A = 0x6 (0_11_0) = 1.0 * 2^(3-1) = 4.0
        // B = 0x6 (0_11_0) = 1.0 * 2^(3-1) = 4.0 -> Result Overflows to Infinity (0x7)
        run_fp_test("FP4 (4, 2) Overflow",   4, 2, 16'h0006, 16'h0006);
        run_fp_test("FP4 (4, 2) Normal",     4, 2, 16'h0002, 16'h0002);

        // --- 2. 8-Bit AI Formats (FP8 E4M3) ---
        // 1.5 * 1.5 = 2.25
        // 1.5  = 0x3C (0_0111_100)
        // 2.25 = 0x41 (0_1000_001) -> Notice the exponent incremented!
        run_fp_test("FP8 (8, 4) 1.5 * 1.5",  8, 4, 16'h003C, 16'h003C);
        run_fp_test("FP8 (8, 4) 1.0 * 2.0",  8, 4, 16'h0038, 16'h0040);
        run_fp_test("FP8 (8, 4) Zero",       8, 4, 16'h003C, 16'h0000);

        // --- 3. AlexNet Custom (FP14) ---
        // 1.0 * 1.0 = 1.0
        run_fp_test("FP14 (14, 5) 1.0*1.0", 14, 5, 16'h1E00, 16'h1E00);
        run_fp_test("FP14 (14, 5) Underflow",14, 5, 16'h0200, 16'h0200);

        // --- 4. Standard Half-Precision (IEEE FP16) ---
        // Format (16, 5): 1 Sign, 5 Exp (Bias 15), 10 Man
        run_fp_test("IEEE FP16 (16, 5)",    16, 5, 16'h3C00, 16'h3C00); // 1.0 * 1.0
        run_fp_test("IEEE FP16 Negative",   16, 5, 16'hBC00, 16'h3C00); // -1.0 * 1.0
        
        // --- 5. BFloat16 ---
        // Format (16, 8): 1 Sign, 8 Exp (Bias 127), 7 Man
        run_fp_test("BFloat16 (16, 8)",     16, 8, 16'h3F80, 16'h3F80); // 1.0 * 1.0

        $display("\n============================================================");
        if (fail_cnt == 0) $display("  *** ALL DATAPATH TESTS PASSED ***");
        else               $display("  *** %0d FAILURES DETECTED ***", fail_cnt);
        $display("============================================================\n");
        $finish;
    end
endmodule