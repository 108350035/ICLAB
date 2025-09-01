import usertype::*;



typedef struct packed {
	Error_Msg message;
	logic [31:0] out_info;
	logic complete;
} ANS;

typedef struct packed {
    User_id buyer_id;
    User_id seller_id;
    Item_num item_num;
    Item_id item_id;
    Money deposit_money;
} PAT;
    

class RAND_PAT;
    rand User_id buyer_id;
    rand User_id seller_id;
    rand Action act;
    rand bit buyer_valid;
    rand bit seller_valid;
    int Buy_precent,Check_precent,Deposit_precent,Return_precent;
    int change_buyer_precent,change_seller_precent;
    rand Item_id item_id;
    rand Item_num item_num;
    rand Money deposit_money;
    constraint limit {
        item_id inside {Large,Medium,Small};
        item_num inside{[1:63]};
        deposit_money inside{[1:65535]};
        buyer_id inside{[0:255]};
        seller_id inside{[0:255]};
        buyer_id != seller_id;
        act dist {Buy := Buy_precent, Check := Check_precent, Deposit := Deposit_precent, Return := Return_precent};
        buyer_valid dist{0 := 100 - change_buyer_precent, 1 := change_buyer_precent};
        seller_valid dist{0 := 100 - change_seller_precent, 1 := change_seller_precent };
    }

    function new();
        this.srandom(0);
    endfunction
endclass


class VERIFICATION;
    PERSON user [255:0];
    logic [7:0] data [67583:65536];//10000 to 107FC
    logic seller_record [255:0];
    logic buyer_record [255:0];
    logic seek_table [255:0];
    logic seek_valid;
    User_id recent_buyer [255:0];
    logic [5:0] buyer_stock,seller_stock;
    logic test_INV_Full,test_not_enough,test_out_of_money,test_Return,test_Wallet_Full,test_Wrong_Num,test_Wrong_Item,test_Wrong_ID;
    int unsigned price,earn_exp;
    integer No,z;
    PAT pat_data;
    RAND_PAT rand_pat;
    ANS golden_ans;
    function new();
        integer i,j,k,l;
        rand_pat = new();
        for(i = 0;i < 256;i = i + 1)
            recent_buyer[i] = 0;
        for(k = 0;k < 256;k = k + 1)
            buyer_record[k] = 0;
        for(j = 0;j < 256;j = j + 1)
            seller_record[j] = 0;
        for(l = 0;l < 256;l = l + 1)
            seek_table[l] = 0;
        seek_valid = 0;
        test_INV_Full = 0;
        test_not_enough = 0;
        test_out_of_money = 0;
        test_Return = 0;
        test_Wallet_Full = 0;
        test_Wrong_Num = 0;
        test_Wrong_Item = 0;
        test_Wrong_ID = 0;
    endfunction

    function read_file();
        $readmemh("../00_TESTBED/DRAM/dram.dat",data);
    endfunction

//=========gen_msg========================================================
    function gen_msg();
        case(rand_pat.act)
            Buy:if(test_INV_Full) golden_ans.message = INV_Full;
                else if(test_not_enough) golden_ans.message = INV_Not_Enough;
                else if(test_out_of_money) golden_ans.message = Out_of_money;
                else buy_message();

            Check:golden_ans.message = No_Err;
            Deposit:if(test_Wallet_Full) golden_ans.message = Wallet_is_Full;
                    else deposit_message();
            Return:if(seek_valid & test_Return) begin
                            if(test_Wrong_ID) golden_ans.message = Wrong_ID;
                            else if(test_Wrong_Num) golden_ans.message = Wrong_Num;
                            else if(test_Wrong_Item) golden_ans.message = Wrong_Item;
                    end
                   else return_message();
        endcase
        golden_ans.complete = (golden_ans.message == No_Err)?1:0;
    endfunction 
