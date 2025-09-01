module Checker(input clk, INF.CHECKER inf);
import usertype::*;

covergroup spec1 @(posedge clk iff inf.amnt_valid);
     coverpoint inf.D.d_money {
	  option.at_least = 10;
        bins bins_0 = {[0:12000]};
        bins bins_1 = {[12001:24000]};
        bins bins_2 = {[24001:36000]};
        bins bins_3 = {[36001:48000]};
        bins bins_4 = {[48001:60000]};
    }
endgroup

covergroup spec2 @(posedge clk iff inf.id_valid);
    coverpoint inf.D.d_id[0] {
        option.auto_bin_max = 256;
        option.at_least = 2;
    }
endgroup

covergroup spec3 @(posedge clk iff inf.act_valid);
    coverpoint inf.D.d_act[0] {
        bins transition [] = (Buy,Check,Deposit,Return => Buy,Check,Deposit,Return);
        option.at_least = 10;
    }
endgroup

covergroup spec4 @(posedge clk iff inf.item_valid);
    coverpoint inf.D.d_item[0] {
        option.at_least = 20;
        bins bins_large = {Large};
        bins bins_medium = {Medium};
        bins bins_small = {Small};
    }
endgroup
covergroup spec5 @(negedge clk iff inf.out_valid);
    coverpoint inf.err_msg {
        ignore_bins ig_message = {No_Err};
        bins bins_INV_Not_Enough = {INV_Not_Enough};
	    bins bins_out_of_money = {Out_of_money};
	    bins bins_INV_Full = {INV_Full};
	    bins bins_Wallet_is_Full = {Wallet_is_Full};
	    bins bins_Wrong_ID = {Wrong_ID};
	    bins bins_Wrong_Num = {Wrong_Num};
	    bins bins_Wrong_Item = {Wrong_Item};
	    bins bins_Wrong_act = {Wrong_act};
        option.at_least = 20;
    }
endgroup


covergroup spec6 @(negedge clk iff inf.out_valid);
    coverpoint inf.complete {
        bins bins_0 = {0};
        bins bins_1 = {1};
        option.at_least = 200;
    }
endgroup

spec1 spec1_inst = new();
spec2 spec2_inst = new();
spec3 spec3_inst = new();
spec4 spec4_inst = new();
spec5 spec5_inst = new();
spec6 spec6_inst = new();

assertion_1:
    assert property(assert_reset)
    else begin
        $display("Assertion 1 is violated");
        $fatal;
    end

property assert_reset;
    @(inf.rst_n) (inf.rst_n == 0) |-> ((inf.out_valid == 0) && (inf.complete == 0) && (inf.out_info == 0) && (inf.err_msg == No_Err)
        && (inf.C_addr == 0) && (inf.C_data_w == 0) && (inf.C_in_valid == 0) && (inf.C_r_wb == 0) && (inf.C_out_valid == 0) && (inf.C_data_r == 0)
        && (inf.AR_VALID == 0) && (inf.AR_ADDR == 0) && (inf.R_READY == 0) && (inf.AW_VALID == 0) && (inf.AW_ADDR == 0) && (inf.W_VALID == 0)
        && (inf.W_DATA == 0) && (inf.B_READY == 0) );
endproperty: assert_reset

assertion_2:
    assert property(assert_complete_1)
    else begin
        $display("Assertion 2 is violated");
        $fatal;
    end

property assert_complete_1;
    @(posedge clk) inf.complete |-> inf.err_msg == No_Err;
endproperty: assert_complete_1

assertion_3:
    assert property(assert_complete_2)
    else begin
        $display("Assertion 3 is violated");
        $fatal;
    end

property assert_complete_2;
    @(posedge clk) (inf.complete == 0) |-> inf.out_info == 0;
endproperty: assert_complete_2

assertion_4:
    assert property(assert_input)
    else begin
        $display("Assertion 4 is violated");
        $fatal;
    end

property assert_input;
    @(posedge clk) (inf.id_valid | inf.act_valid | inf.item_valid | inf.num_valid | inf.amnt_valid) |=> 
        ((inf.id_valid == 0) && (inf.act_valid == 0) && (inf.item_valid == 0) && (inf.num_valid == 0) && (inf.amnt_valid == 0));
endproperty: assert_input

