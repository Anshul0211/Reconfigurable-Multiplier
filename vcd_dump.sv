//`timescale 1ns/1ps

//module tb_fp_9_4;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    always #5 clk = ~clk;

//    task automatic drive_one(input logic [15:0] a_i, input logic [15:0] b_i);
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    function automatic logic [15:0] rand_9bit_fp();
//    begin
//        rand_9bit_fp = $urandom & 16'h01FF;
//    end
//    endfunction

//    initial begin
//        clk        = 0;
//        rst_n      = 0;
//        start      = 0;
//        total_bits = 9;
//        exp_bits   = 4;
//        A          = '0;
//        B          = '0;

//        repeat (5) @(posedge clk);
//        rst_n = 1'b1;

//        repeat (10000) begin
//            drive_one(rand_9bit_fp(), rand_9bit_fp());
//        end

//        #50;
//        $finish;
//    end

//endmodule

//`timescale 1ns/1ps

//module tb_fp_8_4;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    // DUT
//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    // Clock
//    always #5 clk = ~clk;

//    //------------------------------------
//    // Drive function
//    //------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask


//    //------------------------------------
//    // Random generator for 8-bit
//    //------------------------------------

//    function automatic logic [15:0] rand_8bit();
//    begin
//        rand_8bit = $urandom & 16'h00FF;
//    end
//    endfunction


//    //------------------------------------
//    // Main
//    //------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 8;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(10000) begin
//            drive_one(rand_8bit(), rand_8bit());
//        end

//        #100;

//        $finish;

//    end

//endmodule



//`timescale 1ns/1ps

//module tb_fp_6_4;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    // DUT
//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //-----------------------------------
//    // Clock
//    //-----------------------------------
//    always #5 clk = ~clk;

//    //-----------------------------------
//    // Drive function
//    //-----------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask


//    //-----------------------------------
//    // Random 6-bit generator
//    //-----------------------------------

//    function automatic logic [15:0] rand_6bit();
//    begin
//        rand_6bit = $urandom & 16'h003F; // 6 bits
//    end
//    endfunction


//    //-----------------------------------
//    // Main
//    //-----------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 6;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);
//        rst_n = 1;

//        repeat(1000) begin
//            drive_one(rand_6bit(), rand_6bit());
//        end

//        #100;
//        $finish;

//    end

//endmodule

//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    always #5 clk = ~clk;

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    function automatic logic [15:0] rand_16();
//    begin
//        rand_16 = $urandom & 16'hFFFF;
//    end
//    endfunction

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 9;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        repeat(1000) begin
//            drive_one(rand_16(), rand_16());
//        end

//        #100;
//        $finish;

//    end

//endmodule



//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 7 bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_7();
//    begin
//        rand_7 = $urandom & 16'h007F;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 7;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        repeat(1000) begin
//            drive_one(rand_7(), rand_7());
//        end

//        #100;

//        $finish;

//    end

//endmodule



//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 15-bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_15();
//    begin
//        rand_15 = $urandom & 16'h7FFF;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 15;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        //----------------------------------
//        // Run 1000 cases
//        //----------------------------------

//        repeat(1000) begin
//            drive_one(rand_15(), rand_15());
//        end

//        #100;

//        $finish;

//    end

//endmodule





//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 5-bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_5();
//    begin
//        rand_5 = $urandom & 16'h001F;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 5;
//        exp_bits   = 3;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        //----------------------------------
//        // Run 1000 cases
//        //----------------------------------

//        repeat(1000) begin
//            drive_one(rand_5(), rand_5());
//        end

//        #100;

//        $finish;

//    end

//endmodule

//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 10-bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_10();
//    begin
//        rand_10 = $urandom & 16'h03FF;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 10;
//        exp_bits   = 6;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        //----------------------------------
//        // Run 1000 cases
//        //----------------------------------

//        repeat(1000) begin
//            drive_one(rand_10(), rand_10());
//        end

//        #100;

//        $finish;

//    end

//endmodule



//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 9-bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_9();
//    begin
//        rand_9 = $urandom & 16'h01FF;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 9;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        //----------------------------------
//        // Run 1000 cases
//        //----------------------------------

//        repeat(1000) begin
//            drive_one(rand_9(), rand_9());
//        end

