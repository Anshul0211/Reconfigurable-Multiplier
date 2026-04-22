`timescale 1ns/1ps

module reconfig_fp_top #(
    parameter MAX_TOTAL_BITS = 16,
    parameter MAX_EXP_BITS   = 8,
    parameter MAX_MAN_BITS   = 14
)(
    input  logic                      clk,
    input  logic                      rst_n,
    
    // Control Handshake
    input  logic                      start,
    output logic                      ready,
    output logic                      valid,
    
    // Dynamic Configuration
    input  logic [4:0]                total_bits, 
    input  logic [3:0]                exp_bits,   
    
    // Operands
    input  logic [MAX_TOTAL_BITS-1:0] A,
    input  logic [MAX_TOTAL_BITS-1:0] B,
    
    // Result
    output logic [MAX_TOTAL_BITS-1:0] result
);

    // ========================================================================
    // INPUT PIPELINE FFs  (NEW)
    // Registers A, B, total_bits, exp_bits one cycle after port capture
    // ========================================================================
   logic [MAX_TOTAL_BITS-1:0] A_ff,          B_ff;
    logic [4:0]                total_bits_ff;
    logic [3:0]                exp_bits_ff;
    logic                      start_ff;          // <-- ADD THIS

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_ff          <= '0;
            B_ff          <= '0;
            total_bits_ff <= '0;
            exp_bits_ff   <= '0;
            start_ff      <= 1'b0;              // <-- ADD THIS
        end else begin
            A_ff          <= A;
            B_ff          <= B;
            total_bits_ff <= total_bits;
            exp_bits_ff   <= exp_bits;
            start_ff      <= start;             // <-- ADD THIS
        end
    end
    // ------------------------------------------------------------------------
    // 1. Dynamic Bit Extraction  (now uses _ff operands)
    // ------------------------------------------------------------------------
    logic [4:0] man_bits;
    assign man_bits = total_bits_ff - exp_bits_ff - 1;

    logic sign_a, sign_b;
    logic [MAX_EXP_BITS-1:0] exp_a, exp_b;
    logic [MAX_MAN_BITS-1:0] man_a, man_b;
    
    always_comb begin
        sign_a = (A_ff >> (total_bits_ff - 1)) & 1'b1;
        sign_b = (B_ff >> (total_bits_ff - 1)) & 1'b1;
        
        exp_a  = (A_ff >> man_bits) & ((1 << exp_bits_ff) - 1);
        exp_b  = (B_ff >> man_bits) & ((1 << exp_bits_ff) - 1);
        
        man_a  = A_ff & ((1 << man_bits) - 1);
        man_b  = B_ff & ((1 << man_bits) - 1);
    end

    // ------------------------------------------------------------------------
    // 2. Instantiate the Radix-4 Mantissa Core
    // ------------------------------------------------------------------------
    logic [3:0] mult_precision;
    assign mult_precision = man_bits + 1;

    logic [2*MAX_MAN_BITS-1:0] mult_result;
    logic                      mult_result_sign;
    logic                      mult_done;
    logic                      mult_busy;

   precision_gated_radix4_mult #(
        .MAX_MAN_BITS(MAX_MAN_BITS)
    ) mantissa_core (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start_ff),    // <-- WAS start, NOW start_ff
        .precision   (mult_precision),
        .A           (man_a),
        .B           (man_b),
        .sign_a      (sign_a),
        .sign_b      (sign_b),
        .is_float    (1'b1),
        .result      (mult_result),
        .result_sign (mult_result_sign),
        .done        (mult_done),
        .busy        (mult_busy)
    );
    // ------------------------------------------------------------------------
    // 3. Normalization Detection
    // ------------------------------------------------------------------------
    logic overflow;
    logic [MAX_MAN_BITS-1:0] normalized_man;

    always_comb begin
        overflow = mult_result[man_bits * 2 + 1];
        
        if (overflow) begin
            normalized_man = (mult_result >> (man_bits + 1)) & ((1 << man_bits) - 1);
        end else begin
            normalized_man = (mult_result >> man_bits) & ((1 << man_bits) - 1);
        end
    end

    // ------------------------------------------------------------------------
    // 4. Instantiate the Exponent Unit
    // ------------------------------------------------------------------------
    logic [MAX_EXP_BITS-1:0] final_exp;
    logic                    is_infinity;
    logic                    is_zero;

    dynamic_exp_unit #(
        .MAX_EXP_BITS(MAX_EXP_BITS)
    ) exp_core (
        .exp_bits    (exp_bits_ff),
        .exp_a       (exp_a),
        .exp_b       (exp_b),
        .norm_shift  (overflow),
        .final_exp   (final_exp),
        .is_infinity (is_infinity),
        .is_zero     (is_zero)
    );

    // ------------------------------------------------------------------------
    // 5. Pre-Output Logic (drives internal signals, NOT ports directly)
    // ------------------------------------------------------------------------
    logic is_input_zero;
    assign is_input_zero = (A_ff == 0 || B_ff == 0);

    // Internal staging signals (NEW)
    logic                      valid_pre;
    logic                      ready_pre;
    logic [MAX_TOTAL_BITS-1:0] result_pre;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pre  <= 1'b0;
            result_pre <= '0;
            ready_pre  <= 1'b1;
        end else begin
            valid_pre <= 1'b0;
            
            if (start_ff) begin
                ready_pre <= 1'b0;
            end 
            else if (mult_done) begin
                valid_pre <= 1'b1;
                ready_pre <= 1'b1;
                
                result_pre <= '0; 
                
                if (is_input_zero || is_zero) begin
                    result_pre <= '0;
                end else if (is_infinity) begin
                    result_pre <= (mult_result_sign << (total_bits_ff - 1)) | 
                                  (((1 << exp_bits_ff) - 1) << man_bits);
                end else begin
                    result_pre <= (mult_result_sign << (total_bits_ff - 1)) | 
                                  (final_exp << man_bits) | 
                                  normalized_man;
                end
            end
        end
    end

    // ========================================================================
    // OUTPUT PIPELINE FFs  (NEW)
    // Final register stage before result/valid/ready reach the ports
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= '0;
            valid  <= 1'b0;
            ready  <= 1'b1;
        end else begin
            result <= result_pre;
            valid  <= valid_pre;
            ready  <= ready_pre;
        end
    end

endmodule

//`timescale 1ns/1ps