//===========================================================================
//=======mode=======================
    function buy_mode();
       if(test_INV_Full) begin
           pat_data.item_num = 63;
           pat_data.item_id = rand_pat.item_id;
        end
        else if(test_not_enough) begin
            pat_data.item_num = seller_stock + 1 ;
            pat_data.item_id = rand_pat.item_id;
        end
        else if(test_out_of_money) begin
            pat_data.item_num = 3;
            pat_data.item_id = Large;
        end
        else if(test_Return) begin
            pat_data.item_num = 1;
            pat_data.item_id = rand_pat.item_id;
        end
        else begin
            pat_data.item_num = rand_pat.item_num;
            pat_data.item_id = rand_pat.item_id;
        end
    endfunction

    function deposit_mode();
        if(test_Wallet_Full) pat_data.deposit_money = 65535;
        else pat_data.deposit_money = rand_pat.deposit_money;
    endfunction

    function return_mode();
     	  if(test_Wrong_ID) begin
            pat_data.seller_id = user[pat_data.buyer_id].user.shop_history.seller_ID+6;
            pat_data.item_num = user[pat_data.buyer_id].user.shop_history.item_num;
            pat_data.item_id = rand_pat.item_id;
        end

        else if(test_Wrong_Num) begin
            pat_data.seller_id = user[pat_data.buyer_id].user.shop_history.seller_ID;
            pat_data.item_num = user[pat_data.buyer_id].user.shop_history.item_num + 1;
            pat_data.item_id = user[pat_data.buyer_id].user.shop_history.item_ID;
        end
        else if(test_Wrong_Item) begin
            pat_data.seller_id = user[pat_data.buyer_id].user.shop_history.seller_ID;
            pat_data.item_num = user[pat_data.buyer_id].user.shop_history.item_num;
            pat_data.item_id = (user[pat_data.buyer_id].user.shop_history.item_ID == Large)?Medium:((user[pat_data.buyer_id].user.shop_history.item_ID == Medium)?Small:Large);
        end
        else begin
            pat_data.seller_id = user[pat_data.buyer_id].user.shop_history.seller_ID;
            pat_data.item_num = user[pat_data.buyer_id].user.shop_history.item_num;
            pat_data.item_id = user[pat_data.buyer_id].user.shop_history.item_ID;
        end
    endfunction


//=================Find buyer who made the purchase before return==========
    function User_id avoid_Wrong_act();
        User_id buyer_id;
        buyer_id = 8'b0;
        for(No = 0;No <= 255;No = No + 1) begin
            if(seller_record[user[No].user.shop_history.seller_ID] &  buyer_record[No]
            && recent_buyer[user[No].user.shop_history.seller_ID] == No & seek_table[No] == 0) begin
                seek_table[No] = 1;
                seek_valid = 1;
                return buyer_id;
            end
            else if(No == 255) begin
                for(z = 0;z < 256;z = z + 1) begin
                    seek_table[z] = 0;
                end
                seek_valid = 0;
                return 0;
            end
            else buyer_id = buyer_id + 1;
        end
    endfunction
//==========================================================================


