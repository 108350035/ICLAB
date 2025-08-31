`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif
`timescale 1ns/10ps
module PATTERN(
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    out_valid,
    out
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg       clk, rst_n;
output reg       in_valid;
output reg [1:0] init;
output reg [1:0] in0, in1, in2, in3; 


input            out_valid;
input      [1:0] out; 
//================================================================
// parameter and integer and reg
//================================================================
reg [1:0] map [0:63] [0:3];
integer total_cycles,lattency_cycles,out_cycles,cur_line;
integer patcount,total_cost;
integer gap_of_patterns;
integer i,step;
integer seed = 26;
integer x;
parameter PATNUM = 300;
parameter [1:0] lo_obstacle = 2'b01,hi_obstacle = 2'b10,train = 2'b11,road = 2'b00;
parameter [1:0] forward = 2'd0,right = 2'd1,left = 2'd2,jump = 2'd3;

//================clock=========================================//
always #(`CYCLE_TIME/2.0) clk =~clk;
initial clk=0;
//===============initial=======================================//
initial begin
    rst_n = 1'b1;
    in_valid = 1'b0;
    init = 'bx;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
    force clk = 0;
    total_cost = 0;
    total_cycles = 0;
    reset_task;
    @(negedge clk);

    for(patcount=0;patcount<PATNUM;patcount = patcount + 1) begin
		input_data;
        wait_out_valid;
        check_ans;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,lattency_cycles);
    end
    #1000;
    cost_task;
    pass_task;
    $finish;
end

task reset_task;
begin
    #10; rst_n = 1'b0;

    #10;
    if((out_valid !== 1'b0) || (out !== 2'b0)) begin
        $display ("------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                  SPEC 3 FAIL!                                          ");
		$display ("------------------------------------------------------------------------------------------------------------------------");

    #100;
    $finish;
    end

    #10; rst_n = 1'b1;
    #(3.0) release clk;
end endtask

