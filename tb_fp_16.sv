`timescale 1ns/1ps

module tb_fp16_multiplier;

    logic clk;
    logic rst_n;
    logic in_valid;
    logic [15:0] a, b;
    logic out_valid;
    logic [15:0] y;

    fp16_multiplier_pipe dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .a         (a),
        .b         (b),
        .out_valid (out_valid),
        .y         (y)
    );

    // Clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    typedef struct {
        logic [15:0] a;
        logic [15:0] b;
        logic [15:0] exp;
        int          issue_cycle;
    } tb_item_t;

    tb_item_t q[$];

    int cycle;
    int checked;
    int errors;
    int total_latency;

    // Leading zero count for 10-bit fraction
    function automatic int lzc10(input logic [9:0] x);
        int i;
        bit found;
        begin
            lzc10 = 10;
            found = 0;
            for (i = 9; i >= 0; i--) begin
                if (!found && x[i]) begin
                    lzc10 = 9 - i;
                    found = 1;
                end
            end
        end
    endfunction

    // Reference model: same behavior as RTL
    function automatic logic [15:0] fp16_mul_model(
        input logic [15:0] aa,
        input logic [15:0] bb
    );
        logic sign;
        logic a_nan, a_inf, a_zero;
        logic b_nan, b_inf, b_zero;
        logic [10:0] sig_a, sig_b;
        logic signed [8:0] exp_a, exp_b;
        logic [3:0] shift_a, shift_b;

        logic [21:0] prod, prod_norm;
        logic [10:0] mant11;
        logic [11:0] mant12;
        logic round_up;
        logic signed [9:0] exp_sum;
        logic signed [9:0] exp_field;

        begin
            sign = aa[15] ^ bb[15];

            a_nan  = (aa[14:10] == 5'h1F) && (aa[9:0] != 10'h000);
            a_inf  = (aa[14:10] == 5'h1F) && (aa[9:0] == 10'h000);
            a_zero = (aa[14:10] == 5'h00) && (aa[9:0] == 10'h000);

            b_nan  = (bb[14:10] == 5'h1F) && (bb[9:0] != 10'h000);
            b_inf  = (bb[14:10] == 5'h1F) && (bb[9:0] == 10'h000);
            b_zero = (bb[14:10] == 5'h00) && (bb[9:0] == 10'h000);

            if (a_nan || b_nan || (a_inf && b_zero) || (b_inf && a_zero)) begin
                fp16_mul_model = 16'h7E00;
            end else if (a_inf || b_inf) begin
                fp16_mul_model = {sign, 5'h1F, 10'h000};
            end else if (a_zero || b_zero) begin
                fp16_mul_model = {sign, 5'h00, 10'h000};
            end else begin
                // normalize A
                if (aa[14:10] == 5'h00) begin
                    shift_a = lzc10(aa[9:0]) + 1;
                    sig_a   = ({1'b0, aa[9:0]} << shift_a);
                    exp_a   = -9'sd14 - $signed({5'b0, shift_a});
                end else begin
                    sig_a = {1'b1, aa[9:0]};
                    exp_a = $signed({4'b0000, aa[14:10]}) - 9'sd15;
                end

                // normalize B
                if (bb[14:10] == 5'h00) begin
                    shift_b = lzc10(bb[9:0]) + 1;
                    sig_b   = ({1'b0, bb[9:0]} << shift_b);
                    exp_b   = -9'sd14 - $signed({5'b0, shift_b});
                end else begin
                    sig_b = {1'b1, bb[9:0]};
                    exp_b = $signed({4'b0000, bb[14:10]}) - 9'sd15;
                end

                prod      = sig_a * sig_b;
                prod_norm = prod;
                exp_sum   = exp_a + exp_b;

                if (prod[21]) begin
                    prod_norm = prod >> 1;
                    exp_sum   = exp_sum + 1;
                end

                mant11   = prod_norm[20:10];
                round_up = prod_norm[9] &
                           (prod_norm[8] | (|prod_norm[7:0]) | mant11[0]);
                mant12   = {1'b0, mant11} + round_up;

                if (mant12[11]) begin
                    mant11  = mant12[11:1];
                    exp_sum = exp_sum + 1;
                end else begin
                    mant11 = mant12[10:0];
                end

                exp_field = exp_sum + 10'sd15;

                if (exp_field >= 10'sd31) begin
                    fp16_mul_model = {sign, 5'h1F, 10'h000};
                end else if (exp_field <= 10'sd0) begin
                    fp16_mul_model = {sign, 5'h00, 10'h000};
                end else begin
                    fp16_mul_model = {sign, exp_field[4:0], mant11[9:0]};
                end
            end
        end
    endfunction

    function automatic logic [15:0] rand_fp16();
        begin
            rand_fp16 = logic'($urandom());
        end
    endfunction

    task automatic send_vec(input logic [15:0] aa, input logic [15:0] bb);
        tb_item_t item;
        begin
            @(negedge clk);
            a        = aa;
            b        = bb;
            in_valid = 1'b1;

            item.a = aa;
            item.b = bb;
            item.exp = fp16_mul_model(aa, bb);
            item.issue_cycle = cycle + 1; // sampled on next posedge
            q.push_back(item);
        end
    endtask

    // VCD dump
    initial begin
        $dumpfile("fp16_mul_1000.vcd");
        $dumpvars(0, tb_fp16_multiplier);
    end

    // Main stimulus + checker
    initial begin
        int i;

        a = '0;
        b = '0;
        in_valid = 1'b0;
        rst_n = 1'b0;

        cycle = 0;
        checked = 0;
        errors = 0;
        total_latency = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        // Optional directed edge cases first
        send_vec(16'h0000, 16'h3C00); // +0 * +1
        send_vec(16'h8000, 16'h3C00); // -0 * +1
        send_vec(16'h3C00, 16'h3C00); // 1 * 1
        send_vec(16'hC000, 16'h4000); // -2 * 2
        send_vec(16'h7C00, 16'h3C00); // +inf * 1
        send_vec(16'h7C00, 16'h0000); // inf * 0 -> NaN
        send_vec(16'h7E00, 16'h3C00); // NaN * 1
        send_vec(16'h0400, 16'h0400); // smallest normal * smallest normal
        send_vec(16'h0001, 16'h3C00); // subnormal * 1
        send_vec(16'h7BFF, 16'h3C00); // max normal * 1

        // Random 1000-case run total
        for (i = 10; i < 1000; i++) begin
            send_vec(rand_fp16(), rand_fp16());
        end

        @(negedge clk);
        in_valid = 1'b0;
        a = '0;
        b = '0;

        // Flush the pipeline
        wait (q.size() == 0);

        $display("--------------------------------------------------");
        $display("Checked     : %0d", checked);
        $display("Mismatches  : %0d", errors);
        if (checked > 0) begin
            $display("Avg latency : %0f cycles", real'(total_latency) / real'(checked));
        end
        $display("Queue left  : %0d", q.size());
        $display("--------------------------------------------------");

        $finish;
    end

    // Cycle counter and scoreboard
    always @(posedge clk or negedge rst_n) begin
        tb_item_t item;
        int latency;

        if (!rst_n) begin
            cycle = 0;
        end else begin
            cycle = cycle + 1;

            if (out_valid) begin
                if (q.size() == 0) begin
                    $display("[%0t] ERROR: output seen with empty queue", $time);
                    errors = errors + 1;
                end else begin
                    item = q.pop_front();
                    latency = cycle - item.issue_cycle;

                    checked = checked + 1;
                    total_latency = total_latency + latency;

                    if (y !== item.exp) begin
                        errors = errors + 1;
                        $display("[%0t] MISMATCH  A=%h B=%h  DUT=%h  EXP=%h  LAT=%0d",
                                 $time, item.a, item.b, y, item.exp, latency);
                    end else begin
                        $display("[%0t] PASS      A=%h B=%h  Y=%h  LAT=%0d",
                                 $time, item.a, item.b, y, latency);
                    end
                end
            end
        end
    end

endmodule