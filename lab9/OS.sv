module OS(input clk, INF.OS_inf inf);
import usertype::*;

integer i,j;
logic w_en,check_deposit,item_full,item_full_cal,S_item_enough,S_item_enough_cal,B_out_of_money,B_out_of_money_cal,buyer_read_done,C_out_valid_buf;
logic validity_buf,cal_buf,id_valid_buf,cnt,cnt_buf;
PERSON BUYER,SELLER;
User_id recent_buyer_record [255:0];
logic [1:0] identify_b_s [255:0];
logic [31:0] out_temp;
logic [15:0] amount;
logic [16:0] deposit_money,seller_money;
logic [12:0] exp_ns,exp_temp;
logic [8:0] price;
logic [7:0] BUYER_ID,SELLER_ID;
logic [6:0] fee;
logic [5:0] item_num;
logic [3:0] return_message,buy_message,deposit_message,action;
logic [2:0] cnt_to_5;
logic [1:0] level_ns,item;
STATE_OS cs,ns;

always_comb
begin
    case(cs)
        OS_IDLE:ns=(inf.id_valid | inf.act_valid)?S_BUYER:OS_IDLE;
        S_BUYER:ns=(action[3] | action[0])?S_BUY_RETURN:((action[2])?S_CHECK_DEPOSIT:((action[1])?S_CHECK_DEPOSIT:S_BUYER));
        S_CHECK_DEPOSIT:ns=(inf.id_valid)?S_SELLER:((cnt_to_5 == 5 | inf.amnt_valid)?S_WAIT_READ_B:S_CHECK_DEPOSIT);
        S_BUY_RETURN:ns=(inf.id_valid)?S_SELLER:S_BUY_RETURN;
        S_SELLER:ns=(buyer_read_done)?S_WAIT_READ_B:S_SELLER;
        S_WAIT_READ_B:ns=(buyer_read_done & (inf.C_out_valid | check_deposit | action[2]))?S_CAL:S_WAIT_READ_B;
        S_CAL:ns=(cal_buf)?S_VALIDITY:S_CAL;
        S_VALIDITY:ns=(validity_buf)?((w_en)?S_ACT:S_OUT):S_VALIDITY;
        S_ACT:ns=(cnt)?S_WAIT_WRITE_B:S_ACT;
        S_WAIT_WRITE_B:ns=(inf.C_out_valid)?((action[1] | action[2])?S_OUT:S_WAIT_WRITE_S):S_WAIT_WRITE_B;
        S_WAIT_WRITE_S:ns=(inf.C_out_valid)?S_OUT:S_WAIT_WRITE_S;
        S_OUT:ns=OS_IDLE;
        default:ns=OS_IDLE;
    endcase
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) C_out_valid_buf<=0;
    else C_out_valid_buf<=inf.C_out_valid;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) cal_buf<=0;
    else cal_buf<=(cs == S_CAL)?1:0;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) validity_buf<=0;
    else validity_buf<=(cs == S_VALIDITY)?1:0;
end



always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) begin
        for(j= 0;j<256;j=j+1) begin
            recent_buyer_record[j]<=0;
        end
    end
    else if(inf.complete) begin
        recent_buyer_record[SELLER_ID]<=(action[0])?BUYER_ID:recent_buyer_record[SELLER_ID];
    end
end


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) begin
        for(i=0;i<256;i=i+1) begin
            identify_b_s[i]<=2;//0-->buy 1-->sell 2-->none
        end
    end
    else if(inf.complete) begin
        if(action[0]) begin
            identify_b_s[SELLER_ID]<=1;
            identify_b_s[BUYER_ID]<=0;
        end
        else if(action[1]) begin
            identify_b_s[BUYER_ID]<=2;
            identify_b_s[SELLER_ID]<=(check_deposit == 0)?2:identify_b_s[SELLER_ID];
        end
        else if(action[2]) identify_b_s[BUYER_ID]<=2;
        else begin
            identify_b_s[SELLER_ID]<=2;
            identify_b_s[BUYER_ID]<=2;
        end
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) cs<=OS_IDLE;
    else cs<=ns;
