`define CYCLE_TIME 8


module PATTERN(
	// Output signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Input signals
	out_valid,
	out_data
);


output reg clk;
output reg rst_n;
output reg cg_en;
output reg in_valid;
output reg [8:0] in_data;
output reg [2:0] in_mode;

input out_valid;
input [8:0] out_data;

//===================
//
// REG AND PARAMETER 
//
// ==================
real  period = `CYCLE_TIME;
integer mode_txt,input_txt,output_txt,latency,total;
integer i,a,b,c,patcount;
parameter PATNUM = 1000;
reg [8:0] golden [5:0],data [5:0];
reg [2:0] mode; 

//=========
//
//   CLK
//
//=========

initial clk = 0;
always#(period/2) clk = ~clk;


initial begin
    input_txt = $fopen("input.txt","r");
    output_txt = $fopen("output.txt","r");
    mode_txt = $fopen("mode.txt","r");
    total = 0;
    cg_en = 1;
    rst_n = 1;
    in_valid = 0;
    in_mode = 3'bx;
    in_data = 9'bx;
    force clk = 0;
    #5;
    reset_task;
    @(negedge clk);
    for(patcount = 0;patcount<PATNUM;patcount=patcount+1) begin
        data_task;
        wait_valid;
        check_task;
    end
    @(negedge clk);
    pass;
    $finish;
end

task reset_task;
begin
    rst_n = 0;
    #5;
    if(out_data != 0 ||  out_valid != 0) begin
        $display("************************************************************");
        $display("*                       ICLAB08 FAIL                       *");
        $display("*   Output signal should be 0 after initial RESET at %t    *",$time);
        $display("************************************************************");
        $finish;
    end
    #5; rst_n = 1;
    release clk;
end
endtask

task data_task;
begin
    repeat(2) @(negedge clk);
    in_valid = 1;
    for(i = 0;i<6;i=i+1) begin
        a =$fscanf(input_txt,"%d",in_data);
        data[i] = in_data;
        c =$fscanf(output_txt,"%d",golden[i]);
        if(i == 0) begin
            b=$fscanf(mode_txt,"%b",in_mode);
            mode = in_mode;
        end
        else in_mode = 3'bx;
        @(negedge clk);
    end
    in_data = 9'bx;
    in_valid = 0;
end
endtask

task wait_valid;
begin
    latency = 0;
    while(out_valid == 0) begin
        if(latency > 2000) begin
            $display("***************************************************************");
		    $display("*     		    ICLAB08 FAIL      							*");
		    $display("*         The execution latency are over 2000 cycles.         *");
		    $display("***************************************************************");
		    repeat(2)@(negedge clk);
		    $finish;
        end
        latency = latency + 1;
        @(negedge clk);
    end
    total = total + latency;
end
endtask

task check_task;
begin
    for(i=0;i<6;i=i+1) begin
        if(out_data != golden[i]) begin
            $display ("--------------------------------------------------------------------");
		    $display ("                     PATTERN #%d  FAILED!!!                         ",patcount);
		    $display ("--------------------------------------------------------------------");
            $display ("          out_data = %d , golden[%1b] = %d  ",out_data, i, golden[i]  );
            $display ("              mode = %b , a =  %d ,%d ,%d ,%d ,%d ,%d ",mode,data[0],data[1],data[2],data[3],data[4],data[5]);
		    $display ("--------------------------------------------------------------------");
		    repeat(2) @(negedge clk);		
		    $finish;
        end
        @(negedge clk);
    end
	$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",patcount ,latency);
end
endtask


task pass;
begin
    $display ("--------------------------------------------------------------------");
    $display ("          ~(￣▽￣)~(＿△＿)~(￣▽￣)~(＿△＿)~(￣▽￣)~                 ");
    $display ("                         Congratulations!                           ");
    $display ("                  You have passed all patterns!                     ");
    $display ("           total latency = %d    , period = %d ns      ",total,period);
    $display ("--------------------------------------------------------------------");        
    #10;
end 
endtask


endmodule