//=========data import and R/W======================================================
    function void data_import_user();
        logic [16:0] addr;
        addr = {1'b1,5'b0,8'b0,3'b0};
        for(No = 0;No <=255;No = No + 1) begin
            user[No].shop.large_num = data[addr][7:2];
            user[No].shop.small_num = {data[addr+1][3:0],data[addr+2][7:6]};
            user[No].shop.medium_num = {data[addr][1:0],data[addr+1][7:4]};
            user[No].shop.exp = {data[addr+2][3:0],data[addr+3][7:0]};
            user[No].shop.level = data[addr+2][5:4];
            user[No].user.money = {data[addr+4][7:0],data[addr+5][7:0]};
            user[No].user.shop_history.item_ID = data[addr+6][7:6];
            user[No].user.shop_history.item_num = data[addr+6][5:0];
            user[No].user.shop_history.seller_ID = data[addr+7][7:0];
            addr = addr + 8;
        end
    endfunction

    function void init_user();
        data_import_user();
        pat_data.buyer_id = 0;
        pat_data.seller_id = 1;
        rand_pat.Buy_precent = 0;
        rand_pat.Check_precent = 0;
        rand_pat.Deposit_precent = 0;
        rand_pat.Return_precent = 0;
        rand_pat.change_buyer_precent = 60;
        rand_pat.change_seller_precent = 60;
    endfunction

    function void get_data();
        case(rand_pat.act)
            Buy:begin
                    if(rand_pat.buyer_valid) pat_data.buyer_id = rand_pat.buyer_id;
                    pat_data.seller_id = (rand_pat.seller_id == pat_data.buyer_id)?rand_pat.seller_id + 5:rand_pat.seller_id;
                    case(rand_pat.item_id)
                        Large:  begin
                            buyer_stock = user[pat_data.buyer_id].shop.large_num;
                            seller_stock = user[pat_data.seller_id].shop.large_num;
                            price = 300;
                            earn_exp = 60;
                        end
                        Medium: begin
                            buyer_stock = user[pat_data.buyer_id].shop.medium_num;
                            seller_stock = user[pat_data.seller_id].shop.medium_num;
                            price = 200;
                            earn_exp = 40;
                        end
                        Small: begin
                            buyer_stock = user[pat_data.buyer_id].shop.small_num;
                            seller_stock = user[pat_data.seller_id].shop.small_num;
                            price = 100;
                            earn_exp = 20;
                        end
                        endcase
                    buy_mode();

            end

            Check:begin
                    if(rand_pat.buyer_valid) pat_data.buyer_id = (rand_pat.buyer_id == pat_data.seller_id)? rand_pat.buyer_id + 3:rand_pat.buyer_id;
                    if(rand_pat.seller_valid) pat_data.seller_id = (rand_pat.seller_id == pat_data.buyer_id)?rand_pat.seller_id + 4:rand_pat.seller_id;
            end

            Deposit:begin
                    if(rand_pat.buyer_valid) pat_data.buyer_id = (rand_pat.buyer_id == pat_data.seller_id)? rand_pat.buyer_id + 5:rand_pat.buyer_id;
                    deposit_mode();
            end

            Return:begin
                    if(test_Wrong_ID | test_Wrong_Item | test_Wrong_Num) pat_data.buyer_id = avoid_Wrong_act();
                    else if(rand_pat.buyer_valid) pat_data.buyer_id = rand_pat.buyer_id;
                    return_mode();
                    case(user[pat_data.buyer_id].user.shop_history.item_ID)
                        Large   :price = 300;
	                    Medium  :price = 200;
	                    Small   :price = 100;
                    endcase

            end
        endcase
    endfunction


//=======================================================================
    