end

always_ff@(posedge clk)
begin
    id_valid_buf<=inf.id_valid;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) buyer_read_done<=0;
    else if(inf.C_out_valid) buyer_read_done<=1;
    else if(cs == OS_IDLE && inf.id_valid) buyer_read_done<=0;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) return_message<=0;
    else if(cal_buf & action[3]) begin
        if( identify_b_s[BUYER_ID] != 0 || identify_b_s[BUYER.user.shop_history.seller_ID] != 1 || recent_buyer_record[BUYER.user.shop_history.seller_ID] != BUYER_ID)
            return_message<=15;
        else if(BUYER.user.shop_history.seller_ID != SELLER_ID)
            return_message<=9;
        else if(BUYER.user.shop_history.item_num != item_num)
            return_message<=12;
        else if(BUYER.user.shop_history.item_ID != item)
            return_message<=10;
        else return_message<=0;
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) w_en<=0;
    else if(validity_buf == 0 && cs == S_VALIDITY) begin
        if(action[3]) w_en<=(return_message == 0)?1:0;
        else if(action[2]) w_en<=(deposit_message == 0)?1:0;
        else if(action[0]) w_en<=(buy_message == 0)?1:0;
        else w_en <= 0;
    end
    else if(inf.out_valid) w_en<=0;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) cnt<=0;
    else if(cs == S_ACT) cnt<=cnt+1;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) cnt_buf<=0;
    else cnt_buf<=cnt;
end



assign deposit_money = amount + BUYER.user.money;

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) deposit_message<=0;
    else if(cal_buf & action[2]) begin
        if( deposit_money > 65535)
            deposit_message<=8;
        else deposit_message<=0;
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) buy_message<=0;
    else if(cal_buf & action[0]) begin
        if(item_full) buy_message<=4;
        else if(S_item_enough) buy_message<=2;
        else if(B_out_of_money) buy_message<=3;
        else buy_message<=0;
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) cnt_to_5<=0;
    else if(inf.act_valid) cnt_to_5<=0;
    else if(cs == S_CHECK_DEPOSIT) cnt_to_5<=(cnt_to_5 == 5)?5:cnt_to_5+1;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) check_deposit<=0;
    else if(cs == S_CHECK_DEPOSIT)  check_deposit<=(cnt_to_5 == 5)?1:0;
    else if(inf.out_valid) check_deposit<=0;
end


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) BUYER_ID<=0;
    else if(inf.id_valid && cs == OS_IDLE) BUYER_ID<=inf.D.d_id[0];
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) SELLER_ID<=0;
    else if(inf.id_valid && (cs == S_BUY_RETURN || cs == S_CHECK_DEPOSIT)) SELLER_ID<=inf.D.d_id[0];
