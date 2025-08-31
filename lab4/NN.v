//synopsys translate_off
`include "DW_fp_add.v"
`include "DW_fp_sub.v"
`include "DW_fp_mult.v"
//synopsys translate_on
module NN(
	// Input signals
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
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
// state name and intrger
parameter [1:0] idle=2'd0,for_and_back=2'd1,update=2'd2;
integer i;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_d, in_valid_t, in_valid_w1, in_valid_w2;
input [inst_sig_width+inst_exp_width:0] data_point, target;
input [inst_sig_width+inst_exp_width:0] weight1, weight2;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
localparam [2:0] W_Receive=3'd0,F_1=3'd1,F_2=3'd2,B_2=3'd3,B_1=3'd4,U_2=3'd5,U_1=3'd6;
parameter ONE = 32'h3F800000,learn=32'h358637BD;
reg [inst_sig_width+inst_exp_width:0] w1 [11:0],w2 [2:0],target_temp,data [3:0];
reg [8:0] iter;
reg [2:0] cs,ns,valid;
reg o_valid;
reg [inst_sig_width+inst_exp_width:0] mul0_a,mul0_b,mul1_a,mul1_b,mul2_a,mul2_b;
reg [inst_sig_width+inst_exp_width:0] add0_a,add0_b,add1_a,add1_b,add2_a,add2_b,mul6_a,mul6_b;
wire [inst_sig_width+inst_exp_width:0] mul0_out,mul1_out,mul2_out,mul3_out,mul4_out,mul5_out,mul6_out,mul3_a,mul4_a,mul5_a,mul345_b;
reg [inst_sig_width+inst_exp_width:0] y10,y11,y12,y20,sigma10,sigma11,sigma12,temp0,temp1,temp2,temp3,temp4,temp5;
wire [inst_sig_width+inst_exp_width:0] add0_out,add1_out,add2_out,ReLU0,dReLU0,ReLU1,dReLU1,sub0_out;
wire [inst_sig_width+inst_exp_width:0] new_rate,sub0_a,sub0_b;
reg [inst_sig_width+inst_exp_width:0] learning_rate;
//---------------------------------------------------------------------
//   DesignWare
//---------------------------------------------------------------------
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M0(.a(mul0_a),.b(mul0_b),.rnd(3'b0),.z(mul0_out));
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M1(.a(mul1_a),.b(mul1_b),.rnd(3'b0),.z(mul1_out));
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M2(.a(mul2_a),.b(mul2_b),.rnd(3'b0),.z(mul2_out));
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M3(.a(mul3_a),.b(mul345_b),.rnd(3'b0),.z(mul3_out));
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M4(.a(mul4_a),.b(mul345_b),.rnd(3'b0),.z(mul4_out));
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M5(.a(mul5_a),.b(mul345_b),.rnd(3'b0),.z(mul5_out));
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M6(.a(mul6_a),.b(mul6_b),.rnd(3'b0),.z(mul6_out));
DW_fp_mult#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  M7(.a(learning_rate),.b(32'h3F000000),.rnd(3'b0),.z(new_rate));

DW_fp_add#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  A0(.a(add0_a),.b(add0_b),.rnd(3'b0),.z(add0_out));
DW_fp_add#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  A1(.a(add1_a),.b(add1_b),.rnd(3'b0),.z(add1_out));
DW_fp_add#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  A2(.a(add2_a),.b(add2_b),.rnd(3'b0),.z(add2_out));
DW_fp_sub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)  S0(.a(sub0_a),.b(sub0_b),.rnd(3'b0),.z(sub0_out));



assign ReLU0 = (y10[31])?0:y10;
assign dReLU0 = (ReLU0==0)?0:ONE;
assign ReLU1 = (y11[31])?0:y11;
assign dReLU1 = (ReLU1==0)?0:ONE;

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) o_valid<=0;
    else if(cs == U_2) o_valid<=1;
    else o_valid<=0;
end

always@(posedge clk,negedge rst_n) 
begin
    if(!rst_n) cs<=W_Receive;
    else cs<=ns;
end

always@(posedge clk)
begin
    if(cs == F_1) begin
        valid[0]<=in_valid_d;
        valid[1]<=valid[0];
        valid[2]<=valid[1];
    end
    else begin
        valid[0]<=valid[1];
        valid[1]<=valid[2];
        valid[2]<=valid[0];
    end

end

always@(*)
begin
    case(cs)
        W_Receive:ns=(in_valid_d)?F_1:W_Receive;
        F_1:ns=(in_valid_d)?F_1:F_2;
        F_2:ns=(valid[1])?F_2:B_2;
        B_2:ns=B_1;
        B_1:ns=U_2;
        U_2:ns=U_1;
        U_1:ns=(in_valid_w1)?W_Receive:((in_valid_d)?F_1:U_1);
        default:ns=F_1;
    endcase
end

always@(posedge clk,negedge rst_n) 
begin
    if(!rst_n) begin
        y10<=0;
        y11<=0;
        y12<=0;
    end
    else if(cs== F_1) begin
        y10<=add0_out;
        y11<=add1_out;
        y12<=add2_out;
    end
    else if(cs == F_2) begin
        y11<=mul2_out;
        y12<=y11;
        y10<=y12;
    end
    else if(cs == B_1) begin
        y10<=mul0_out;
        y11<=mul1_out;
        y12<=mul2_out;
    end
    else if(o_valid) begin
        y10<=0;
        y11<=0;
        y12<=0;
    end
end

always@(posedge clk) 
begin
    if(in_valid_d)  begin
        temp0<=mul0_out;
        temp1<=mul1_out;
        temp2<=mul2_out;
    end
    else if(cs == F_2) begin
        temp0<=mul6_out;
    end
    else if(cs[2]) begin
        temp0<=mul2_out;
        temp1<=mul3_out;
        temp2<=mul4_out;
    end
end

always@(posedge clk,negedge rst_n) 
begin
    if(!rst_n) y20<=0;
    else if(cs == F_2) y20<=(valid[0])?add0_out:mul0_out;
    else if(in_valid_t) y20<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        sigma10<=0;
        sigma11<=0;
        sigma12<=0;
    end
    else if(cs == B_1 | in_valid_t) begin
        sigma12<=mul5_out;
        sigma11<=mul4_out;
        sigma10<=mul3_out;
    end
    else if(cs == F_2) begin
        sigma12<=sigma11;
        sigma11<=mul1_out;
        sigma10<=sigma12;
    end
    else if(cs[2]) begin
        sigma11<=sigma12;
        sigma10<=sigma11;
    end
end

always@(posedge clk,negedge rst_n) 
begin
    if(!rst_n) target_temp<=0;
    else if(in_valid_t) target_temp<=target;
    else if(cs == B_2) target_temp<=sub0_out;
end


always@(posedge clk,negedge rst_n) 
begin
    if(!rst_n) begin
        for(i=0;i<3;i=i+1)
            w2[i]<=0;
    end
    else if(in_valid_w2) begin
        w2[2]<=weight2;
        w2[1]<=w2[2];
        w2[0]<=w2[1];
    end
    else if(cs == U_2) begin
        w2[0]<=add0_out;
        w2[1]<=add1_out;
        w2[2]<=add2_out;
    end
end


always@(*)
begin
    if(in_valid_d) begin
        mul0_a = data_point;
        mul0_b = w1[0];
    end
    else if(valid[0] == 0) begin
        mul0_a = w2[0];
        mul0_b = ReLU0;
    end
    else begin
        mul0_a = y10;
        mul0_b = target_temp;
    end
end
assign sub0_a = (cs[1:0] ==3)?y20:w1[0];
assign sub0_b = (cs[1:0] ==3)?target_temp:temp0;

always@(*)
begin
    case(cs)
        U_1:begin
            add0_a = w1[1];
            add0_b = {~temp1[31],temp1[30:0]};
        end
        F_2:begin
            add0_a = y20;
            add0_b = temp0;
        end
        U_2:begin
            add0_a = w2[0];
            add0_b = {~y10[31],y10[30:0]};
        end
        default:begin
            add0_a = y10;
            add0_b = temp0;
        end
    endcase
end


always@(*)
begin
    case(cs)
        U_1:begin
            add1_a = w1[2];
            add1_b = {~temp2[31],temp2[30:0]};
        end
        U_2:begin
            add1_a = w2[1];
            add1_b = {~y11[31],y11[30:0]};
        end
        default:begin
            add1_a = y11;
            add1_b = temp1;
        end
    endcase
end

always@(*)
begin
    if(cs == U_1) begin
            add2_a = w1[3];
            add2_b = {~temp3[31],temp3[30:0]};
    end
    else if(cs == U_2) begin
            add2_a = w2[2];
            add2_b = {~y12[31],y12[30:0]};
    end
    else begin
            add2_a = y12;
            add2_b = temp2;
    end
end


always@(*)
begin
    if(in_valid_d) begin
        mul1_a = data_point;
        mul1_b = w1[4];
    end
    else if(cs == F_2) begin
        mul1_a = sigma10;
        mul1_b = dReLU0;
    end
    else if(cs == B_1) begin
        mul1_a = y11;
        mul1_b = target_temp;
    end
    else begin
        mul1_a = y11;
        mul1_b = learning_rate;
    end
end

always@(*)
begin
    if(in_valid_d) begin
        mul2_a = data_point;
        mul2_b = w1[8];
    end
    else if(cs == B_1) begin
        mul2_a = y12;
        mul2_b = target_temp;
    end
    else if(cs == F_2) begin
        mul2_a = ReLU0;
        mul2_b = learning_rate;
    end
    else begin
        mul2_a = sigma10;
        mul2_b = data[0];
    end
end
always@(posedge clk)
begin
    temp3<=mul5_out;
end

assign mul3_a = (in_valid_t)?w2[0]:((cs==B_1)?sigma10:data[1]);
assign mul4_a = (in_valid_t)?w2[1]:((cs==B_1)?sigma11:data[2]);
assign mul5_a = (in_valid_t)?w2[2]:((cs==B_1)?sigma12:data[3]);
assign mul345_b =(in_valid_t)?learning_rate:((cs==B_1)?target_temp:sigma10);

always@(*)
begin
    if(valid[0]) begin
        mul6_a = w2[2];
        mul6_b = ReLU0;
    end
    else begin
        mul6_a = w2[1];
        mul6_b = ReLU1;
    end
end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        for(i=0;i<12;i=i+1)
            w1[i]<=0;
    end
    else if(in_valid_w1) begin
        w1[11]<=weight1;
        w1[10]<=w1[11];
        w1[9]<=w1[10];
        w1[8]<=w1[9];
        w1[7]<=w1[8];
        w1[6]<=w1[7];
        w1[5]<=w1[6];
        w1[4]<=w1[5];
        w1[3]<=w1[4];
        w1[2]<=w1[3];
        w1[1]<=w1[2];
        w1[0]<=w1[1];
    end
    else if(in_valid_d) begin
        w1[3]<=w1[0];
        w1[2]<=w1[3];
        w1[1]<=w1[2];
        w1[0]<=w1[1];
        w1[4]<=w1[5];
        w1[5]<=w1[6];
        w1[6]<=w1[7];
        w1[7]<=w1[4];
        w1[8]<=w1[9];
        w1[9]<=w1[10];
        w1[10]<=w1[11];
        w1[11]<=w1[8];
    end
    else if(cs == U_1) begin
        w1[3]<=w1[7];
        w1[2]<=w1[6];
        w1[1]<=w1[5];
        w1[0]<=w1[4];
        w1[4]<=w1[8];
        w1[5]<=w1[9];
        w1[6]<=w1[10];
        w1[7]<=w1[11];
        w1[8]<=sub0_out;
        w1[9]<=add0_out;
        w1[10]<=add1_out;
        w1[11]<=add2_out;
    end
end

always@(posedge clk,negedge rst_n) 
begin
    if(!rst_n) begin
        for(i=0;i<4;i=i+1)
            data[i]<=0;
    end
    else if(in_valid_d) begin
        data[3]<=data_point;
        data[2]<=data[3];
        data[1]<=data[2];
        data[0]<=data[1];
    end
end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) out<=0;
    else if(o_valid) out<=y20;
    else out<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) out_valid<=0;
    else if(o_valid) out_valid<=1;
    else out_valid<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) iter<=0;
    else if(iter == 400 | in_valid_w2) iter<=0;
    else if(o_valid) iter<=iter+1;
end

always@(posedge clk)
begin
    if(in_valid_w2) learning_rate<=learn;
    else if(iter == 400)learning_rate<=new_rate;
end


endmodule