task input_data;
begin
    gap_of_patterns = $random(seed) % 'd6;
    repeat(gap_of_patterns)@(negedge clk);
	init = $random(seed)% 'd4;
    cur_line = init;
    x=0;
	gen_map;
    in_valid = 1'b1;
    for(i=0;i<64;i=i+1) begin
        in0 = map[i][0];
        in1 = map[i][1];
        in2 = map[i][2];
        in3 = map[i][3];
    @(negedge clk);
    if(i==0) init = 'bx;
    if(out_valid!==1'b0) begin
        $display ("------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                  SPEC 5 FAIL!                                          ");
		$display ("------------------------------------------------------------------------------------------------------------------------");

    repeat(3)@(negedge clk);
    $finish;
    end else if (out!==2'b00) begin
        $display ("------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                  SPEC 4 FAIL!                                          ");
		$display ("------------------------------------------------------------------------------------------------------------------------");

    repeat(3)@(negedge clk);
    $finish;
    end
    x = x + 1;
    end
    in_valid = 1'b0;
    init = 'bx;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
    
end
endtask

task gen_map; 
begin
    integer col,row;
    for(row=0;row<4;row=row+1) begin
        col = 0 ;
	    while(col < 64 ) begin
            if(col == 0 && row == cur_line) begin
                map[col][row] = road;
                col = col + 1;
            end
            else if(col % 8 == 0) begin
                if(($random(seed) % 'd2) == 1) begin
                    if(row == 3 && map[col][0] == train && map[col][1] == train && map[col][2] == train) begin
                        map[col][row] = road;
                        col = col + 1;
                    end
                    else begin
                        map[col][row] = train;
                        map[col+1][row] = train;
                        map[col+2][row] = train;
                        map[col+3][row] = train;
                        col = col + 4;
                    end
                end
                    else begin
                        map[col][row] = road;
                        col = col + 1;
                    end
            end
            else if(col % 2 == 0) begin
                map[col][row] = $random(seed) % 'd3;
                col = col + 1;
            end
            else begin 
                map[col][row] = road;
                col = col + 1;
            end
        end
	end
end
endtask

task print_map; 
begin
    integer col,row;
    for(row=0;row<4;row=row+1) begin
	    for(col=0;col<64;col=col+1) begin
		    $display("%d",map[col][row]);
        end
	    $display("\n");
    end
end
endtask

task wait_out_valid;
begin
    lattency_cycles = 0;
    while(out_valid==1'b0) begin
        lattency_cycles = lattency_cycles + 1;
        if(lattency_cycles == 3000) begin
            $display ("------------------------------------------------------------------------------------------------------------------------");
		    $display ("                                                                  SPEC 6 FAIL!                                          ");
		    $display ("------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
    @(negedge clk);
    end
    total_cycles = lattency_cycles + total_cycles;
end
endtask

task check_ans;
begin
    step = 0;
    out_cycles = 0;
    while(out_valid == 1'b1) begin
        if(cur_line < 0 || cur_line > 3) begin
            $display ("------------------------------------------------------------------------------------------------------------------------");
		    $display ("                                                                  SPEC 8-1 FAIL!                                        ");
		    $display ("------------------------------------------------------------------------------------------------------------------------");
            @(negedge clk);
            $finish;
        end
        else begin
            case(out)
                forward: if(map[step+1][cur_line]==lo_obstacle) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-2 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else if(map[step+1][cur_line]==train) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-4 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else total_cost = total_cost + 1;

                right: if(map[step+1][cur_line+1]==lo_obstacle) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-2 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else if(map[step+1][cur_line+1]==hi_obstacle) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-3 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else if(map[step+1][cur_line+1]==train) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-4 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else begin
                            cur_line = cur_line + 1;
                            total_cost = total_cost + 2;
                        end

                left:  if(map[step+1][cur_line-1]==lo_obstacle) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-2 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else if(map[step+1][cur_line-1]==hi_obstacle) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-3 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else if(map[step+1][cur_line-1]==train) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-4 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            $display(" in step = %d ,out = %d cur_line = %d" ,step,out,cur_line);
                            @(negedge clk);
                            $finish;
                        end else begin
                            cur_line = cur_line - 1;
                            total_cost = total_cost + 2;
						end

                jump: if(map[step+1][cur_line]===hi_obstacle) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-3 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else if(map[step+1][cur_line]==train) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-4 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else if(map[step][cur_line]==lo_obstacle) begin
                            $display ("------------------------------------------------------------------------------------------------------------------------");
		                    $display ("                                                                  SPEC 8-5 FAIL!                                        ");
		                    $display ("------------------------------------------------------------------------------------------------------------------------");
                            @(negedge clk);
                            $finish;
                        end else total_cost = total_cost + 4;
                    endcase
                end
                @(negedge clk);
                step = step + 1;
                out_cycles = out_cycles + 1;
            end

            if(out_cycles !== 63) begin
                $display ("------------------------------------------------------------------------------------------------------------------------");
		        $display ("                                                                  SPEC 7 FAIL!                                          ");
		        $display ("------------------------------------------------------------------------------------------------------------------------");
                @(negedge clk);
                $finish;
            end
            @(negedge clk);

end
endtask

task cost_task;
begin
    $display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                           Your total cost = %d          						                      ", total_cost);
	$display ("----------------------------------------------------------------------------------------------------------------------");
end
endtask
    

task pass_task;
begin
    $display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                						            ");
	$display ("                                           You have passed all patterns!          						            ");
	$display ("                                           Your execution cycles = %5d cycles   						            ", total_cycles);
	$display ("                                           Your clock period = %.1f ns        					                ", `CYCLE_TIME);
	$display ("                                           Your total latency = %.1f ns         						            ", total_cycles*`CYCLE_TIME);
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$finish;
end
endtask

    

endmodule


// fail.txt
// SPEC 3 IS FAIL!
// The reset signal (rst_n) would be given only once at the beginning of simulation. All output 
// signals should be reset after the reset signal is asserted.

// SPEC 4 IS FAIL!
// The out should be reset when your out_valid is low.

// SPEC 5 IS FAIL!
// The out_valid should not be high when in_valid is high.

// SPEC 6 IS FAIL!
// The execution latency is limited in 3000 cycles. The latency is the time of the clock cycles 
// between the falling edge of the in_valid and the rising edge of the out_valid.

// SPEC 7 IS FAIL!
// The out_valid and out must be asserted successively in 63 cycles.


// SPEC 8-1 IS FAIL!
// - SPEC 8-1 (5%): The character cannot run outside the map.

// SPEC 8-2 IS FAIL!
// - SPEC 8-2 (5%): The character must avoid hitting lower obstacles.

// SPEC 8-3 IS FAIL!
// - SPEC 8-3 (5%): The character must avoid hitting higher obstacles.

// SPEC 8-4 IS FAIL!
// - SPEC 8-4 (5%): The character must avoid hitting trains.

// SPEC 8-5 IS FAIL!
// - SPEC 8-5 (5%): If you are on a lower obstacle (2’b01), you cannot use jump.