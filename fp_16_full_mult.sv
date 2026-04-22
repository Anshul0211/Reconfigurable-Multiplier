`timescale 1ns/1ps

module fp16_multiplier_pipe (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        in_valid,
    input  logic [15:0]  a,
    input  logic [15:0]  b,
    output logic        out_valid,
    output logic [15:0]  y
);

    typedef enum logic [1:0] {
        SP_NONE = 2'd0,
        SP_ZERO = 2'd1,
        SP_INF  = 2'd2,
        SP_NAN  = 2'd3
    } special_t;

    // Stage 0: input registers
    logic [15:0] a0, b0;
    logic        v0;

    // Stage 1: decoded/normalized registers
    logic        sign1_q, sign1_d;
    special_t    special1_q, special1_d;
    logic [10:0] sig_a1_q, sig_a1_d;
    logic [10:0] sig_b1_q, sig_b1_d;
    logic signed [8:0] exp_a1_q, exp_a1_d;
    logic signed [8:0] exp_b1_q, exp_b1_d;
    logic        v1;

    // Stage 2: computed result register
    logic [15:0] result2_q, result2_d;
    logic        v2;

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

    // Stage 0: input flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a0 <= '0;
            b0 <= '0;
            v0 <= 1'b0;
        end else begin
            a0 <= a;
            b0 <= b;
            v0 <= in_valid;
        end
    end

    // Stage 1 combinational decode
    always_comb begin
        logic a_nan, a_inf, a_zero;
        logic b_nan, b_inf, b_zero;
        logic [3:0] shift_a, shift_b;

        sign1_d    = a0[15] ^ b0[15];
        special1_d = SP_NONE;
        sig_a1_d   = '0;
        sig_b1_d   = '0;
        exp_a1_d   = '0;
        exp_b1_d   = '0;

        a_nan  = (a0[14:10] == 5'h1F) && (a0[9:0] != 10'h000);
        a_inf  = (a0[14:10] == 5'h1F) && (a0[9:0] == 10'h000);
        a_zero = (a0[14:10] == 5'h00) && (a0[9:0] == 10'h000);

        b_nan  = (b0[14:10] == 5'h1F) && (b0[9:0] != 10'h000);
        b_inf  = (b0[14:10] == 5'h1F) && (b0[9:0] == 10'h000);
        b_zero = (b0[14:10] == 5'h00) && (b0[9:0] == 10'h000);

        if (a_nan || b_nan || (a_inf && b_zero) || (b_inf && a_zero)) begin
            special1_d = SP_NAN;
        end else if (a_inf || b_inf) begin
            special1_d = SP_INF;
        end else if (a_zero || b_zero) begin
            special1_d = SP_ZERO;
        end else begin
            special1_d = SP_NONE;
        end

        if (!a_nan && !a_inf && !a_zero) begin
            if (a0[14:10] == 5'h00) begin
                shift_a  = lzc10(a0[9:0]) + 1;
                sig_a1_d = ({1'b0, a0[9:0]} << shift_a);
                exp_a1_d = -9'sd14 - $signed({5'b0, shift_a});
            end else begin
                sig_a1_d = {1'b1, a0[9:0]};
                exp_a1_d = $signed({4'b0000, a0[14:10]}) - 9'sd15;
            end
        end

        if (!b_nan && !b_inf && !b_zero) begin
            if (b0[14:10] == 5'h00) begin
                shift_b  = lzc10(b0[9:0]) + 1;
                sig_b1_d = ({1'b0, b0[9:0]} << shift_b);
                exp_b1_d = -9'sd14 - $signed({5'b0, shift_b});
            end else begin
                sig_b1_d = {1'b1, b0[9:0]};
                exp_b1_d = $signed({4'b0000, b0[14:10]}) - 9'sd15;
            end
        end
    end

    // Stage 1 flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign1_q    <= 1'b0;
            special1_q <= SP_NONE;
            sig_a1_q   <= '0;
            sig_b1_q   <= '0;
            exp_a1_q   <= '0;
            exp_b1_q   <= '0;
            v1         <= 1'b0;
        end else begin
            sign1_q    <= sign1_d;
            special1_q <= special1_d;
            sig_a1_q   <= sig_a1_d;
            sig_b1_q   <= sig_b1_d;
            exp_a1_q   <= exp_a1_d;
            exp_b1_q   <= exp_b1_d;
            v1         <= v0;
        end
    end

    // Stage 2 combinational compute
    always_comb begin
        logic [21:0] prod, prod_norm;
        logic [10:0] mant11;
        logic [11:0] mant12;
        logic round_up;
        logic signed [9:0] exp_sum;
        logic signed [9:0] exp_field;

        result2_d = 16'h0000;

        if (special1_q == SP_NAN) begin
            result2_d = 16'h7E00; // quiet NaN
        end else if (special1_q == SP_INF) begin
            result2_d = {sign1_q, 5'h1F, 10'h000};
        end else if (special1_q == SP_ZERO) begin
            result2_d = {sign1_q, 5'h00, 10'h000};
        end else begin
            prod      = sig_a1_q * sig_b1_q;
            prod_norm = prod;
            exp_sum   = exp_a1_q + exp_b1_q;

            if (prod[21]) begin
                prod_norm = prod >> 1;
                exp_sum   = exp_sum + 1;
            end

            mant11   = prod_norm[20:10];
            round_up = prod_norm[9] &
                       (prod_norm[8] | (|prod_norm[7:0]) | mant11[0]);

            mant12 = {1'b0, mant11} + round_up;

            if (mant12[11]) begin
                mant11  = mant12[11:1];
                exp_sum = exp_sum + 1;
            end else begin
                mant11 = mant12[10:0];
            end

            exp_field = exp_sum + 10'sd15;

            if (exp_field >= 10'sd31) begin
                result2_d = {sign1_q, 5'h1F, 10'h000};
            end else if (exp_field <= 10'sd0) begin
                result2_d = {sign1_q, 5'h00, 10'h000}; // flush underflow to zero
            end else begin
                result2_d = {sign1_q, exp_field[4:0], mant11[9:0]};
            end
        end
    end

    // Stage 2 flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result2_q <= 16'h0000;
            v2        <= 1'b0;
        end else begin
            result2_q <= result2_d;
            v2        <= v1;
        end
    end

    // Stage 3 output flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y         <= 16'h0000;
            out_valid <= 1'b0;
        end else begin
            y         <= result2_q;
            out_valid <= v2;
        end
    end

endmodule