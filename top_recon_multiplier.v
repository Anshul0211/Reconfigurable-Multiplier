`timescale 1ns / 1ps

module top_recon_multiplier(
        input clk, rst,
		input [15:0] in_a, in_b, //size decided based on max of (normal op len, parallel op len) = (11, 8+8)
		input [2:0] precision_mode, //5 modes
//		input start_op,
		output reg [1:0]exception,overflow,underflow,
		output reg [15:0] result
//		output reg op_complete
		);
//input is assumed to be in partitions of (8, 8) for parallel case and are filled from lsb side for each partition


//FP6 (1, 4, 1) -> 0 -> parallel
//FP7 (1, 4, 2) -> 1 -> parallel
//FP8 (1, 4, 3) -> 2 -> parallel (decided based on the fact that more layers utilised this config in the given layerwise config)
//FP9 (1, 4, 4) -> 3
//FP11 (1, 6, 4) -> 4
//max mantissa multiplication is 5x5 bit for normal case and 2(4x4) for parallel case so we choose we choose N=8 (4, 4 parallel)
//max exponent size is 6 for normal and (4+4) for parallel
//max mantissa size is 4 for normal and (3+3) for parallel

//register definitions for isolating the inputs for reg to reg design
reg [15:0] a, b;
reg [2:0] precision_mode_r; 
reg [15:0] result_comb; //combinational circuit result to be latched to result register at posedge
reg [1:0] exception_comb,overflow_comb,underflow_comb;

always@(posedge clk) begin
    if(rst) begin
        a<=0; b<=0;
        precision_mode_r<=0;
        result<=0;
        exception<=0;
        overflow<=0;
        underflow<=0;
    end
    else begin
        a<=in_a; b<=in_b;
        precision_mode_r<=precision_mode;
        result<=result_comb;
        exception<=exception_comb;
        overflow<=overflow_comb;
        underflow<=underflow_comb;
    end
end

//reg a_low_sign, a_high_sign, b_low_sign, b_high_sign; //separate low and high sign bits for the parallel computation case
reg [1:0] a_sign, b_sign; //common sign for all cases, for parallel case partition in half, for normal case stored in sign[0]
reg [7:0] a_exp, b_exp; //common exponent for all cases, for parallel case partition in half
reg [7:0] a_mant, b_mant; //common mantissa for all cases, for parallel case partition in half

wire mode_parallel_bar = (precision_mode_r<3) ? 1'b0 : 1'b1; //0->parallel, 1->normal 

reg [1:0]result_sign;
reg [9:0]sum_exp;

wire [9:0]product_full;
wire [7:0]product_lo, product_hi;

reg [1:0]normalised,product_round;
reg [15:0]product_normalised;
//reg product_low_round,product_high_round,normalised_low,normalised_high;

reg [1:0]zero;

reg [5:0] product_mantissa; //normal case mantissa = 4, parallel case mantissa = 2x(3)
reg [9:0] final_exp; //normal case exponent result = 7, parallel case exponent = 2x(5)

always@(*) begin

    // ---------- SAFE DEFAULTS ----------
    a_sign = 0; b_sign = 0;
    a_exp  = 0; b_exp  = 0;
    a_mant = 0; b_mant = 0;

    result_sign = 0;
    sum_exp = 0;

    product_normalised = 0;
    product_mantissa = 0;
    final_exp = 0;

    normalised = 0;
    product_round = 0;

    zero = 0;

    exception_comb = 0;
    overflow_comb  = 0;
    underflow_comb = 0;

    result_comb = 0;

    //sign, exp, mant separation:

    case(precision_mode_r)
        0:begin //FP6 (1, 4, 1) parallel
            a_sign[0] = a[5]; a_exp[3:0] = a[4:1]; a_mant[3:0] = (|a[4:1])?{1'b1, a[0]}:{1'b0, a[0]};
            b_sign[0] = b[5]; b_exp[3:0] = b[4:1]; b_mant[3:0] = (|b[4:1])?{1'b1, b[0]}:{1'b0, b[0]};
            a_sign[1] = a[13]; a_exp[7:4] = a[12:9]; a_mant[7:4] = (|a[12:9])?{1'b1, a[8]}:{1'b0, a[8]};
            b_sign[1] = b[13]; b_exp[7:4] = b[12:9]; b_mant[7:4] = (|b[12:9])?{1'b1, b[8]}:{1'b0, b[8]};
        end
        1:begin //FP7 (1, 4, 2) parallel
            a_sign[0] = a[6]; a_exp[3:0] = a[5:2]; a_mant[3:0] = (|a[5:2])?{1'b1, a[1:0]}:{1'b0, a[1:0]};
            b_sign[0] = b[6]; b_exp[3:0] = b[5:2]; b_mant[3:0] = (|b[5:2])?{1'b1, b[1:0]}:{1'b0, b[1:0]};
            a_sign[1] = a[14]; a_exp[7:4] = a[13:10]; a_mant[7:4] = (|a[13:10])?{1'b1, a[9:8]}:{1'b0, a[9:8]};
            b_sign[1] = b[14]; b_exp[7:4] = b[13:10]; b_mant[7:4] = (|b[13:10])?{1'b1, b[9:8]}:{1'b0, b[9:8]};
        end
        2:begin //FP8 (1, 4, 3) parallel
            a_sign[0] = a[7]; a_exp[3:0] = a[6:3]; a_mant[3:0] = (|a[6:3])?{1'b1, a[2:0]}:{1'b0, a[2:0]};
            b_sign[0] = b[7]; b_exp[3:0] = b[6:3]; b_mant[3:0] = (|b[6:3])?{1'b1, b[2:0]}:{1'b0, b[2:0]};
            a_sign[1] = a[15]; a_exp[7:4] = a[14:11]; a_mant[7:4] = (|a[14:11])?{1'b1, a[10:8]}:{1'b0, a[10:8]};
            b_sign[1] = b[15]; b_exp[7:4] = b[14:11]; b_mant[7:4] = (|b[14:11])?{1'b1, b[10:8]}:{1'b0, b[10:8]};
        end
        3:begin //FP9 (1, 4, 4)
            a_sign[0] = a[8]; a_exp = a[7:4]; a_mant = (|a[7:4])?{1'b1, a[3:0]}:{1'b0, a[3:0]};
            b_sign[0] = b[8]; b_exp = b[7:4]; b_mant = (|b[7:4])?{1'b1, b[3:0]}:{1'b0, b[3:0]};
        end
        4:begin //FP11 (1, 6, 4)
            a_sign[0] = a[10]; a_exp = a[9:4]; a_mant = (|a[9:4])?{1'b1, a[3:0]}:{1'b0, a[3:0]};
            b_sign[0] = b[10]; b_exp = b[9:4]; b_mant = (|b[9:4])?{1'b1, b[3:0]}:{1'b0, b[3:0]};
        end
        default: begin //keeping FP11 as default case
            a_sign[0] = a[10]; a_exp = a[9:4]; a_mant = (|a[9:4])?{1'b1, a[3:0]}:{1'b0, a[3:0]};
            b_sign[0] = b[10]; b_exp = b[9:4]; b_mant = (|b[9:4])?{1'b1, b[3:0]}:{1'b0, b[3:0]};  
        end
    endcase
    //result sign computation and exponent addition
    result_sign = a_sign^b_sign;
    if(mode_parallel_bar == 0) begin
        sum_exp[4:0] = a_exp[3:0] + b_exp[3:0];
        sum_exp[9:5] = a_exp[7:4] + b_exp[7:4];
    end
    else begin
        sum_exp = a_exp + b_exp;
    end
    
    //normalisation and rounding
    normalised=0; product_round=0;
    case(precision_mode_r)
    0: begin
        product_round[0] = product_lo[0];
        product_round[1] = product_hi[0];
        product_normalised[7:0] = product_lo[3]?product_lo:product_lo<<1;
        product_normalised[15:8] = product_hi[3]?product_hi:product_hi<<1;
        normalised[0] = product_lo[3];
        normalised[1] = product_hi[3];
    end
    1: begin
        product_round[0] = product_lo[1];
        product_round[1] = product_hi[1];
        product_normalised[7:0] = product_lo[5]?product_lo:product_lo<<1;
        product_normalised[15:8] = product_hi[5]?product_hi:product_hi<<1;
        normalised[0] = product_lo[5];
        normalised[1] = product_hi[5];
    end
    2: begin
        product_round[0] = product_lo[2];
        product_round[1] = product_hi[2];
        product_normalised[7:0] = product_lo[7]?product_lo:product_lo<<1;
        product_normalised[15:8] = product_hi[7]?product_hi:product_hi<<1;
        normalised[0] = product_lo[7];
        normalised[1] = product_hi[7];
    end
    3: begin
        product_round[0] = product_full[3];
        product_normalised = product_full[9]?product_full:product_full<<1;
        normalised[0] = product_full[9];
    end
    4: begin
        product_round[0] = product_full[3];
        product_normalised = product_full[9]?product_full:product_full<<1;
        normalised[0] = product_full[9];
    end
    default: begin
        product_round[0] = product_full[3];
        product_normalised = product_full[9]?product_full:product_full<<1;
        normalised[0] = product_full[9];    
    end
    endcase
    
    //product mantissa computation and exponent bias handling
    case(precision_mode_r)
    0: begin
        product_mantissa[2:0] = product_normalised[2] + (product_normalised[1] & product_round[0]);      
        product_mantissa[5:3] = product_normalised[10] + (product_normalised[9] & product_round[1]); 
        final_exp[4:0] = sum_exp[4:0] - 3'd7 + normalised[0];   
        final_exp[9:5] = sum_exp[9:5] - 3'd7 + normalised[1]; 
    end
    1: begin
        product_mantissa[2:0] = product_normalised[4:3] + (product_normalised[2] & product_round[0]);      
        product_mantissa[5:3] = product_normalised[12:11] + (product_normalised[10] & product_round[1]);
        final_exp[4:0] = sum_exp[4:0] - 3'd7 + normalised[0];   
        final_exp[9:5] = sum_exp[9:5] - 3'd7 + normalised[1]; 
       
    end
    2: begin
        product_mantissa[2:0] = product_normalised[6:4] + (product_normalised[3] & product_round[0]);      
        product_mantissa[5:3] = product_normalised[14:12] + (product_normalised[11] & product_round[1]);
        final_exp[4:0] = sum_exp[4:0] - 3'd7 + normalised[0];   
        final_exp[9:5] = sum_exp[9:5] - 3'd7 + normalised[1];  
    end
    3: begin
        product_mantissa = product_normalised[8:5] + (product_normalised[4] & product_round[0]);
        final_exp = sum_exp - 3'd7 + normalised[0];      
    end
    4: begin
        product_mantissa = product_normalised[8:5] + (product_normalised[4] & product_round[0]);  
        final_exp = sum_exp - 5'd31 + normalised[0];      
    end
    default: begin
        product_mantissa = product_normalised[8:5] + (product_normalised[4] & product_round[0]);  
        final_exp = sum_exp - 5'd31 + normalised[0];  
    end
    endcase
    
    //exception, overflow and underflow:
    //exception is set when all the exponent bits of any 1 input are all 1s and it means either inf or NaN
    //zero is set when any input has all mant and exp as all 0s
    //overflow set when exp value has a carry with msb bit non zero
    //underflow set when final_exp goes negative 
    case(precision_mode_r)
    0: begin
        exception_comb[0] = (&a_exp[3:0]) | (&b_exp[3:0]); 
        exception_comb[1] = (&a_exp[7:4]) | (&b_exp[7:4]);
        zero[0] = (a_exp[3:0] == 0 && a_mant[3:0] == 0) || (b_exp[3:0] == 0 && b_mant[3:0] == 0);
        zero[1] = (a_exp[7:4] == 0 && a_mant[7:4] == 0) || (b_exp[7:4] == 0 && b_mant[7:4] == 0);
        overflow_comb[0] = ((final_exp[4] & !final_exp[3]) & !zero[0]);
        overflow_comb[1] = ((final_exp[9] & !final_exp[8]) & !zero[1]);
        underflow_comb[0] = ((final_exp[4] & final_exp[3]) & !zero[0]);
        underflow_comb[1] = ((final_exp[9] & final_exp[8]) & !zero[1]);
    end
    1: begin
        exception_comb[0] = (&a_exp[3:0]) | (&b_exp[3:0]); 
        exception_comb[1] = (&a_exp[7:4]) | (&b_exp[7:4]); 
        zero[0] = (a_exp[3:0] == 0 && a_mant[3:0] == 0) || (b_exp[3:0] == 0 && b_mant[3:0] == 0);
        zero[1] = (a_exp[7:4] == 0 && a_mant[7:4] == 0) || (b_exp[7:4] == 0 && b_mant[7:4] == 0);
        overflow_comb[0] = ((final_exp[4] & !final_exp[3]) & !zero[0]);
        overflow_comb[1] = ((final_exp[9] & !final_exp[8]) & !zero[1]);
        underflow_comb[0] = ((final_exp[4] & final_exp[3]) & !zero[0]);
        underflow_comb[1] = ((final_exp[9] & final_exp[8]) & !zero[1]);
    end
    2: begin
        exception_comb[0] = (&a_exp[3:0]) | (&b_exp[3:0]); 
        exception_comb[1] = (&a_exp[7:4]) | (&b_exp[7:4]); 
        zero[0] = (a_exp[3:0] == 0 && a_mant[3:0] == 0) || (b_exp[3:0] == 0 && b_mant[3:0] == 0);
        zero[1] = (a_exp[7:4] == 0 && a_mant[7:4] == 0) || (b_exp[7:4] == 0 && b_mant[7:4] == 0);
        overflow_comb[0] = ((final_exp[4] & !final_exp[3]) & !zero[0]);
        overflow_comb[1] = ((final_exp[9] & !final_exp[8]) & !zero[1]);
        underflow_comb[0] = ((final_exp[4] & final_exp[3]) & !zero[0]);
        underflow_comb[1] = ((final_exp[9] & final_exp[8]) & !zero[1]);
    end
    3: begin
        exception_comb[0] = (&a_exp[3:0]) | (&b_exp[3:0]);
        exception_comb[1] = 0;
        zero[0] = (a_exp == 0 && a_mant == 0) || (b_exp == 0 && b_mant == 0);
        zero[1] = 0;
        overflow_comb[0] = ((final_exp[4] & !final_exp[3]) & !zero[0]);
        overflow_comb[1] = 0;
        underflow_comb[0] = ((final_exp[4] & final_exp[3]) & !zero[0]);
        underflow_comb[1] = 0;
    end
    4: begin
        exception_comb[0] = (&a_exp[5:0]) | (&b_exp[5:0]);
        exception_comb[1] = 0;
        zero[0] = (a_exp == 0 && a_mant == 0) || (b_exp == 0 && b_mant == 0);
        zero[1] = 0;
        overflow_comb[0] = ((final_exp[6] & !final_exp[5]) & !zero[0]);
        overflow_comb[1] = 0;
        underflow_comb[0] = ((final_exp[6] & final_exp[5]) & !zero[0]);
        underflow_comb[1] = 0;
    end
    default: begin
        exception_comb[0] = (&a_exp[5:0]) | (&b_exp[5:0]);
        exception_comb[1] = 0;
        zero[0] = (a_exp == 0 && a_mant == 0) || (b_exp == 0 && b_mant == 0);
        zero[1] = 0;
        overflow_comb[0] = ((final_exp[6] & !final_exp[5]) & !zero[0]);
        overflow_comb[1] = 0;
        underflow_comb[0] = ((final_exp[6] & final_exp[5]) & !zero[0]);
        underflow_comb[1] = 0;
    end
    
    endcase
    //result compilation
    case(precision_mode_r)
    0: begin
        result_comb[7:0] = exception_comb[0] ? 8'd0 : zero[0] ? {2'b0, result_sign[0], 5'd0} : 
            overflow_comb[0] ? {2'd0, result_sign[0], 4'b1111, 1'd0} : underflow_comb[0] ? {2'd0, result_sign[0], 5'd0} : 
            {2'd0, result_sign[0], final_exp[3:0], product_mantissa[0]};
        result_comb[15:8] = exception_comb[1] ? 8'd0 : zero[1] ? {2'd0, result_sign[1], 5'd0} : 
            overflow_comb[1] ? {2'd0, result_sign[1], 4'b1111, 1'd0} : underflow_comb[1] ? {2'd0, result_sign[1], 5'd0} : 
            {2'd0, result_sign[1], final_exp[8:5], product_mantissa[3]};
//        result_comb = {2'b0, result_sign[1], final_exp[8:5], product_mantissa[3], 2'b0, result_sign[0], final_exp[3:0], product_mantissa[0]};
    end
    1: begin
        result_comb[7:0] = exception_comb[0] ? 8'd0 : zero[0] ? {1'b0, result_sign[0], 6'd0} : 
            overflow_comb[0] ? {1'b0, result_sign[0], 4'b1111, 2'd0} : underflow_comb[0] ? {1'b0, result_sign[0], 6'd0} : 
            {1'b0, result_sign[0], final_exp[3:0], product_mantissa[1:0]};
        result_comb[15:8] = exception_comb[1] ? 8'd0 : zero[1] ? {1'b0, result_sign[1], 6'd0} : 
            overflow_comb[1] ? {1'b0, result_sign[1], 4'b1111, 2'd0} : underflow_comb[1] ? {1'b0, result_sign[1], 6'd0} : 
            {1'b0, result_sign[1], final_exp[8:5], product_mantissa[4:3]};
//        result_comb = {1'b0, result_sign[1], final_exp[8:5], product_mantissa[4:3], 1'b0, result_sign[0], final_exp[3:0], product_mantissa[1:0]};
    end
    2: begin
        result_comb[7:0] = exception_comb[0] ? 8'd0 : zero[0] ? {result_sign[0], 7'd0} : 
            overflow_comb[0] ? {result_sign[0], 4'b1111, 3'd0} : underflow_comb[0] ? {result_sign[0], 7'd0} : 
            {result_sign[0], final_exp[3:0], product_mantissa[2:0]};
        result_comb[15:8] = exception_comb[1] ? 8'd0 : zero[1] ? {result_sign[1], 7'd0} : 
            overflow_comb[1] ? {result_sign[1], 4'b1111, 3'd0} : underflow_comb[1] ? {result_sign[1], 7'd0} : 
            {result_sign[1], final_exp[8:5], product_mantissa[5:3]};
//        result_comb = {result_sign[1], final_exp[8:5], product_mantissa[5:3], result_sign[0], final_exp[3:0], product_mantissa[2:0]};
    end
    3: begin
        result_comb = exception_comb[0] ? 16'd0 : zero[0] ? {7'd0, result_sign[0], 8'd0} : 
            overflow_comb[0] ? {7'd0, result_sign[0], 4'b1111, 4'd0} : underflow_comb[0] ? {7'd0, result_sign[0], 8'd0} : 
            {7'd0, result_sign[0], final_exp[3:0], product_mantissa[3:0]};
//        result_comb = {7'b0, result_sign[0], final_exp[3:0], product_mantissa[3:0]};
    end
    4: begin
        result_comb = exception_comb[0] ? 16'd0 : zero[0] ? {5'd0, result_sign[0], 10'd0} : 
            overflow_comb[0] ? {5'd0, result_sign[0], 4'b1111, 4'd0} : underflow_comb[0] ? {5'd0, result_sign[0], 10'd0} : 
            {5'd0, result_sign[0], final_exp[5:0], product_mantissa[3:0]};
//        result_comb = {5'b0, result_sign[0], final_exp[5:0], product_mantissa[3:0]};
    end
    default: begin
        result_comb = exception_comb[0] ? 16'd0 : zero[0] ? {5'd0, result_sign[0], 10'd0} : 
            overflow_comb[0] ? {5'd0, result_sign[0], 4'b1111, 4'd0} : underflow_comb[0] ? {5'd0, result_sign[0], 10'd0} : 
            {5'd0, result_sign[0], final_exp[5:0], product_mantissa[3:0]};
//        result_comb = {5'b0, result_sign[0], final_exp[5:0], product_mantissa[3:0]};
    end
    endcase
end

multiplier_Nbit #(8) uut(.rst(rst), .mode(mode_parallel_bar), .A(a_mant), .B(b_mant), .product_full(product_full), .product_lo(product_lo), .product_hi(product_hi));
endmodule

module multiplier_Nbit #(
    parameter N = 24
)(
    input rst,
    //input start,
    input mode, // 1 = full NxN, 0 = two (N/2)x(N/2) parallel
    input [N-1:0]A,
    input [N-1:0]B,
    //output valid,
    output reg [2*N-1:0]product_full,
    output reg [N-1:0]product_lo,
    output reg [N-1:0]product_hi
);

localparam H = N/2;

// Operand splitting
wire [H-1:0] A0 = A[H-1:0];
wire [H-1:0] A1 = A[N-1:H];
wire [H-1:0] B0 = B[H-1:0];
wire [H-1:0] B1 = B[N-1:H];

// Operand isolation (cross-term gating)
wire [H-1:0] A0_cross = mode ? A0 : {H{1'b0}};
wire [H-1:0] A1_cross = mode ? A1 : {H{1'b0}};
wire [H-1:0] B0_cross = mode ? B0 : {H{1'b0}};
wire [H-1:0] B1_cross = mode ? B1 : {H{1'b0}};

// Partial products
wire [N-1:0] pp00 = A0 * B0;
wire [N-1:0] pp11 = A1 * B1;
wire [N-1:0] pp01 = A0_cross * B1_cross;
wire [N-1:0] pp10 = A1_cross * B0_cross;

// Partial product shifting for further addition stage
wire [2*N-1:0] p00_ext = {{(2*N-N){1'b0}}, pp00};
wire [2*N-1:0] p01_ext = {{(N-H){1'b0}}, pp01, {H{1'b0}}};
wire [2*N-1:0] p10_ext = {{(N-H){1'b0}}, pp10, {H{1'b0}}};
wire [2*N-1:0] p11_ext = {pp11, {(2*N-N){1'b0}}};

// Final qaddition and result compilation
always @(*) begin
    if (rst) begin
//        valid        = 1'b0;
        product_full = {2*N{1'b0}};
        product_lo   = {N{1'b0}};
        product_hi   = {N{1'b0}};
    end
    else begin
        //valid      = start;
        product_lo = pp00;
        product_hi = pp11;
        
        if (mode)
            product_full = p00_ext + p01_ext + p10_ext + p11_ext;
        else
            product_full = {2*N{1'b0}};
    end
end
endmodule
