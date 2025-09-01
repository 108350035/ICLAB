
`ifdef RTL
    `timescale 1ns/1ps
    //`include "CDC.v"
    `define CYCLE_TIME_clk1 14.1
    `define CYCLE_TIME_clk2 2.5
    `define CYCLE_TIME_clk3 2.7
`endif
`ifdef GATE
    `timescale 1ns/1ps
    `include "CDC_SYN.v"
    `define CYCLE_TIME_clk1 14.1
    `define CYCLE_TIME_clk2 2.5
    `define CYCLE_TIME_clk3 2.7
`endif

module PATTERN(
    // Output signals
    clk_1,
    clk_2,
    clk_3,
    rst_n,
    in_valid,
    mode,
    CRC,
    message,

    // Input signals
    out_valid,
    out
    
);
//======================================
//          I/O PORTS
//======================================
output reg        clk_1;
output reg        clk_2;
output reg        clk_3;
output reg        rst_n;
output reg        in_valid;
output reg        mode;
output reg [59:0] message;
output reg        CRC;

input             out_valid;
input [59:0]      out;
//=====================================
//      PARAMETER AND REG
//=====================================
parameter CLK1 = `CYCLE_TIME_clk1;
parameter CLK2 = `CYCLE_TIME_clk2;
parameter CLK3 = `CYCLE_TIME_clk3;
parameter PATNUM = 500;
integer i,patcount,latency,total;
integer a,b,c,d,data_txt;
reg [59:0] golden;
//=====================================
//           CLOCK
//=====================================
initial clk_1 = 0;
always#(CLK1 / 2) clk_1 = ~clk_1;
initial clk_2 = 0;
always#(CLK2 / 2) clk_2 = ~clk_2;
initial clk_3 = 0;
always#(CLK3 / 2) clk_3 = ~clk_3;
//====================================


initial begin
    data_txt = $fopen("data.txt","r");
    rst_n = 1;
    in_valid = 0;
    mode = 1'bx;
    message = 60'bx;
    CRC = 1'bx;
    force clk_1 = 0;
    force clk_2 = 0;
    force clk_3 = 0;
    total = 0;
    reset_task;
    for(patcount = 0;patcount<PATNUM;patcount=patcount+1) begin
        data_task;
        d=$fscanf(data_txt,"%b",golden);
        wait_outvalid;
        ans_check;
    end
    pass_task;
    $finish;
end


task reset_task;
begin
    rst_n = 0;
    #3;
    if( (out != 0) || (out_valid != 0)) begin
        $display ("------------------------------------------------------------------------------------------------------------------------");
		$display ("                          All output signals should be reset after the reset signal is asserted.                        ");
		$display ("------------------------------------------------------------------------------------------------------------------------");
        repeat(2) @(negedge clk_1);
        $finish;
    end
    #3; rst_n = 1'b1;
    #3; release clk_1;
    release clk_2;
    release clk_3;
end
endtask

task data_task;
begin
    repeat($urandom_range(1,3)) @(negedge clk_1);
    in_valid = 1;
    a = $fscanf(data_txt,"%d",CRC);
    b = $fscanf(data_txt,"%d",mode);
    c = $fscanf(data_txt,"%b",message);
    @(negedge clk_1);
    in_valid = 0;
    message = 60'bx;
    CRC = 1'bx;
    mode = 1'bx;
end
endtask

task wait_outvalid;
begin
    latency = 0;
	while (out_valid == 1'b0) begin
        latency = latency + 1;
		if(latency == 400) begin
			$display ("-------------------------------------------------------------------------------------------------------------------");
			$display ("                                        The cycles of execution latency is more than 400                          ");
			$display ("-------------------------------------------------------------------------------------------------------------------");
			$finish;
			end
	    else if(out != 'b0) begin
		    $display ("-------------------------------------------------------------------------------------------------------------------");
		    $display ("                                        The out should be reset after your out_valid is pulled down                ");
		    $display ("-------------------------------------------------------------------------------------------------------------------");
		    $finish;
	    end
        @(negedge clk_3);
    end
    total = total + latency;
end
endtask


task ans_check;
begin
    #1;
    if(out != golden) begin
        $display ("-------------------------------------------------------------------------------------------------------------------");
		$display ("                                        output = %b is not equal ans = %b                             ",out,golden);
		$display ("-------------------------------------------------------------------------------------------------------------------");
        @(negedge clk_3);
        $finish;
    end
    else begin
        $display("\033[0;34mPASS PATTERN NO.%4d,Cycles: %3d\033[m", patcount ,latency);
        @(negedge clk_3);
        check_valid;
    end
end
endtask

task check_valid;
begin
    if(out_valid == 1'b1) begin
         $display ("-------------------------------------------------------------------------------------------------------------------");
		 $display ("                                           out_valid is high over 1 clcye                                          ");
		 $display ("-------------------------------------------------------------------------------------------------------------------");
         @(negedge clk_3);
         $finish;
    end
end
endtask

    

task pass_task;
begin
		$display ("---------------------------------------------------------------------------------------------------");
		$display ("                            congratulations! You have passed all patterns!                         ");
		$display ("                            Your execution cycles = %5d cycles                               ",total);
		//$display ("                            Your clock period = %.1f ns                                ",`CYCLE_TIME);
		//$display ("                            TOTAL LATENCY = %.1f ns                       ",`CYCLE_TIME*total_latency);
		$display ("---------------------------------------------------------------------------------------------------");
		@(negedge clk_1);
        $finish;
end
endtask

endmodule