//=============process out_info==================================================================================
    function void cal_out_info();
        if(golden_ans.complete == 1)
            case(rand_pat.act)
                Buy:golden_ans.out_info = user[pat_data.buyer_id].user;
                Check:golden_ans.out_info = (rand_pat.seller_valid)?{14'd0,user[pat_data.seller_id].shop.large_num,user[pat_data.seller_id].shop.medium_num,
                                                                                user[pat_data.seller_id].shop.small_num}:{16'd0,user[pat_data.buyer_id].user.money};
                Deposit:golden_ans.out_info = {16'd0,user[pat_data.buyer_id].user.money};
                Return:golden_ans.out_info = {14'd0,user[pat_data.buyer_id].shop.large_num,user[pat_data.buyer_id].shop.medium_num,user[pat_data.buyer_id].shop.small_num};
            endcase
        else golden_ans.out_info = 0;
    endfunction
//============process out_info ===================================================================================

//===========update trade history ====================================================================
     function void update_trade();
         case(rand_pat.act)
             Buy:buy_update();
             Check:check_update();
             Deposit:deposit_update();
             Return:return_update();
         endcase
     endfunction
     
     function void buy_update();
        seller_record[pat_data.seller_id] = 1;
        seller_record[pat_data.buyer_id] = 0;
        buyer_record[pat_data.buyer_id] = 1;
        buyer_record[pat_data.seller_id] = 0;
        recent_buyer[pat_data.seller_id] = pat_data.buyer_id;
    endfunction

    function void check_update();
        if(rand_pat.seller_valid) begin
            seller_record[pat_data.seller_id] = 0;
            buyer_record[pat_data.seller_id] = 0;
        end
        seller_record[pat_data.buyer_id] = 0;
        buyer_record[pat_data.buyer_id] = 0;
    endfunction

    function void deposit_update();
        buyer_record[pat_data.buyer_id] = 0;
        seller_record[pat_data.buyer_id] = 0;
    endfunction

    function void return_update();
        seller_record[pat_data.seller_id] = 0;
        seller_record[pat_data.buyer_id] = 0;
        buyer_record[pat_data.buyer_id] = 0;
        buyer_record[pat_data.seller_id] = 0;
    endfunction
//============updata trade history ====================================================================


//=============message check======================================================================================================
    function void buy_message();
        int unsigned fee;        
        case(user[pat_data.buyer_id].shop.level)
            Platinum:fee = 10;
            Gold:fee = 30;
            Silver:fee = 50;
            Copper:fee = 70; 
        endcase

        if(buyer_stock + pat_data.item_num > 63) golden_ans.message = INV_Full;
        else if(seller_stock < pat_data.item_num) golden_ans.message = INV_Not_Enough;
        else if(user[pat_data.buyer_id].user.money < (price * pat_data.item_num) + fee) golden_ans.message = Out_of_money;
        else golden_ans.message = No_Err;
    endfunction

    function void deposit_message();
        if(pat_data.deposit_money + user[pat_data.buyer_id].user.money > 65535) golden_ans.message = Wallet_is_Full;
        else golden_ans.message = No_Err;
    endfunction

    function void return_message();
    if(seller_record[user[pat_data.buyer_id].user.shop_history.seller_ID] == 0 || buyer_record[pat_data.buyer_id] == 0 
        || recent_buyer[user[pat_data.buyer_id].user.shop_history.seller_ID] != pat_data.buyer_id) golden_ans.message = Wrong_act;
        else if(user[pat_data.buyer_id].user.shop_history.seller_ID != pat_data.seller_id) golden_ans.message = Wrong_ID;
        else if(pat_data.item_num != user[pat_data.buyer_id].user.shop_history.item_num) golden_ans.message = Wrong_Num;
        else if(pat_data.item_id != user[pat_data.buyer_id].user.shop_history.item_ID) golden_ans.message = Wrong_Item;
        else golden_ans.message = No_Err;
    endfunction

//=============message check======================================================================================================

//============process buyer,seller==========================================================================
    function void do_operation();
        case(rand_pat.act)
            Buy:op_buy();
            Deposit:op_deposit();
            Return:op_return();
        endcase
    endfunction

    function op_buy();
        int unsigned fee;
        user[pat_data.buyer_id].user.shop_history.seller_ID = pat_data.seller_id;
        user[pat_data.buyer_id].user.shop_history.item_ID = pat_data.item_id;
        user[pat_data.buyer_id].user.shop_history.item_num = pat_data.item_num;
        case(rand_pat.item_id)
            Large   :begin
                user[pat_data.buyer_id].shop.large_num = user[pat_data.buyer_id].shop.large_num + pat_data.item_num;
                user[pat_data.seller_id].shop.large_num = user[pat_data.seller_id].shop.large_num - pat_data.item_num;
                
            end
	        Medium  :begin
                user[pat_data.buyer_id].shop.medium_num = user[pat_data.buyer_id].shop.medium_num + pat_data.item_num;
                user[pat_data.seller_id].shop.medium_num = user[pat_data.seller_id].shop.medium_num - pat_data.item_num;
            end
	        Small   :begin
                user[pat_data.buyer_id].shop.small_num = user[pat_data.buyer_id].shop.small_num + pat_data.item_num;
                user[pat_data.seller_id].shop.small_num = user[pat_data.seller_id].shop.small_num - pat_data.item_num;
            end
        endcase

        case(user[pat_data.buyer_id].shop.level)
            Platinum:fee = 10;
            Gold:begin
                    fee = 30;
                    user[pat_data.buyer_id].shop.exp = (user[pat_data.buyer_id].shop.exp + (earn_exp * pat_data.item_num) >= 4000)?0:
                    user[pat_data.buyer_id].shop.exp + (earn_exp * pat_data.item_num);
            end
            Silver:begin
                    fee = 50;
                    user[pat_data.buyer_id].shop.exp = (user[pat_data.buyer_id].shop.exp + (earn_exp * pat_data.item_num) >= 2500)?0:
                    user[pat_data.buyer_id].shop.exp + (earn_exp * pat_data.item_num);
            end
            Copper:begin
                    fee = 70;
                    user[pat_data.buyer_id].shop.exp = (user[pat_data.buyer_id].shop.exp + (earn_exp * pat_data.item_num) >= 1000)?0:
                    user[pat_data.buyer_id].shop.exp + (earn_exp * pat_data.item_num);
            end
        endcase
        
        user[pat_data.buyer_id].shop.level = (user[pat_data.buyer_id].shop.exp == 0)?((user[pat_data.buyer_id].shop.level == 0)?0:
        user[pat_data.buyer_id].shop.level - 1): user[pat_data.buyer_id].shop.level;
        user[pat_data.buyer_id].user.money = user[pat_data.buyer_id].user.money - (pat_data.item_num * price) - fee;
        user[pat_data.seller_id].user.money = (user[pat_data.seller_id].user.money + (pat_data.item_num * price) >= 65535)?65535:
        user[pat_data.seller_id].user.money + (pat_data.item_num * price);
    endfunction

    function op_deposit();
        user[pat_data.buyer_id].user.money = user[pat_data.buyer_id].user.money + pat_data.deposit_money;
    endfunction

    function op_return();
        case(user[pat_data.buyer_id].user.shop_history.item_ID)
            Large   :begin
                user[pat_data.buyer_id].shop.large_num = user[pat_data.buyer_id].shop.large_num - user[pat_data.buyer_id].user.shop_history.item_num;
                user[pat_data.seller_id].shop.large_num = user[pat_data.seller_id].shop.large_num + user[pat_data.buyer_id].user.shop_history.item_num;
            end
	        Medium  :begin
                user[pat_data.buyer_id].shop.medium_num = user[pat_data.buyer_id].shop.medium_num - user[pat_data.buyer_id].user.shop_history.item_num;
                user[pat_data.seller_id].shop.medium_num = user[pat_data.seller_id].shop.medium_num + user[pat_data.buyer_id].user.shop_history.item_num;
            end
	        Small   :begin
                user[pat_data.buyer_id].shop.small_num = user[pat_data.buyer_id].shop.small_num - user[pat_data.buyer_id].user.shop_history.item_num;
                user[pat_data.seller_id].shop.small_num = user[pat_data.seller_id].shop.small_num + user[pat_data.buyer_id].user.shop_history.item_num;
            end
        endcase
        user[pat_data.buyer_id].user.money = user[pat_data.buyer_id].user.money + (user[pat_data.buyer_id].user.shop_history.item_num) * price;
        user[pat_data.seller_id].user.money = user[pat_data.seller_id].user.money - (user[pat_data.buyer_id].user.shop_history.item_num) * price;
    endfunction
//============process buyer,seller===========================================================================

endclass





