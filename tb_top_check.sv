`timescale 1ns/1ps

module tb_reconfig_fp_top;

    // Up-sized to 16 to handle your largest (15,4) format safely
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

    // Timeout Watchdog
    initial begin
        #500_000;
        $display("\n[TIMEOUT] Simulation exceeded 500 us.");
        $finish;
    end

    // -----------------------------------------------------------------------
    // Arbitrary Precision Floating-Point Reference Model (Software Math)
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

        if (valA == 0 || valB == 0) return 0;

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

        // Pack Final Result
        return (sign_res << (t_bits - 1)) | (calc_exp << m_bits) | norm_man;
    endfunction

    // -----------------------------------------------------------------------
    // Core Test Task
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
        expected_res = ref_fp_mult(valA, valB, t_bits, e_bits);

        // Wait for DUT to be ready
        wait(ready == 1'b1);
        @(negedge clk);
        
        total_bits = t_bits;
        exp_bits   = e_bits;
        A          = valA;
        B          = valB;
        start      = 1'b1;
        start_time = $time;
        
        @(negedge clk);
        start = 1'b0;
        
        // Use safe named-block fork/join to prevent Vivado freezing
        fork
            begin : wait_valid
                wait(valid == 1'b1);
            end
        join
        
        end_time = $time;
        latency = (end_time - start_time) / 10;
        
        @(negedge clk);
        
        if (result === expected_res[MAX_TOTAL_BITS-1:0]) begin
            pass_cnt++;
            $display("[%04d PASS] %-18s | Prec: (%02d,%0d) | 0x%04h * 0x%04h = 0x%04h | Latency: %0d",
                     test_num, test_name, t_bits, e_bits, valA, valB, result, latency);
        end else begin
            fail_cnt++;
            $display("[%04d FAIL] %-18s | Prec: (%02d,%0d) | 0x%04h * 0x%04h",
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
        $display("  FULL FLOATING-POINT DATAPATH: 1.5 * 1.5 = 2.25");
        $display("============================================================\n");

        // CORRECTED VALUES: 1.5 represented in the given formats
        run_fp_test("Layer 1: (8, 3)",   8, 3, 16'h0038, 16'h0038);
        run_fp_test("Layer 2: (3, 1)",   3, 1, 16'h0003, 16'h0003); 
        run_fp_test("Layer 3: (5, 1)",   5, 1, 16'h000C, 16'h000C);
        run_fp_test("Layer 4: (4, 1)",   4, 1, 16'h0006, 16'h0006); 
        
        // Mid precision
        run_fp_test("Layer 5: (7, 2)",   7, 2, 16'h0018, 16'h0018); 
        
        // Tiny precision
        run_fp_test("Layer 6: (6, 1)",   6, 1, 16'h0018, 16'h0018); 
        
        // Baseline comparison
        run_fp_test("Layer 7: (8, 4)",   8, 4, 16'h003C, 16'h003C);

        $display("\n============================================================");
        if (fail_cnt == 0) $display("  *** ALL DATAPATH TESTS PASSED ***");
        else               $display("  *** %0d FAILURES DETECTED ***", fail_cnt);
        $display("============================================================\n");
        $finish;
    end
endmodule