Action act;
logic [2:0] cnt;
logic act_valid;

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) act<=No_action;
    else if(inf.act_valid) act<=inf.D.d_act[0];
    else if(inf.out_valid) act<=No_action;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) cnt<=0;
    else if(inf.out_valid) cnt<=0;
    else if(act == Check) cnt<=cnt+1;
end

always_ff@(posedge clk)
begin
    act_valid<=inf.act_valid;
end

assertion_5_1:
    assert property(assert_buyer_to_act)
    else begin
        $display("Assertion 5 is violated");
        $fatal;
    end

property assert_buyer_to_act;
    @(posedge clk iff act == No_action) inf.id_valid |=> ##[1:5] inf.act_valid;
endproperty:assert_buyer_to_act

assertion_5_2_1:
    assert property(assert_Buy_Return_1)
    else begin
        $display("Assertion 5 is violated");
        $fatal;
    end

assertion_5_2_2:
    assert property(assert_Buy_Return_2)
    else begin
        $display("Assertion 5 is violated");
        $fatal;
    end

assertion_5_2_3:
    assert property(assert_Buy_Return_3)
    else begin
        $display("Assertion 5 is violated");
        $fatal;
    end


property assert_Buy_Return_1;
    @(posedge clk iff (act == Return || act == Buy)) act_valid |-> ##[1:5] inf.item_valid;
endproperty:assert_Buy_Return_1

property assert_Buy_Return_2;
    @(posedge clk iff (act == Return || act == Buy)) inf.item_valid |=> ##[1:5] inf.num_valid;
endproperty:assert_Buy_Return_2

property assert_Buy_Return_3;
    @(posedge clk iff (act == Return || act == Buy)) inf.num_valid |=> ##[1:5] inf.id_valid;
endproperty:assert_Buy_Return_3


assertion_5_3:
    assert property(assert_Check)
    else begin
        $display("Assertion 5 is violated");
        $fatal;
    end

property assert_Check;
    @(posedge clk iff act == Check) act_valid |-> ##[1:5] (inf.id_valid || cnt == 5);
endproperty:assert_Check


assertion_5_4:
    assert property(assert_Deposit)
    else begin
        $display("Assertion 5 is violated");
        $fatal;
    end

property assert_Deposit;
    @(posedge clk iff act == Deposit) act_valid |-> ##[1:5] inf.amnt_valid;
endproperty:assert_Deposit


assertion_6:
    assert property(@(posedge clk) (inf.id_valid + inf.act_valid + inf.item_valid + inf.num_valid + inf.amnt_valid == 1) ||
        (inf.id_valid + inf.act_valid + inf.item_valid + inf.num_valid + inf.amnt_valid == 0))
    else begin
        $display("Assertion 6 is violated");
        $fatal;
    end


assertion_7:
    assert property(@(posedge clk) inf.out_valid |=> (inf.out_valid == 0))
    else begin
        $display("Assertion 7 is violated");
        $fatal;
    end

assertion_8:
    assert property(@(posedge clk) inf.out_valid |=> ##[1:9] (inf.id_valid | inf.act_valid))
    else begin
        $display("Assertion 8 is violated");
        $fatal;
    end


assertion_9_1:
    assert property(assert_buy_return_wait)
    else begin
        $display("Assertion 9 is violated");
        $fatal;
    end

assertion_9_2:
    assert property(assert_check_buyer_wait)
    else begin
        $display("Assertion 9 is violated");
        $fatal;
    end

assertion_9_3:
    assert property(assert_check_seller_wait)
    else begin
        $display("Assertion 9 is violated");
        $fatal;
    end
assertion_9_4:
    assert property(assert_deposit_wait)
    else begin
        $display("Assertion 9 is violated");
        $fatal;
    end

property assert_buy_return_wait;
	@(posedge clk iff (act == Buy || act == Return)) inf.id_valid |-> ##[1:10000] inf.out_valid;
endproperty:assert_buy_return_wait

property assert_check_buyer_wait;
	@(posedge clk iff (act == Check)) act_valid |-> ##[1:9999] inf.out_valid;
endproperty:assert_check_buyer_wait

property assert_check_seller_wait;
	@(posedge clk iff (act == Check)) inf.id_valid |-> ##[1:10000] inf.out_valid;
endproperty:assert_check_seller_wait

property assert_deposit_wait;
	@(posedge clk iff (act == Deposit)) inf.amnt_valid |-> ##[1:10000] inf.out_valid;
endproperty:assert_deposit_wait

endmodule
