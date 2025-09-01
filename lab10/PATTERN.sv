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
parameter PATNUM = 2000;
integer patcount,total_cycle,latency;



initial begin
    verification = new();
    verification.read_file();
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
        set_mode;
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

task set_mode;
begin
    if(patcount < 10) begin //test Err_msg:out_of_money
        verification.test_out_of_money = 1;
        verification.rand_pat.Buy_precent = 100;
    end
    else if(patcount < 25) begin //test Err_msg:INV_not_enough
        verification.test_out_of_money = 0;
        verification.test_not_enough = 1;
    end
    else if(patcount < 40) begin //test Err_msg:INV_is_Full
        verification.test_not_enough = 0;
        verification.test_INV_Full = 1;
    end
    else if(patcount < 50) begin
        verification.test_INV_Full = 0;
        verification.rand_pat.Buy_precent = 0;
        verification.rand_pat.Check_precent = 100;
    end
    else if(patcount < 65) begin //test Err_msg:Wallet_is_Full
        verification.rand_pat.Check_precent = 0;
        verification.test_Wallet_Full = 1;
        verification.rand_pat.Deposit_precent = 100;
    end
    else if(patcount < 130) begin
        verification.test_Wallet_Full = 0;
    end
    else if(patcount < 160) begin
        verification.rand_pat.Deposit_precent = 0;
        verification.rand_pat.Buy_precent = 100;
        verification.test_Return = 1;
    end
    else if(patcount < 280) begin //test Err_msg:Wrong Item
        verification.rand_pat.Return_precent = 100;
        verification.rand_pat.Buy_precent = 0;
        verification.test_Wrong_Item = 1;
    end
    else if(patcount < 310) begin //test Err_msg:Wrong Num
        verification.test_Wrong_Item = 0;
        verification.test_Wrong_Num = 1;
    end
    else if(patcount < 340) begin //test Err_msg:Wrong ID

        verification.test_Wrong_ID = 1;
        verification.test_Wrong_Num = 0;
    end
    else begin
        verification.test_Return = 0;
        verification.test_Wrong_ID = 0;
        verification.rand_pat.Buy_precent = 25;
        verification.rand_pat.Check_precent = 25;
        verification.rand_pat.Deposit_precent = 25;
        verification.rand_pat.Return_precent = 25;
        verification.rand_pat.change_buyer_precent = 80;
        verification.rand_pat.change_seller_precent = 100;
    end
    verification.rand_pat.randomize();
    verification.get_data();
    verification.gen_msg();
end
endtask

task input_task;
begin
    if(verification.rand_pat.buyer_valid | verification.test_Return) begin
        inf.id_valid = 1;
        inf.D = {8'd0,verification.pat_data.buyer_id};
        @(negedge clk);
        inf.id_valid = 0;
        inf.D = 16'bx;
        repeat($urandom_range(1,5)) @(negedge clk);
    end
    inf.act_valid = 1;
    inf.D = {12'b0,verification.rand_pat.act};
    @(negedge clk);
    inf.act_valid = 0;
    inf.D = 16'bx;
    repeat($urandom_range(1,5)) @(negedge clk);
    case(verification.rand_pat.act) 
        Buy:begin
           inf.item_valid = 1;
           inf.D = {14'b0,verification.pat_data.item_id};
           @(negedge clk);
           inf.item_valid = 0;
           inf.D = 16'bx;
           repeat($urandom_range(1,5)) @(negedge clk);
           inf.num_valid = 1;
           inf.D = {10'b0,verification.pat_data.item_num};
           @(negedge clk);
           inf.num_valid = 0;
           inf.D = 16'bx;
           repeat($urandom_range(1,5)) @(negedge clk);
           inf.id_valid = 1;
           inf.D = {8'd0,verification.pat_data.seller_id};
           @(negedge clk);
           inf.id_valid = 0;
           inf.D = 16'bx;
        end

        Check:
            if(verification.rand_pat.seller_valid == 1) begin
            inf.id_valid = 1;
            inf.D = {8'd0,verification.pat_data.seller_id};
            @(negedge clk);
            inf.id_valid = 0;
            inf.D = 16'bx;
        end

        Deposit:begin
            inf.amnt_valid = 1;
            inf.D = verification.pat_data.deposit_money;
            @(negedge clk);
            inf.amnt_valid = 0;
            inf.D = 16'bx;
        end

        Return:begin
            inf.item_valid = 1;
            inf.D = {14'b0,verification.pat_data.item_id};
            @(negedge clk);
            inf.item_valid = 0;
            inf.D = 16'bx;
            repeat($urandom_range(1,5)) @(negedge clk);
            inf.num_valid = 1;
            inf.D = {10'b0,verification.pat_data.item_num};
            @(negedge clk);
            inf.num_valid = 0;
            inf.D = 16'bx;
            repeat($urandom_range(1,5)) @(negedge clk);
            inf.id_valid = 1;
            inf.D = {8'd0,verification.pat_data.seller_id};
            @(negedge clk);
            inf.id_valid = 0;
            inf.D = 16'bx;
        end
    endcase
end
endtask

task wait_out_valid;
begin
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
        verification.update_trade();
    end
    verification.cal_out_info();
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
    


            

            
            


