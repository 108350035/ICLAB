`ifdef RTL
	`define CYCLE_TIME 6.8
`endif
`ifdef GATE
	`define CYCLE_TIME 6.8
`endif
`timescale 1ns/10ps


module PATTERN(
// output signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
// input signals
    out_valid,
    out_value
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk, rst_n;

output reg in_valid;
output reg [7:0] matrix;
output reg [1:0]  matrix_size;

output reg in_valid2;
output reg [4:0]  matrix_idx;
output reg [1:0]  mode;

input 				out_valid;
input signed [49:0] out_value;

//==========================================
//    INTEGER AND REG AND PARAMETER AND WIRE
//==========================================
integer patcount,mode_txt,element_txt,index_txt,ans_txt,size_txt;
integer total_latency,latency,a,b,c,d,e,random_cycles,actual_size;
integer i,j,k;
parameter PATNUM=50;

reg [1:0] size;
reg signed [49:0] golden_ans [0:9];


//=========================================
initial clk = 0;
always #(`CYCLE_TIME/2) clk=~clk;
//========================================


initial begin
    mode_txt = $fopen("mode.txt","r");
    element_txt = $fopen("element.txt","r");
    index_txt = $fopen("index.txt","r");
    size_txt = $fopen("size.txt","r");
    ans_txt = $fopen("ans.txt","r");
    @(negedge clk);
    rst_n = 1'b1;
    in_valid = 1'b0;
	in_valid2 = 1'b0;
    matrix = 'bx;
	matrix_size = 'bx;
    matrix_idx = 'bx;
    mode = 'bx;
    force clk = 0;
    total_latency = 0;
    latency = 0;
    reset_task;
    @(negedge clk);
    for(patcount = 0;patcount<PATNUM;patcount = patcount +1) begin
        golden_ans_task;
        a =$fscanf(size_txt,"%d",size);
        size_element_task;
        for(i = 0;i<10;i=i+1) begin
            idx_mode_task;
            wait_out_valid;
            check_ans;
        end
    end
    @(negedge clk);
    pass_task;
end

task reset_task;
begin
    #10; rst_n = 1'b0;
    #10;if((out_valid != 1'b0) || (out_value != 'b0)) begin
        $display ("------------------------------------------------------------------------------------------------------------------------");
		$display ("                          All output signals should be reset after the reset signal is asserted.                        ");
		$display ("------------------------------------------------------------------------------------------------------------------------");
    repeat(2) @(negedge clk);
    $finish;
    end
    #10; rst_n = 1'b1;
    #(3.0) release clk;
end
endtask

task size_element_task;
begin
    random_cycles = $urandom_range(1, 5);
    case(size)
        2'b00: actual_size = 2;
        2'b01: actual_size = 4; 
        2'b10: actual_size = 8; 
        2'b11: actual_size = 16;
    endcase
    repeat(random_cycles) @(negedge clk);
    in_valid = 1'b1;
    for(i = 0;i<32;i = i+1) begin
        for(j = 0;j<actual_size*actual_size;j=j+1) begin
            b = $fscanf(element_txt,"%d",matrix);
            if(i == 0 && j==0) matrix_size = size;
            else matrix_size = 'bx;
            @(negedge clk);
        end
    end
    in_valid = 1'b0;
    matrix = 'bx;
end
endtask

task idx_mode_task;
begin
    random_cycles = $urandom_range(1, 3);
    repeat(random_cycles) @(negedge clk);
    in_valid2 = 1'b1;
    for(j=0;j<3;j=j+1) begin
        c = $fscanf(index_txt,"%d",matrix_idx);
        if(j == 0) d = $fscanf(mode_txt,"%d",mode);
        else mode = 'bx;
        @(negedge clk);
    end
    in_valid2 = 1'b0;
    matrix_idx = 'bx;
end
endtask

task wait_out_valid;
begin
    latency = 0;
	while (out_valid == 1'b0) begin
        latency = latency + 1;
		if(latency == 10000) begin
			$display ("-------------------------------------------------------------------------------------------------------------------");
			$display ("                                        The cycles of execution latency is more than 10000                          ");
			$display ("-------------------------------------------------------------------------------------------------------------------");
			$finish;
			end
	    else if(out_value != 'b0) begin
		    $display ("-------------------------------------------------------------------------------------------------------------------");
		    $display ("                                        The out should be reset after your out_valid is pulled down                ");
		    $display ("-------------------------------------------------------------------------------------------------------------------");
		    $finish;
	    end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end
endtask

task golden_ans_task;
begin
    for(j = 0;j<10;j=j+1) begin 
        e = $fscanf(ans_txt,"%d",golden_ans[j]);
    end
    k=0;
end
endtask

task check_ans;
begin
    if(out_value != golden_ans[k]) begin
        $display ("-------------------------------------------------------------------------------------------------------------------");
		$display ("                                        output = %d is not equal ans = %d                             ",out_value,golden_ans[k]);
		$display ("-------------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
    else begin
        k = k + 1;
        $display("\033[0;34mPASS PATTERN NO.%4d, ROUND NO.%4d\033[m \033[0;32m Cycles: %3d\033[m", patcount ,k+1,latency);
        if(i == 9) random_cycles = $urandom_range(1, 5);
        else random_cycles = $urandom_range(1, 3);
        repeat(random_cycles) @(negedge clk);
        if(out_valid == 1'b1) begin
         $display ("-------------------------------------------------------------------------------------------------------------------");
		 $display ("                                           out_valid is high over 1 clcye                                          ");
		 $display ("-------------------------------------------------------------------------------------------------------------------");
         @(negedge clk);
         $finish;
        end
    end
end
endtask

task pass_task;
begin
		$display ("---------------------------------------------------------------------------------------------------");
		$display ("                            congratulations! You have passed all patterns!                         ");
		$display ("                            Your execution cycles = %5d cycles                        ",total_latency);
		$display ("                            Your clock period = %.1f ns                                ",`CYCLE_TIME);
		$display ("                            TOTAL LATENCY = %.1f ns                       ",`CYCLE_TIME*total_latency);
		$display ("---------------------------------------------------------------------------------------------------");
		@(negedge clk);
        $finish;
end
endtask
endmodule
