import usertype::*;



typedef struct packed {
	Error_Msg message;
	logic [31:0] out_info;
	logic complete;
} ANS;

typedef struct packed {
    User_id buyer_id;
    User_id seller_id;
} ID;

class DRAM;
    logic [7:0] data [67583:65536];//10000 to 107FC
    function read_file();
        $readmemh("../00_TESTBED/DRAM/dram.dat",data);
    endfunction

    function PERSON read_user(User_id USER);
        PERSON person;
        logic [16:0] addr;
        addr = {1'b1,5'b0,USER,3'b0};
        person.shop.large_num = data[addr][7:2];
        person.shop.small_num = {data[addr+1][3:0],data[addr+2][7:6]};
        person.shop.medium_num = {data[addr][1:0],data[addr+1][7:4]};
        person.shop.exp = {data[addr+2][3:0],data[addr+3][7:0]};
        person.shop.level = data[addr+2][5:4];
        person.user.money = {data[addr+4][7:0],data[addr+5][7:0]};
        person.user.shop_history.item_ID = data[addr+6][7:6];
        person.user.shop_history.item_num = data[addr+6][5:0];
        person.user.shop_history.seller_ID = data[addr+7][7:0];
        return person;
    endfunction

    function void write_data(User_id USER,PERSON person);
        logic [16:0] addr;
        addr = {1'b1,5'b0,USER,3'b0};
        data[addr][7:2] = person.shop.large_num;
        data[addr+2][7:6] = person.shop.small_num[1:0];
        data[addr+1][3:0]= person.shop.small_num[5:2];
        data[addr+1][7:4] = person.shop.medium_num[3:0];
        data[addr][1:0] = person.shop.medium_num[5:4];
        data[addr+3][7:0]= person.shop.exp[7:0];
        data[addr+2][3:0] = person.shop.exp[11:8];
        data[addr+2][5:4] = person.shop.level;
        data[addr+5][7:0] = person.user.money[7:0];
        data[addr+4][7:0] = person.user.money[15:8];
        data[addr+6][7:6] = person.user.shop_history.item_ID;
        data[addr+6][5:0] = person.user.shop_history.item_num;
        data[addr+7][7:0] = person.user.shop_history.seller_ID;
    endfunction
        
    
endclass


class RAND_DATA;
    rand User_id buyer_id;
    rand User_id seller_id;
    rand Action act;
    rand bit buyer_valid;
    rand bit seller_valid;
    rand Item_id item_id;
    rand Item_num item_num;
    rand Money deposit_money;
    rand bit Return_valid;
    constraint limit{
        buyer_id inside{[0:255]};
        seller_id inside{[0:255]};
        buyer_id != seller_id;
        act dist {Buy := 35, Check := 35, Deposit := 5, Return := 25};
        buyer_valid dist{0 :=60, 1 :=40};
        seller_valid dist{0 :=30, 1 :=70};
        item_id inside {Large,Medium,Small};
        item_num inside{[1:63]};
        deposit_money inside{[1:65535]};
        Return_valid dist {0 :=30, 1 :=70};
    }

    function new();
        this.srandom(0);
    endfunction
endclass


class VERIFICATION;
    logic seller_record [255:0];
    logic buyer_record [255:0];
    User_id recent_buyer [255:0];
    ID id;
    PERSON buyer,seller;
    DRAM dram;
    RAND_DATA randpat_data;
    ANS golden_ans;
    function new();
        integer i,j,k;
        dram = new();
        randpat_data = new();
        for(i = 0;i < 256;i = i + 1)
            recent_buyer[i] = 0;
        for(k = 0;k < 256;k = k + 1)
            buyer_record[k] = 0;
        for(j = 0;j < 256;j = j + 1)
            seller_record[j] = 0;
    endfunction

//===== DRAM ============================================    
    function void init_user();
        id.buyer_id = 0;
        id.seller_id = 1;
    endfunction

    function void read_buyer();
        if(randpat_data.buyer_id == id.seller_id)
            id.buyer_id = randpat_data.buyer_id+$urandom_range(1,255);
        else if(randpat_data.act == Return) 
            id.buyer_id = (randpat_data.Return_valid)?recent_buyer[buyer.user.shop_history.seller_ID]:randpat_data.buyer_id;
        else
            id.buyer_id = randpat_data.buyer_id;
        buyer = dram.read_user(id.buyer_id);
    endfunction

    function void read_seller();
        if(randpat_data.seller_id == id.buyer_id)
            id.seller_id = randpat_data.seller_id+$urandom_range(1,255);
        else if(randpat_data.act == Return)
            id.seller_id = (randpat_data.Return_valid)?buyer.user.shop_history.seller_ID:randpat_data.seller_id;
        else 
            id.seller_id = randpat_data.seller_id;
        seller = dram.read_user(id.seller_id);
    endfunction

    function void write_buyer();
        dram.write_data(id.buyer_id,buyer);
    endfunction
    
    function void write_seller();
        dram.write_data(id.seller_id,seller);
    endfunction
//===== DRAM ============================================

    
//=============process out_info==================================================================================
    function void cal_out_info();
        case(randpat_data.act)
            Buy:golden_ans.out_info = buyer.user;
            Check:golden_ans.out_info = (randpat_data.seller_valid)?{14'd0,seller.shop.large_num,seller.shop.medium_num,seller.shop.small_num}:{16'd0,buyer.user.money};
            Deposit:golden_ans.out_info = {16'd0,buyer.user.money};
            Return:golden_ans.out_info = {14'd0,buyer.shop.large_num,buyer.shop.medium_num,buyer.shop.small_num};
        endcase
    endfunction
//============process out_info ===================================================================================

//===========update trade history ====================================================================
     function void update_trade();
         case(randpat_data.act)
             Buy:buy_update();
             Check:check_update();
             Deposit:deposit_update();
             Return:return_update();
         endcase
     endfunction
     
     function void buy_update();
        seller_record[id.seller_id] = 1;
        seller_record[id.buyer_id] = 0;
        buyer_record[id.buyer_id] = 1;
        buyer_record[id.seller_id] = 0;
        recent_buyer[id.seller_id] = id.buyer_id;
    endfunction

    function void check_update();
        if(randpat_data.seller_valid) begin
            seller_record[id.seller_id] = 0;
            buyer_record[id.seller_id] = 0;
        end
        seller_record[id.buyer_id] = 0;
        buyer_record[id.buyer_id] = 0;
    endfunction

    function void deposit_update();
        buyer_record[id.buyer_id] = 0;
        seller_record[id.buyer_id] = 0;
    endfunction

    function void return_update();
        seller_record[id.seller_id] = 0;
        seller_record[id.buyer_id] = 0;
        buyer_record[id.buyer_id] = 0;
        buyer_record[id.seller_id] = 0;
    endfunction
//============updata trade history ====================================================================


//=============message check======================================================================================================
    function void buy_message();
        int unsigned price,fee;
        logic [5:0] buyer_stock,seller_stock;
        case(randpat_data.item_id)
            Large:  begin
                buyer_stock = buyer.shop.large_num;
                seller_stock = seller.shop.large_num;
                price = 300;
            end
            Medium: begin
                buyer_stock = buyer.shop.medium_num;
                seller_stock = seller.shop.medium_num;
                price = 200;
            end
            Small: begin
                buyer_stock = buyer.shop.small_num;
                seller_stock = seller.shop.small_num;
                price = 100;
            end
        endcase

        case(buyer.shop.level)
            Platinum:fee = 10;
            Gold:fee = 30;
            Silver:fee = 50;
            Copper:fee = 70; 
        endcase

        if(buyer_stock + randpat_data.item_num > 63) golden_ans.message = INV_Full;
        else if(seller_stock < randpat_data.item_num) golden_ans.message = INV_Not_Enough;
        else if(buyer.user.money < (price * randpat_data.item_num) + fee) golden_ans.message = Out_of_money;
        else golden_ans.message = No_Err;
    endfunction

    function void deposit_message();
        if(randpat_data.deposit_money + buyer.user.money > 65535) golden_ans.message = Wallet_is_Full;
        else golden_ans.message = No_Err;
    endfunction

    function void return_message();
    if(seller_record[buyer.user.shop_history.seller_ID] == 0 || buyer_record[id.buyer_id] == 0 
        || recent_buyer[buyer.user.shop_history.seller_ID] != id.buyer_id) golden_ans.message = Wrong_act;
        else if(buyer.user.shop_history.seller_ID != id.seller_id) golden_ans.message = Wrong_ID;
        else if(randpat_data.item_num != buyer.user.shop_history.item_num) golden_ans.message = Wrong_Num;
        else if(randpat_data.item_id != buyer.user.shop_history.item_ID) golden_ans.message = Wrong_Item;
        else golden_ans.message = No_Err;
    endfunction

    function void message_check();
        case(randpat_data.act) 
            Buy:buy_message();
            Check:golden_ans.message = No_Err;
            Deposit:deposit_message();
            Return:return_message();     
        endcase
        golden_ans.complete = (golden_ans.message == 0)?1:0;
    endfunction
//=============message check======================================================================================================

//============process buyer,seller==========================================================================
    function void do_operation();
        case(randpat_data.act)
            Buy:op_buy();
            Deposit:op_deposit();
            Return:op_return();
        endcase
    endfunction

    function op_buy();
        int unsigned fee,price,earn_exp;
        buyer.user.shop_history.seller_ID = id.seller_id;
        buyer.user.shop_history.item_ID = randpat_data.item_id;
        buyer.user.shop_history.item_num = randpat_data.item_num;
        case(randpat_data.item_id)
            Large   :begin
                buyer.shop.large_num = buyer.shop.large_num + randpat_data.item_num;
                seller.shop.large_num = seller.shop.large_num - randpat_data.item_num;
                price = 300;
                earn_exp = 60;
            end
	        Medium  :begin
                buyer.shop.medium_num = buyer.shop.medium_num + randpat_data.item_num;
                seller.shop.medium_num = seller.shop.medium_num - randpat_data.item_num;
                price = 200;
                earn_exp = 40;
            end
	        Small   :begin
                buyer.shop.small_num = buyer.shop.small_num + randpat_data.item_num;
                seller.shop.small_num = seller.shop.small_num - randpat_data.item_num;
                price = 100;
                earn_exp = 20;
            end
        endcase

        case(buyer.shop.level)
            Platinum:fee = 10;
            Gold:begin
                    fee = 30;
                    buyer.shop.exp = (buyer.shop.exp + (earn_exp * randpat_data.item_num) >= 4000)?0:buyer.shop.exp + (earn_exp * randpat_data.item_num);
            end
            Silver:begin
                    fee = 50;
                    buyer.shop.exp = (buyer.shop.exp + (earn_exp * randpat_data.item_num) >= 2500)?0:buyer.shop.exp + (earn_exp * randpat_data.item_num);
            end
            Copper:begin
                    fee = 70;
                    buyer.shop.exp = (buyer.shop.exp + (earn_exp * randpat_data.item_num) >= 1000)?0:buyer.shop.exp + (earn_exp * randpat_data.item_num);
            end
        endcase
        
        buyer.shop.level = (buyer.shop.exp == 0)?((buyer.shop.level == 0)?0:buyer.shop.level - 1): buyer.shop.level;
        buyer.user.money = buyer.user.money - (randpat_data.item_num * price) - fee;
        seller.user.money = (seller.user.money + (randpat_data.item_num * price) >= 65535)?65535:seller.user.money + (randpat_data.item_num * price);
    endfunction

    function op_deposit();
        buyer.user.money = buyer.user.money + randpat_data.deposit_money;
    endfunction

    function op_return();
        int unsigned price;
        case(buyer.user.shop_history.item_ID)
            Large   :begin
                buyer.shop.large_num = buyer.shop.large_num - buyer.user.shop_history.item_num;
                seller.shop.large_num = seller.shop.large_num + buyer.user.shop_history.item_num;
                price = 300;
            end
	        Medium  :begin
                buyer.shop.medium_num = buyer.shop.medium_num - buyer.user.shop_history.item_num;
                seller.shop.medium_num = seller.shop.medium_num + buyer.user.shop_history.item_num;
                price = 200;
            end
	        Small   :begin
                buyer.shop.small_num = buyer.shop.small_num - buyer.user.shop_history.item_num;
                seller.shop.small_num = seller.shop.small_num + buyer.user.shop_history.item_num;
                price = 100;
            end
        endcase
        buyer.user.money = buyer.user.money + (buyer.user.shop_history.item_num) * price;
        seller.user.money = seller.user.money - (buyer.user.shop_history.item_num) * price;
    endfunction
//============process buyer,seller===========================================================================

endclass