//module reconfig_fp_top #(
//    parameter MAX_TOTAL_BITS = 16,
//    parameter MAX_EXP_BITS   = 8,
//    parameter MAX_MAN_BITS   = 14
//)(
//    input  logic                      clk,
//    input  logic                      rst_n,
    
//    // Control Handshake
//    input  logic                      start,
//    output logic                      ready,
//    output logic                      valid,
    
//    // Dynamic Configuration
//    input  logic [4:0]                total_bits, 
//    input  logic [3:0]                exp_bits,   
    
//    // Operands
//    input  logic [MAX_TOTAL_BITS-1:0] A,
//    input  logic [MAX_TOTAL_BITS-1:0] B,
    
//    // Result
//    output logic [MAX_TOTAL_BITS-1:0] result
//);

//    // ------------------------------------------------------------------------
//    // 1. Dynamic Bit Extraction
//    // ------------------------------------------------------------------------
//    logic [4:0] man_bits; // Fractional bits (excluding hidden bit)
//    assign man_bits = total_bits - exp_bits - 1;

//    logic sign_a, sign_b;
//    logic [MAX_EXP_BITS-1:0] exp_a, exp_b;
//    logic [MAX_MAN_BITS-1:0] man_a, man_b;
    
//    always_comb begin
//        // Shift logically to avoid 'X' states
//        sign_a = (A >> (total_bits - 1)) & 1'b1;
//        sign_b = (B >> (total_bits - 1)) & 1'b1;
        
//        exp_a  = (A >> man_bits) & ((1 << exp_bits) - 1);
//        exp_b  = (B >> man_bits) & ((1 << exp_bits) - 1);
        
