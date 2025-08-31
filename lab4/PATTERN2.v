`ifdef RTL
	`define CYCLE_TIME 14.0
`endif
`ifdef GATE
	`define CYCLE_TIME 14.0
`endif

`timescale 1ns/10ps

module PATTERN(//edit
	// Output signals
	clk,
	rst_n,
	in_valid_d,
	in_valid_t,
	in_valid_w1,
	in_valid_w2,
	data_point,
	target,
	weight1,
	weight2,
	// Input signals
	out_valid,
	out
);
//---------------------------------------------------------------------
//   PARAMETER and INTEGER
//---------------------------------------------------------------------
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
parameter delay = 0.1;
parameter PATNUM = 20;
integer latency_cycles,total_cycles,patcount,i,j,a,b,c,d,e;
integer weight1_txt,weight2_txt,data_txt,target_txt,golden_txt,round,epoch;
real point_weight,out_sign,ans_sign,out_exponent,ans_exponent,exponent_weight,out_fraction,ans_fraction,ans_real_value,out_real_value,difference;
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
output reg [inst_sig_width+inst_exp_width:0] data_point, target;
output reg [inst_sig_width+inst_exp_width:0] weight1, weight2;
input	out_valid;
input	[inst_sig_width+inst_exp_width:0] out;
//=================================//
//         REG AND WIRE
//================================//
reg [inst_sig_width+inst_exp_width:0] golden;
//=================clock===========//
always #(`CYCLE_TIME/2) clk = ~clk;
initial clk = 0;
//================================//
//            IP                 
//===============================//

initial begin
	weight1_txt=$fopen("weight1.txt","r");
	weight2_txt=$fopen("weight2.txt","r");
	data_txt=$fopen("data.txt","r");
	target_txt=$fopen("target.txt","r");
    golden_txt=$fopen("golden.txt","r");
    rst_n = 1'b1;
    in_valid_d = 1'b0;
    in_valid_t = 1'b0;
    in_valid_w1 = 1'b0;
    in_valid_w2 = 1'b0;
    target = 'bx;
    data_point = 'bx;
    weight1 = 'bx;
    weight2 = 'bx;
    force clk = 0;
    latency_cycles = 0;
    total_cycles = 0;
    reset_task;
    @(negedge clk);
	for(patcount = 0;patcount < PATNUM;patcount = patcount + 1) begin
	    weight_task;
        repeat(2) @(negedge clk);
        for(epoch=0;epoch<25;epoch=epoch+1) begin
		    for(round = 0;round<100;round = round + 1) begin
		        data_and_target_task;
		        wait_out_valid;
                ans_check;
		    end
        end
    end
    @(negedge clk);
	pass_task;

end

task reset_task;
begin
    #10; rst_n = 1'b0;
    #10; if((out != 'b0) || (out_valid != 1'b0)) begin
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

task weight_task;
begin
    in_valid_w1 = 1'b1;
	in_valid_w2 = 1'b1;
	for(i=0;i<12;i=i+1) begin
		b=$fscanf(weight1_txt,"%b",weight1);
		if(i<3) begin
            a=$fscanf(weight2_txt,"%b",weight2);
        end else begin
            in_valid_w2 = 1'b0;
	        weight2 = 'bx;
        end
        @(negedge clk);
	end
	in_valid_w1 = 1'b0;
	weight1 = 'bx;
end
endtask

task data_and_target_task;
begin
    in_valid_d = 1'b1;
    in_valid_t = 1'b1;
	for(i=0;i<4;i=i+1) begin
            c=$fscanf(data_txt,"%b",data_point);
            if(i==0) begin
                d=$fscanf(target_txt,"%b",target);
                e=$fscanf(golden_txt,"%b",golden);
            end else begin
                in_valid_t = 1'b0;
			    target = 'bx;
            end
            @(negedge clk);
        end
	in_valid_d = 1'b0;
	data_point = 'bx;
end
endtask

task wait_out_valid;
begin
	latency_cycles = 0;
	while (out_valid == 1'b0) begin
        latency_cycles = latency_cycles + 1;
		if(latency_cycles == 300) begin
			$display ("-------------------------------------------------------------------------------------------------------------------");
			$display ("                                        The cycles of execution latency is more than 300                           ");
			$display ("-------------------------------------------------------------------------------------------------------------------");
			$finish;
			end
	    else if(out != 'b0) begin
		    $display ("-------------------------------------------------------------------------------------------------------------------");
		    $display ("                                        The out should be reset after your out_valid is pulled down                           ");
		    $display ("-------------------------------------------------------------------------------------------------------------------");
		    $finish;
	    end
        @(negedge clk);
    end
    total_cycles = total_cycles + latency_cycles;
end
endtask

task pass_task;
begin
		$display ("---------------------------------------------------------------------------------------------------");
		$display ("                            congratulations! You have passed all patterns!                         ");
		$display ("                            Your execution cycles = %5d cycles                        ",total_cycles);
		$display ("                            Your clock period = %.1f ns                                ",`CYCLE_TIME);
		$display ("                            TOTAL LATENCY = %.1f ns                       ",`CYCLE_TIME*total_cycles);
		$display ("---------------------------------------------------------------------------------------------------");
		@(negedge clk);
        $finish;
end
endtask

task ans_check;
begin
     ans_fraction = 1;
     out_fraction = 1;
     ans_sign = (golden[31])?-1:1;
     out_sign = (out[31])?-1:1;
     point_weight=0.5;
     exponent_weight=1;
     out_exponent = - 127;
     ans_exponent = - 127;
     for(i=22;i>=0;i=i-1) begin
         if(golden[i] == 1) ans_fraction = ans_fraction + point_weight;
         if(out[i] == 1) out_fraction = out_fraction + point_weight;
         point_weight = point_weight / 2;
    end

    for(j=23;j<=30;j=j+1) begin
        if(golden[j] == 1) ans_exponent = ans_exponent + exponent_weight;
        if(out[j] == 1) out_exponent = out_exponent + exponent_weight;
        exponent_weight = exponent_weight *2;
    end

    ans_real_value = ans_sign*ans_fraction*(2**ans_exponent);
    out_real_value = out_sign*out_fraction*(2**out_exponent);
    difference =(ans_real_value-out_real_value)/ans_real_value;
    $display("The value of my_value is: %f",difference);
     if(difference > 0.0001 || difference < -0.0001)  begin
         $display ("-------------------------------------------------------------------------------------------------------------------");
		 $display ("                                        output = %.1f is not equal ans = %.1f                             ",out_real_value,ans_real_value );
		 $display ("-------------------------------------------------------------------------------------------------------------------");
         @(negedge clk);
         $finish;
     end
     else begin
         check_out_valid;
         $display("\033[0;34mPASS PATTERN NO.%4d, epoch NO.%4d\033[m \033[0;32m ROUND NO.%4d\033[m \033[0;32m Cycles: %3d\033[m", patcount+1 ,epoch+1,round+1,latency_cycles);
    end
end
endtask

task check_out_valid;
begin
    @(negedge clk);
    if(out_valid == 1'b1) begin
         $display ("-------------------------------------------------------------------------------------------------------------------");
		 $display ("                                           out_valid is high over 1 clcye                                          ");
		 $display ("-------------------------------------------------------------------------------------------------------------------");
         @(negedge clk);
         $finish;
     end
    @(negedge clk);
end
endtask
endmodule

