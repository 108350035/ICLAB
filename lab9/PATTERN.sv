`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_OS.sv"
`include "PATTERN_def.sv"

//just show===========
`ifdef RTL
`define CYCLE_TIME 3.3
`endif

`ifdef GATE
`define CYCLE_TIME 3.3
`endif
//====================
import usertype::*;
program automatic PATTERN(input clk, INF.PATTERN inf);
VERIFICATION verification;


//================================================================
// parameters & integer
//================================================================
parameter PATNUM = 50000;
integer patcount,total_cycle,latency;



initial begin
    verification = new();
    verification.dram.read_file();
    verification.init_user();
    total_cycle = 0;
    inf.rst_n = 1;
    inf.D = 16'bx;
    inf.id_valid = 0;
    inf.act_valid = 0;
    inf.item_valid = 0;
    inf.num_valid = 0;
    inf.amnt_valid = 0;
    @(negedge clk);
    reset_task;
    for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
        input_task;
        wait_out_valid;
        compare_task;
    end
    pass_task;
    $finish;
end


task reset_task;
begin
    inf.rst_n = 0;
    @(negedge clk);
    if(inf.out_valid | inf.err_msg | inf.complete | inf.out_info) begin
        $display ("------------------------------------------------------------------------------------------------------------------------");
		$display ("                          All output signals should be reset after the reset signal is asserted.                        ");
		$display ("------------------------------------------------------------------------------------------------------------------------");
        repeat(2) @(negedge clk);
        $finish;
    end
    @(negedge clk) ;
    inf.rst_n = 1'b1;
    repeat(2) @(negedge clk);
end
endtask


task input_task;
begin
    verification.randpat_data.randomize();
    if(patcount == 0 || verification.randpat_data.buyer_valid == 1) begin
        verification.randpat_data.randomize();
        verification.read_buyer();
        inf.id_valid = 1;
        inf.D = {8'd0,verification.id.buyer_id};
        @(negedge clk);
        inf.id_valid = 0;
        inf.D = 16'bx;
        repeat($urandom_range(1,5)) @(negedge clk);
    end
    inf.act_valid = 1;
    inf.D = {12'b0,verification.randpat_data.act};
    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 16'bx;
    repeat($urandom_range(1,5)) @(negedge clk);
    case(verification.randpat_data.act) 
        Buy:begin
           inf.item_valid = 1;
           inf.D = {14'b0,verification.randpat_data.item_id};
           @(negedge clk);
           inf.item_valid = 0;
           inf.D = 16'bx;
           repeat($urandom_range(1,5)) @(negedge clk);
           inf.num_valid = 1;
           inf.D = {10'b0,verification.randpat_data.item_num};
           @(negedge clk);
           inf.num_valid = 0;
           inf.D = 16'bx;
           repeat($urandom_range(1,5)) @(negedge clk);
           verification.read_seller();
           inf.id_valid = 1;
           inf.D = {8'd0,verification.id.seller_id};
           @(negedge clk);
           inf.id_valid = 0;
           inf.D = 16'bx;
        end

        Check:
            if(verification.randpat_data.seller_valid == 1) begin
            verification.read_seller();
            inf.id_valid = 1;
            inf.D = {8'd0,verification.id.seller_id};
            @(negedge clk);
            inf.id_valid = 0;
            inf.D = 16'bx;
        end

        Deposit:begin
            inf.amnt_valid = 1;
            inf.D = verification.randpat_data.deposit_money;
            @(negedge clk);
            inf.amnt_valid = 0;
            inf.D = 16'bx;
        end

        Return:begin
            inf.item_valid = 1;
            inf.D = {14'b0,verification.randpat_data.item_id};
            @(negedge clk);
            inf.item_valid = 0;
            inf.D = 16'bx;
            repeat($urandom_range(1,5)) @(negedge clk);
            inf.num_valid = 1;
            inf.D = {10'b0,verification.randpat_data.item_num};
            @(negedge clk);
            inf.num_valid = 0;
            inf.D = 16'bx;
            repeat($urandom_range(1,5)) @(negedge clk);
            verification.read_seller();
            inf.id_valid = 1;
            inf.D = {8'd0,verification.id.seller_id};
            @(negedge clk);
            inf.id_valid = 0;
            inf.D = 16'bx;
        end
    endcase
end
endtask

task wait_out_valid;
begin
    verification.message_check();
    latency = 0;
    while (inf.out_valid == 0) begin
        latency = latency + 1;
        if(latency == 10001) begin
            $display ("-------------------------------------------------------------------------------------------------------------------");
			$display ("                                        The cycles of execution latency is more than 10000                         ");
			$display ("-------------------------------------------------------------------------------------------------------------------");
			$finish;
			end
        else if(inf.out_info || inf.complete || inf.err_msg) begin
            $display ("-------------------------------------------------------------------------------------------------------------------");
		    $display ("                              The output signal should be reset after your out_valid is pulled down                ");
		    $display ("-------------------------------------------------------------------------------------------------------------------");
		    $finish;
        end
        @(negedge clk);
    end
    if(verification.golden_ans.complete == 1) begin
        verification.do_operation();
        verification.cal_out_info();
        verification.update_trade();
        case(verification.randpat_data.act)
            Buy,Return:begin
                verification.write_buyer();
                verification.write_seller();
            end
            Deposit:verification.write_buyer();
        endcase
    end
    else verification.golden_ans.out_info = 0;
    total_cycle = total_cycle + latency;
end
endtask

task compare_task;
begin
    if(inf.complete != verification.golden_ans.complete || inf.out_info != verification.golden_ans.out_info || inf.err_msg != verification.golden_ans.message) begin
        $display ("----------------------------------------------------------------------------------------------------------------");
        $display ("                                      PATTERN NO. %10d                                                       ", patcount);
		$display ("                            Yours                              Golden                                           ");
        $display ("                         complete:%2d                        complete:%2d             ",inf.complete,verification.golden_ans.complete);
        $display ("                         Err_msg :%2d                        Err_msg :%2d               ",inf.err_msg,verification.golden_ans.message);
        $display ("                         out_info:%8h                  out_info:%8h             ",inf.out_info,verification.golden_ans.out_info);
		$display ("---------------------------------------------------------------------------------------------------------------");
        @(negedge clk);
        $finish;
    end
    else begin
        $display ("-------------------------------------------------------------------------------------------------------------------");
		$display ("                         PATTERN NO.%5d  PASS!   latency: %5d           ",patcount,latency);
	    $display ("-------------------------------------------------------------------------------------------------------------------");
    end
    repeat($urandom_range(2,10)) @(negedge clk);
end
endtask
    

task pass_task;
begin
		$display ("---------------------------------------------------------------------------------------------------");
		$display ("                            congratulations! You have passed all patterns!                         ");
		$display ("                            Your execution cycles = %8d cycles                        ",total_cycle);
		$display ("                            Your clock period = %.1f ns                                ",`CYCLE_TIME);
		$display ("                            TOTAL LATENCY = %.1f ns                                  ",`CYCLE_TIME * total_cycle);
		$display ("---------------------------------------------------------------------------------------------------");
end
endtask

endprogram
    


            

            
            