end


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) begin
        inf.C_addr<=0;
        inf.C_r_wb<=0;
        inf.C_in_valid<=0;
        inf.C_data_w<=0;
    end
    else if(cs == S_BUYER & id_valid_buf) begin
        inf.C_addr<=BUYER_ID;
        inf.C_r_wb<=1;
        inf.C_in_valid<=1;
    end
    else if(cs == S_SELLER & buyer_read_done) begin
        inf.C_addr<=SELLER_ID;
        inf.C_r_wb<=1;
        inf.C_in_valid<=1;
    end
    else if(cs == S_WAIT_WRITE_B & cnt_buf) begin
        inf.C_addr<=BUYER_ID;
        inf.C_r_wb<=0;
        inf.C_in_valid<=1;
        inf.C_data_w<=1;
        {inf.C_data_w[19:16],inf.C_data_w[31:24]}<=BUYER.shop.exp;
        {inf.C_data_w[39:32],inf.C_data_w[47:40]}<=BUYER.user.money;
        inf.C_data_w[21:20]<=BUYER.shop.level;
        inf.C_data_w[7:2]<=BUYER.shop.large_num;
        {inf.C_data_w[1:0],inf.C_data_w[15:12]}<=BUYER.shop.medium_num;
        {inf.C_data_w[11:8],inf.C_data_w[23:22]}<=BUYER.shop.small_num;
        inf.C_data_w[63:56]<=BUYER.user.shop_history.seller_ID;
        inf.C_data_w[55:54]<=BUYER.user.shop_history.item_ID;
        inf.C_data_w[53:48]<=BUYER.user.shop_history.item_num;
    end
    else if(cs == S_WAIT_WRITE_S & C_out_valid_buf) begin
        inf.C_addr<=SELLER_ID;
        inf.C_r_wb<=0;
        inf.C_in_valid<=1;
        {inf.C_data_w[19:16],inf.C_data_w[31:24]}<=SELLER.shop.exp;
        {inf.C_data_w[39:32],inf.C_data_w[47:40]}<=SELLER.user.money;
        inf.C_data_w[21:20]<=SELLER.shop.level;
        inf.C_data_w[7:2]<=SELLER.shop.large_num;
        {inf.C_data_w[1:0],inf.C_data_w[15:12]}<=SELLER.shop.medium_num;
        {inf.C_data_w[11:8],inf.C_data_w[23:22]}<=SELLER.shop.small_num;
        inf.C_data_w[63:56]<=SELLER.user.shop_history.seller_ID;
        inf.C_data_w[55:54]<=SELLER.user.shop_history.item_ID;
        inf.C_data_w[53:48]<=SELLER.user.shop_history.item_num;

    end
    else inf.C_in_valid<=0;
end
    

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) action<=0;
    else if(inf.act_valid) action<=inf.D.d_act[0];
    else if(inf.out_valid) action<=0;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) inf.err_msg<=No_Err;
    else if(cs == S_OUT) begin
        if(action[0]) inf.err_msg<=buy_message;
        else if(action[1]) inf.err_msg<=No_Err;
        else if(action[2]) inf.err_msg<=deposit_message;
        else inf.err_msg<=return_message;
    end
    else inf.err_msg<=No_Err;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) item<=0;
    else if(inf.item_valid) item<=inf.D.d_item[0];
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) item_num<=0;
    else if(inf.num_valid) item_num<=inf.D.d_item_num[5:0];
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) item_full<=0;
    else if(cs == S_CAL) item_full<=item_full_cal;
end

always_comb
begin
    if(action[0]) begin
        case(item)
            1:item_full_cal = (BUYER.shop.large_num + item_num > 63)?1:0;
            2:item_full_cal = (BUYER.shop.medium_num + item_num > 63)?1:0;
            default:item_full_cal = (BUYER.shop.small_num + item_num > 63)?1:0;
        endcase
    end
    else item_full_cal = 0;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) S_item_enough<=0;
    else if(cs == S_CAL) S_item_enough<=S_item_enough_cal;
end


always_comb
begin
    if(action[0]) begin
        case(item)
            1:S_item_enough_cal = (SELLER.shop.large_num < item_num)?1:0;
            2:S_item_enough_cal = (SELLER.shop.medium_num < item_num)?1:0;
            default:S_item_enough_cal = (SELLER.shop.small_num < item_num)?1:0;
        endcase
    end
    else S_item_enough_cal = 0;
end


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) B_out_of_money<=0;
    else if(cs == S_CAL) B_out_of_money<=B_out_of_money_cal;
end


always_comb
begin
    if(action[0]) begin
        case(item)
            1:B_out_of_money_cal = (BUYER.user.money < (item_num*price + fee))?1:0;
            2:B_out_of_money_cal = (BUYER.user.money < (item_num*price + fee))?1:0;
            default:B_out_of_money_cal = (BUYER.user.money < (item_num*price + fee))?1:0;
        endcase
    end
    else B_out_of_money_cal = 0;