//        man_a  = A & ((1 << man_bits) - 1);
//        man_b  = B & ((1 << man_bits) - 1);
//    end

//    // ------------------------------------------------------------------------
//    // 2. Instantiate the Radix-4 Mantissa Core
//    // ------------------------------------------------------------------------
//    logic [3:0] mult_precision;
//    assign mult_precision = man_bits + 1; // Core expects width INCLUDING hidden bit

//    logic [2*MAX_MAN_BITS-1:0] mult_result;
//    logic                      mult_result_sign;
//    logic                      mult_done;
//    logic                      mult_busy;

//    precision_gated_radix4_mult #(
//        .MAX_MAN_BITS(MAX_MAN_BITS)
//    ) mantissa_core (
//        .clk         (clk),
//        .rst_n       (rst_n),
//        .start       (start),
//        .precision   (mult_precision),
//        .A           (man_a),
//        .B           (man_b),
//        .sign_a      (sign_a),
//        .sign_b      (sign_b),
//        .is_float    (1'b1),           // FORCE float mode (injects hidden bits)
//        .result      (mult_result),
//        .result_sign (mult_result_sign),
//        .done        (mult_done),
//        .busy        (mult_busy)
//    );

//    // ------------------------------------------------------------------------
//    // 3. Normalization Detection
//    // ------------------------------------------------------------------------
//logic overflow;
//    logic [MAX_MAN_BITS-1:0] normalized_man;

//    always_comb begin
//        // FIXED: The maximum possible index for the product's hidden bit 
//        // is (man_bits * 2 + 1) when the multiplication >= 2.0
        
//        overflow = mult_result[man_bits * 2 + 1];  // <--- ADD THE "+ 1" HERE
        
//        // Shift down to strip the hidden bit and align the fraction
//        if (overflow) begin
//            normalized_man = (mult_result >> (man_bits + 1)) & ((1 << man_bits) - 1);
//        end else begin
//            normalized_man = (mult_result >> man_bits) & ((1 << man_bits) - 1);
//        end
//    end
//    // ------------------------------------------------------------------------
//    // 4. Instantiate the Exponent Unit
//    // ------------------------------------------------------------------------
//    logic [MAX_EXP_BITS-1:0] final_exp;
//    logic                    is_infinity;
//    logic                    is_zero;

//    dynamic_exp_unit #(
//        .MAX_EXP_BITS(MAX_EXP_BITS)
//    ) exp_core (
//        .exp_bits    (exp_bits),
//        .exp_a       (exp_a),
//        .exp_b       (exp_b),
//        .norm_shift  (overflow),
//        .final_exp   (final_exp),
//        .is_infinity (is_infinity),
//        .is_zero     (is_zero)
//    );

//    // ------------------------------------------------------------------------
//    // 5. Output Packing & FSM
//    // ------------------------------------------------------------------------
//    logic is_input_zero;
//    assign is_input_zero = (A == 0 || B == 0);

//    always_ff @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            valid  <= 1'b0;
//            result <= '0;
//            ready  <= 1'b1;
//        end else begin
//            valid <= 1'b0; // Default clear
            
//            if (start) begin
//                ready <= 1'b0;
//            end 
//            else if (mult_done) begin
//                valid <= 1'b1;
//                ready <= 1'b1;
                
//                // Pack the result dynamically
//                result <= '0; 
                
//                if (is_input_zero || is_zero) begin
//                    result <= '0; // Hard flush to zero
//                end else if (is_infinity) begin
//                    // Pack Infinity (All 1s in Exponent, 0s in Mantissa)
//                    result <= (mult_result_sign << (total_bits - 1)) | 
//                              (((1 << exp_bits) - 1) << man_bits);
//                end else begin
//                    // Pack Normal Result
//                    result <= (mult_result_sign << (total_bits - 1)) | 
//                              (final_exp << man_bits) | 
//                              normalized_man;
//                end
//            end
//        end
//    end

//endmodule