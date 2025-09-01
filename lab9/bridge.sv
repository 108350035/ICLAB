module bridge(input clk, INF.bridge_inf inf);


logic [63:0] shop_user;
logic [11:0] address;
STATE_BR cs,ns;
assign inf.AR_ADDR = (cs == S_READ_READY)?{5'h10,address}:0;
assign inf.AW_ADDR = (cs == S_WRITE_READY)?{5'h10,address}:0;
assign inf.R_READY = (cs == S_READ)?1:0;
assign inf.W_DATA = (cs == S_WRITE)?shop_user:0;
assign inf.W_VALID = (cs == S_WRITE)?1:0;
assign inf.AR_VALID = (cs == S_READ_READY)?1:0;
assign inf.AW_VALID = (cs == S_WRITE_READY)?1:0; 
assign inf.B_READY = (cs == S_RESPONSE)?1:0;

always_comb
begin
    case(cs)
        S_IDLE:ns=(inf.C_in_valid)?((inf.C_r_wb)?S_READ_READY:S_WRITE_READY):S_IDLE;
        S_READ_READY:ns=(inf.AR_READY)?S_READ:S_READ_READY;
        S_READ:ns=(inf.R_VALID)?S_READ_OUT:S_READ;
        S_READ_OUT:ns=S_IDLE;
        S_WRITE_READY:ns=(inf.AW_READY)?S_WRITE:S_WRITE_READY;
        S_WRITE:ns=(inf.W_READY)?S_RESPONSE:S_WRITE;
        S_RESPONSE:ns=(inf.B_VALID)?S_WRITE_OUT:S_RESPONSE;
        S_WRITE_OUT:ns=S_IDLE;
        default:ns=S_IDLE;
    endcase
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) cs<=S_IDLE;
    else cs<=ns;
end


always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) address<=0;
    else if(inf.C_in_valid) address<={inf.C_addr,3'b0};
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) shop_user<=0;
    else if(inf.R_VALID) shop_user<=inf.R_DATA;
    else if(inf.C_in_valid & inf.C_r_wb == 0) shop_user<=inf.C_data_w;
end

always_ff@(posedge clk,negedge inf.rst_n)
begin
    if(!inf.rst_n) begin
        inf.C_out_valid<=0;
        inf.C_data_r<=0;
    end
    else if(cs == S_READ_OUT) begin
        inf.C_out_valid<=1;
        inf.C_data_r<=shop_user;
    end
    else if(cs == S_WRITE_OUT) inf.C_out_valid<=1;
    else begin
        inf.C_out_valid<=0;
        inf.C_data_r<=0;
    end
end


endmodule