end


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) out_temp<=0;
    else if(ns == S_OUT) begin
        case(action)
            1:out_temp<={BUYER.user.money,BUYER.user.shop_history.item_ID,BUYER.user.shop_history.item_num,BUYER.user.shop_history.seller_ID};
            2:out_temp<=(check_deposit)?{16'b0,BUYER.user.money}:{14'd0,SELLER.shop.large_num,SELLER.shop.medium_num,SELLER.shop.small_num};
            4:out_temp<={16'b0,BUYER.user.money};
            8:out_temp<={14'd0,BUYER.shop.large_num,BUYER.shop.medium_num,BUYER.shop.small_num};
        endcase
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) amount<=0;
    else if(inf.amnt_valid) amount<=inf.D.d_money;
end

always_comb
begin
    if(action[0]) begin
        case(item)
            1:exp_ns=BUYER.shop.exp+(60*item_num);
            2:exp_ns=BUYER.shop.exp+(40*item_num);
            3:exp_ns=BUYER.shop.exp+(20*item_num);
            default:exp_ns = 0;
        endcase
    end
    else exp_ns = 0;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) exp_temp<=0;
    else if(action[0] & cs == S_ACT & cnt == 0) begin
        exp_temp<=exp_ns;
    end
end


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) BUYER<=0;
    else if(buyer_read_done == 0 & inf.C_out_valid) begin
        BUYER.shop.exp<={inf.C_data_r[19:16],inf.C_data_r[31:24]};
        BUYER.shop.level<=inf.C_data_r[21:20];
        BUYER.shop.small_num<={inf.C_data_r[11:8],inf.C_data_r[23:22]};
        BUYER.shop.medium_num<={inf.C_data_r[1:0],inf.C_data_r[15:12]};
        BUYER.shop.large_num<=inf.C_data_r[7:2];
        BUYER.user.money<={inf.C_data_r[39:32],inf.C_data_r[47:40]}; 
        BUYER.user.shop_history.seller_ID<=inf.C_data_r[63:56];
        BUYER.user.shop_history.item_ID<=inf.C_data_r[55:54];
        BUYER.user.shop_history.item_num<=inf.C_data_r[53:48];
    end
    else if(action[0] & cs == S_ACT & cnt == 0) begin
        BUYER.shop.large_num<=(item == 1)?BUYER.shop.large_num + item_num:BUYER.shop.large_num;
        BUYER.shop.small_num<=(item == 3)?BUYER.shop.small_num + item_num :BUYER.shop.small_num;
        BUYER.shop.medium_num<=(item == 2)?BUYER.shop.medium_num+ item_num :BUYER.shop.medium_num;
        BUYER.user.shop_history.seller_ID<=SELLER_ID;
        BUYER.user.shop_history.item_ID<=item;
        BUYER.user.shop_history.item_num<=item_num;
        BUYER.user.money<=BUYER.user.money - (price * item_num);
    end
    else if(action[0] & cs == S_ACT & cnt) begin
        case(BUYER.shop.level)
            3:begin
                BUYER.shop.exp<=(exp_temp >= 1000)?0:exp_temp;
                BUYER.shop.level<=level_ns;
                BUYER.user.money<=BUYER.user.money - fee;
            end
            2:begin
                BUYER.shop.exp<=(exp_temp >= 2500)?0:exp_temp;
                BUYER.shop.level<=level_ns;
                BUYER.user.money<=BUYER.user.money - fee;
            end
            1:begin
                BUYER.shop.exp<=(exp_temp >= 4000)?0:exp_temp;
                BUYER.shop.level<=level_ns;
                BUYER.user.money<=BUYER.user.money - fee;
            end
            default:BUYER.user.money<=BUYER.user.money - fee;
        endcase
    end
    else if(action[2] & cs == S_ACT & cnt == 0) begin
        BUYER.user.money<=amount + BUYER.user.money;
    end
    else if(action[3] & cs == S_ACT & cnt == 0) begin
        BUYER.shop.large_num<=(BUYER.user.shop_history.item_ID == 1)?BUYER.shop.large_num - BUYER.user.shop_history.item_num :BUYER.shop.large_num;
        BUYER.shop.small_num<=(BUYER.user.shop_history.item_ID == 3)?BUYER.shop.small_num - BUYER.user.shop_history.item_num :BUYER.shop.small_num;
        BUYER.shop.medium_num<=(BUYER.user.shop_history.item_ID == 2)?BUYER.shop.medium_num - BUYER.user.shop_history.item_num :BUYER.shop.medium_num;
        BUYER.user.money<=BUYER.user.money + (price * BUYER.user.shop_history.item_num);
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) fee<=0;
    else if(action[0]) begin
        case(BUYER.shop.level)
            3:fee <= 70;
            2:fee <= 50;
            1:fee <= 30;
            default:fee <= 10;
        endcase
    end
