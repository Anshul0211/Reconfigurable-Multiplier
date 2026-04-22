`timescale 1ns/1ps

module dynamic_exp_unit #(
    parameter MAX_EXP_BITS = 8
)(
    input  logic [3:0]              exp_bits,
    input  logic [MAX_EXP_BITS-1:0] exp_a,
    input  logic [MAX_EXP_BITS-1:0] exp_b,
    input  logic                    norm_shift, // +1 from mantissa overflow
    
    output logic [MAX_EXP_BITS-1:0] final_exp,
    output logic                    is_infinity,
    output logic                    is_zero
);

    logic signed [MAX_EXP_BITS+2:0] calc_exp; // Extra width for sign and overflow detection
    logic signed [MAX_EXP_BITS+2:0] bias;
    logic signed [MAX_EXP_BITS+2:0] max_exp_val;

    always_comb begin
        // 1. Dynamically calculate the Bias and Max boundaries
        bias = (1 << (exp_bits - 1)) - 1;
        max_exp_val = (1 << exp_bits) - 1;
        
        // 2. Base Exponent Math (E_A + E_B - Bias + Normalization_Shift)
        // Explicit signed casts to ensure negative numbers are tracked correctly
        calc_exp = $signed({1'b0, exp_a}) + $signed({1'b0, exp_b}) - bias + $signed({1'b0, norm_shift});
        
        // 3. Exception Checking
        if (calc_exp >= max_exp_val) begin
            // Overflow: Peg to maximum value (Infinity representation)
            final_exp   = max_exp_val; 
            is_infinity = 1'b1;
            is_zero     = 1'b0;
        end else if (calc_exp <= 0) begin
            // Underflow: Peg to minimum value (Flush to Zero)
            final_exp   = 0; 
            is_infinity = 1'b0;
            is_zero     = 1'b1;
        end else begin
            // Normal operation
            final_exp   = calc_exp[MAX_EXP_BITS-1:0];
            is_infinity = 1'b0;
            is_zero     = 1'b0;
        end
    end

endmodule