//        #100;

//        $finish;

//    end

//endmodule



//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 6-bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_6();
//    begin
//        rand_6 = $urandom & 16'h003F;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 6;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        //----------------------------------
//        // Run 1000 cases
//        //----------------------------------

//        repeat(1000) begin
//            drive_one(rand_6(), rand_6());
//        end

//        #100;

//        $finish;

//    end

//endmodule


//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 16-bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_16();
//    begin
//        rand_16 = $urandom & 16'hFFFF;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 16;
//        exp_bits   = 5;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        //----------------------------------
//        // Run 1000 cases
//        //----------------------------------

//        repeat(1000) begin
//            drive_one(rand_16(), rand_16());
//        end

//        #100;

//        $finish;

//    end

//endmodule


//`timescale 1ns/1ps

//module tb_fp;

//    logic clk;
//    logic rst_n;
//    logic start;
//    logic ready;
//    logic valid;

//    logic [4:0] total_bits;
//    logic [3:0] exp_bits;

//    logic [15:0] A;
//    logic [15:0] B;
//    logic [15:0] result;

//    //--------------------------------------
//    // DUT
//    //--------------------------------------

//    reconfig_fp_top dut (
//        .clk        (clk),
//        .rst_n      (rst_n),
//        .start      (start),
//        .ready      (ready),
//        .valid      (valid),
//        .total_bits (total_bits),
//        .exp_bits   (exp_bits),
//        .A          (A),
//        .B          (B),
//        .result     (result)
//    );

//    //--------------------------------------
//    // Clock
//    //--------------------------------------

//    always #5 clk = ~clk;

//    //--------------------------------------
//    // Drive task
//    //--------------------------------------

//    task automatic drive_one(
//        input logic [15:0] a_i,
//        input logic [15:0] b_i
//    );
//    begin
//        @(posedge clk);
//        while (!ready) @(posedge clk);

//        A     <= a_i;
//        B     <= b_i;
//        start <= 1'b1;

//        @(posedge clk);
//        start <= 1'b0;

//        wait(valid);
//        @(posedge clk);
//    end
//    endtask

//    //--------------------------------------
//    // Random 8-bit generator
//    //--------------------------------------

//    function automatic logic [15:0] rand_8();
//    begin
//        rand_8 = $urandom & 16'h00FF;
//    end
//    endfunction

//    //--------------------------------------
//    // Main
//    //--------------------------------------

//    initial begin

//        clk   = 0;
//        rst_n = 0;
//        start = 0;

//        total_bits = 8;
//        exp_bits   = 4;

//        repeat(5) @(posedge clk);

//        rst_n = 1;

//        repeat(5) @(posedge clk);

//        //----------------------------------
//        // Run 1000 cases
//        //----------------------------------

//        repeat(1000) begin
//            drive_one(rand_8(), rand_8());
//        end

//        #100;

//        $finish;

//    end

//endmodule
`timescale 1ns/1ps

module tb_fp;

    logic clk;
    logic rst_n;
    logic start;
    logic ready;
    logic valid;

    logic [4:0] total_bits;
    logic [3:0] exp_bits;

    logic [15:0] A;
    logic [15:0] B;
    logic [15:0] result;

    reconfig_fp_top dut (
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

    always #5 clk = ~clk;

    task automatic drive_one(
        input logic [15:0] a_i,
        input logic [15:0] b_i
    );
    begin
        @(posedge clk);
        while (!ready) @(posedge clk);

        A     <= a_i;
        B     <= b_i;
        start <= 1'b1;

        @(posedge clk);
        start <= 1'b0;

        wait(valid);
        @(posedge clk);
    end
    endtask

    function automatic logic [15:0] rand_val();
    begin
        rand_val = $urandom & ((1 << total_bits) - 1);
    end
    endfunction

    initial begin

        clk   = 0;
        rst_n = 0;
        start = 0;

        // <<< SET CONFIG HERE >>>

        total_bits = 6;
        exp_bits   = 1;

        repeat(5) @(posedge clk);

        rst_n = 1;

        repeat(5) @(posedge clk);

        repeat(1000) begin
            drive_one(rand_val(), rand_val());
        end

        #100;
        $finish;

    end

endmodule