end

always_comb
begin
    if(action[0]) begin
        case(BUYER.shop.level)
            3:level_ns=(exp_temp >= 1000)?BUYER.shop.level-1:BUYER.shop.level;
            2:level_ns=(exp_temp >= 2500)?BUYER.shop.level-1:BUYER.shop.level;
            1:level_ns=(exp_temp >= 4000)?BUYER.shop.level-1:BUYER.shop.level;
            default:level_ns=0;
        endcase
    end
    else begin
        level_ns = 0;
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) SELLER<=0;
    else if(cs == S_WAIT_READ_B & inf.C_out_valid) begin
        SELLER.shop.exp<={inf.C_data_r[19:16],inf.C_data_r[31:24]};
        SELLER.shop.level<=inf.C_data_r[21:20];
        SELLER.shop.small_num<={inf.C_data_r[11:8],inf.C_data_r[23:22]};
        SELLER.shop.medium_num<={inf.C_data_r[1:0],inf.C_data_r[15:12]};
        SELLER.user.money<={inf.C_data_r[39:32],inf.C_data_r[47:40]};
        SELLER.shop.large_num<=inf.C_data_r[7:2];
        SELLER.user.shop_history.seller_ID<=inf.C_data_r[63:56];
        SELLER.user.shop_history.item_ID<=inf.C_data_r[55:54];
        SELLER.user.shop_history.item_num<=inf.C_data_r[53:48];
    end
    else if(action[0] & cs == S_ACT & cnt == 0) begin
        SELLER.shop.large_num<=(item == 1 && SELLER.shop.large_num >= item_num )?SELLER.shop.large_num - item_num :SELLER.shop.large_num;
        SELLER.shop.medium_num<=(item == 2 && SELLER.shop.medium_num >= item_num )?SELLER.shop.medium_num - item_num :SELLER.shop.medium_num;
        SELLER.shop.small_num<=(item == 3 && SELLER.shop.small_num >= item_num )?SELLER.shop.small_num - item_num :SELLER.shop.small_num;
        SELLER.user.money<=(SELLER.user.money + (price * item_num) >= 65535)?65535:seller_money;
    end
    else if(action[3] & cs == S_ACT & cnt == 0) begin
        SELLER.shop.large_num<=(BUYER.user.shop_history.item_ID == 1)?SELLER.shop.large_num + BUYER.user.shop_history.item_num :SELLER.shop.large_num;
        SELLER.shop.medium_num<=(BUYER.user.shop_history.item_ID == 2)?SELLER.shop.medium_num + BUYER.user.shop_history.item_num :SELLER.shop.medium_num;
        SELLER.shop.small_num<=(BUYER.user.shop_history.item_ID == 3)?SELLER.shop.small_num + BUYER.user.shop_history.item_num :SELLER.shop.small_num;
        SELLER.user.money<=SELLER.user.money - (price * BUYER.user.shop_history.item_num);
    end
end

assign seller_money = SELLER.user.money + (price * item_num);


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) price<=0;
    else if(action[3]) begin
            case(BUYER.user.shop_history.item_ID)
                1:price <= 300;
                2:price <= 200;
                default:price <= 100;
            endcase
    end
    else begin
        case(item)
            1:price <= 300;
            2:price <= 200;
            default:price <= 100;
        endcase
    end
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) begin
        inf.out_valid<=0;
        inf.out_info<=0;
        inf.complete<=0;
    end
    else if(cs == S_OUT) begin
        inf.out_valid<=1;
        inf.out_info<=(w_en | action[1])?out_temp:0;
        inf.complete<=w_en | action[1];
    end
    else begin
        inf.out_valid<=0;
        inf.out_info<=0;
        inf.complete<=0;
    end
end


endmodule
