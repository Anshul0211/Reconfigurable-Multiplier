

`timescale 1ns/1ps

module precision_gated_radix4_mult #(
    parameter int MAX_MAN_BITS = 14        
) (
    input  logic                        clk,
    input  logic                        rst_n,    

    //  Control
    input  logic                        start,     
    input  logic [3:0]                  precision, 

    // Operands (magnitude + separate sign) 
    input  logic [MAX_MAN_BITS-1:0]     A,         // multiplicand magnitude
    input  logic [MAX_MAN_BITS-1:0]     B,         // multiplier   magnitude
    input  logic                        sign_a,    // sign of A
    input  logic                        sign_b,    // sign of B
    input  logic                        is_float,  // 1 ? inject IEEE-754 hidden '1'

    // Outputs \
    output logic [2*MAX_MAN_BITS-1:0]   result,    
    output logic                        result_sign,
    output logic                        done,      
    output logic                        busy       
);

   
    
    
    // ACC_W = extra 4 bits of headroom above 2P for Booth sign-extension
    localparam int ACC_W = 2 * MAX_MAN_BITS + 4;

    
    // FSM state encoding
    
    typedef enum logic [1:0] {
        S_IDLE     = 2'b00,
        S_LOAD     = 2'b01,   // one setup cycle to register operands
        S_MULTIPLY = 2'b10,   // ceil(precision/2) Booth cycles
        S_DONE     = 2'b11    // latch result, assert done
    } state_t;

    state_t state;

  
    // Datapath registers
   
    logic signed [ACC_W-1:0]      acc;     // partial-product accumulator
    logic        [ACC_W-1:0]      mcd_r;   // multiplicand - shifts LEFT  ×4 each cycle
    logic        [MAX_MAN_BITS:0] mpr_r;   // multiplier   - shifts RIGHT ÷4 each cycle
    //                                        extra MSB keeps the shift clean
    logic                         prev_b;  // Booth look-back bit b_{2i-1}
    logic        [3:0]            cyc;     // Booth cycle counter
    logic        [3:0]            max_cyc; // ceil(precision/2) - loaded on start
    logic                         sign_r;  // registered result sign

    
    // Precision mask & hidden-bit injection  
    //
    //   prec_mask : e.g. precision=7  ? 14'b00_0000_0111_1111
    //   a_proc    : hidden-bit OR at bit (precision-1), then AND with mask
    //   b_proc    : same for B
    //
    //   The dynamic shift ((MAX_MAN_BITS'(1) << (precision-1))) avoids the variable array-index X-state issue in simulation.

    logic [MAX_MAN_BITS-1:0] prec_mask;
    logic [MAX_MAN_BITS-1:0] a_proc, b_proc;

    always_comb begin
        prec_mask = (MAX_MAN_BITS'(1) << precision) - 1'b1;
        a_proc    = (A | (is_float ? MAX_MAN_BITS'(1) << (precision - 1) : '0)) & prec_mask;
        b_proc    = (B | (is_float ? MAX_MAN_BITS'(1) << (precision - 1) : '0)) & prec_mask;
    end

    
    // Radix-4 Modified Booth partial-product  (combinational)
    
    //   Encode triplet sel = { b_{2i+1}, b_{2i}, b_{2i-1} }
    //   sel  ? decimal ?  PP
    //   000  ?    0    ?   0
    //   001  ?   +1    ?  +M
    //   010  ?   +1    ?  +M
    //   011  ?   +2    ? +2M
    //   100  ?   -2    ? -2M
    //   101  ?   -1    ?  -M
    //   110  ?   -1    ?  -M
    //   111  ?    0    ?   0
    //
    //   mcd_s is zero-extended then sign-cast; MSB is always 0 during normal
    //   operation (magnitude ? 14 bits in a 32-bit field).
    //   Explicit $signed cast ensures Verilog respects two's complement when
    //   the encoder generates a negative partial product (-M, -2M).

    logic signed [ACC_W-1:0] mcd_s;    // sign-safe view of multiplicand
    logic signed [ACC_W-1:0] booth_pp; // partial product this cycle

    assign mcd_s = signed'(ACC_W'(mcd_r)); // safe: MSB always 0

    always_comb begin
        unique case ({mpr_r[1], mpr_r[0], prev_b})
            3'b000 : booth_pp =  '0;
            3'b001 : booth_pp =  mcd_s;
            3'b010 : booth_pp =  mcd_s;
            3'b011 : booth_pp =  mcd_s <<< 1;
            3'b100 : booth_pp = -(mcd_s <<< 1);
            3'b101 : booth_pp = -mcd_s;
            3'b110 : booth_pp = -mcd_s;
            3'b111 : booth_pp =  '0;
        endcase
    end

    
    // clock enable
   
  
    logic clk_en;
    assign clk_en = (state == S_MULTIPLY);

   
    // Control FSM - NOT gated by clk_en

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            busy        <= 1'b0;
            done        <= 1'b0;
            sign_r      <= 1'b0;
            max_cyc     <= '0;
            cyc         <= '0;
            result      <= '0;
            result_sign <= 1'b0;
        end else begin
            done <= 1'b0;  // self-clearing pulse; held 1 for exactly 1 cycle

            case (state)
                
                // IDLE: wait for start, pre-compute control metadata

                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy    <= 1'b1;
                        sign_r  <= sign_a ^ sign_b;
                        // ceil(precision / 2) using integer arithmetic:
                        //   (precision + 1) >> 1
                        max_cyc <= (4'(precision) + 4'd2) >> 1;
                        cyc     <= '0;
                        state   <= S_LOAD;
                    end
                end

                
                // LOAD: one dead cycle - datapath already armed by the
                //       separate always_ff block below
                
                S_LOAD: begin
                    state <= S_MULTIPLY;
                end

                
                // MULTIPLY: count Booth cycles; each real work happens in the ICG-gated datapath block

                S_MULTIPLY: begin
                    cyc <= cyc + 1'b1;
                    if (cyc == max_cyc - 1'b1)
                        state <= S_DONE;
                end

               
                // DONE: latch result, signal completion
                
                S_DONE: begin
                    result      <= acc[2*MAX_MAN_BITS-1:0];
                    result_sign <= sign_r;
                    done        <= 1'b1;
                    busy        <= 1'b0;
                    state       <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    
    // Accumulator - ICG-gated block
    
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc <= '0;
        else if (state == S_LOAD)
            acc <= '0;            // clear accumulator before first Booth step
        else if (clk_en)
            acc <= acc + booth_pp;  // Booth accumulate
    end

    
    // Multiplier shift register - ICG-gated
    // mpr_r shifts RIGHT by 2 each cycle, exposing the next Booth triplet.
    // prev_b is the look-back bit retained across cycles.
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mpr_r  <= '0;
            prev_b <= 1'b0;
        end else if (state == S_LOAD) begin
            mpr_r  <= {1'b0, b_proc};  // zero-extend to MAX_MAN_BITS+1 bits
            prev_b <= 1'b0;            // b_{-1} = 0 per Booth convention
        end else if (clk_en) begin
            prev_b <= mpr_r[1];        // save bit before it shifts away
            mpr_r  <= mpr_r >> 2;
        end
    end

    
    // Multiplicand shift register - ICG-gated
    // mcd_r shifts LEFT by 2 each cycle, implementing the positional weight
    // 4^i for the i-th Booth partial product without a barrel shifter.
    // Register is sized to ACC_W (32 bits) to absorb 7 left-shifts of 14 bits
    // (14 + 7×2 = 28 bits) without overflow.
   
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mcd_r <= '0;
        else if (state == S_LOAD)
            mcd_r <= ACC_W'(a_proc);  // load precision-masked operand
        else if (clk_en)
            mcd_r <= mcd_r << 2;      // weight ×4 per Booth cycle
    end

endmodule