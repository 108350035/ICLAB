//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : PATTERN.v
//   	Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL_TOP
    `define CYCLE_TIME 18.9
`endif

`ifdef GATE_TOP
    `define CYCLE_TIME 18.9
`endif

module PATTERN (
    // Output signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Input signals
    out_valid, out_Rx, out_Ry
);

    // ===============================================================
    // I/O Declaration
    // ===============================================================
    output reg clk, rst_n, in_valid;
    output reg [5:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
    input out_valid;
    input [5:0] out_Rx, out_Ry;
    // ===============================================================
    // Variables Declaration
    // ===============================================================
        integer patcount,lattency,total_lattency,b,c;
        reg [5:0] x,y,Px,Py,Qx,Qy,prime,a;
        parameter PATNUM=2000;
    //---------------------------------------------------------------------
    //   CLOCK GENERATION
    //---------------------------------------------------------------------
    initial clk = 0;
    always #(`CYCLE_TIME / 2) clk = ~clk;
    //---------------------------------------------------------------------
    //   MAIN FLOW
    //---------------------------------------------------------------------
    initial begin
        b = $fopen("input.txt","r");
        rst_n = 1;
        in_valid = 0;
        in_Px = 'bx;
        in_Py = 'bx;
        in_Qx = 'bx;
        in_Qy = 'bx;
        in_a = 'bx;
        in_prime = 'bx;
        total_lattency = 0;
        force clk = 0;
        #5;
        reset_task;
        $display("abc");
        for(patcount = 0;patcount < PATNUM;patcount = patcount + 1) begin
            input_task;
            wait_valid;
            compare;
        end
        @(negedge clk);
        pass;
        $finish;
    end


task pass;
begin
    $display ("--------------------------------------------------------------------");
    $display ("          ~(￣▽￣)~(＿△＿)~(￣▽￣)~(＿△＿)~(￣▽￣)~                 ");
    $display ("                         Congratulations!                           ");
    $display ("                  You have passed all patterns!                     ");
    $display ("--------------------------------------------------------------------");        
    #10;
end 
endtask

task compare;
begin
    if(out_Rx != x || out_Ry != y) begin
        $display ("--------------------------------------------------------------------");
		$display ("                     PATTERN #%d  FAILED!!!                         ",patcount);
		$display ("--------------------------------------------------------------------");
        $display ("P:(Px, Py), Q:(Qx, Qy) = (%d, %d), (%d, %d). Prime, a = (%d, %d)",Px, Py, Qx, Qy, prime, a);
		$display ("Ans: R:(Rx, Ry) = (%d, %d), Yours: (%d, %d)",x, y ,out_Rx, out_Ry);		
		$display ("--------------------------------------------------------------------");
		repeat(2) @(negedge clk);		
		$finish;
    end
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",patcount ,lattency);
end
endtask
    

task wait_valid;
begin
    lattency = 0;
    while(out_valid == 0) begin
        if(lattency > 1000) begin
            $display("***************************************************************");
		    $display("*     		    ICLAB06 FAIL      							*");
		    $display("*         The execution latency are over 1000 cycles.         *");
		    $display("***************************************************************");
		    repeat(2)@(negedge clk);
		    $finish;
        end
        lattency = lattency + 1;
        @(negedge clk);
    end
    total_lattency = total_lattency + lattency;
end
endtask





task reset_task;
begin
    rst_n = 0;
    #(`CYCLE_TIME / 2);
    if(out_Rx != 0 || out_Ry != 0 || out_valid != 0) begin
        $display("************************************************************");
        $display("*                       ICLAB06 FAIL                       *");
        $display("*   Output signal should be 0 after initial RESET at %t    *",$time);
        $display("************************************************************");
        $finish;
    end
    #5; rst_n = 1;
    release clk;
end
endtask

task input_task;
begin
    repeat(3) @(negedge clk);
    c =$fscanf(b,"%d %d %d %d %d %d %d %d",Px,Py,Qx,Qy,prime,a,x,y);
    in_valid = 1;
    in_Px = Px;
    in_Py = Py;
    in_Qx = Qx;
    in_Qy = Qy;
    in_prime = prime;
    in_a = a;
    @(negedge clk);
    in_Px = 'bx;
    in_Py = 'bx;
    in_Qx = 'bx;
    in_Qy = 'bx;
    in_a = 'bx;
    in_prime = 'bx;
    in_valid = 0;
end
endtask


    
    



endmodule