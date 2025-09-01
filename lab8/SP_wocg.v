module SP(
	// Input signals
	clk,
	rst_n,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid;
input [2:0] in_mode;
input [8:0] in_data;
output reg out_valid;
output reg [8:0] out_data; 

//======================
// PARAMETER DECLARATION
//======================
parameter [2:0] IDLE=3'd0,INPUT=3'd1,STEP_1=3'd2,STEP_2=3'd3,STEP_3=3'd4,STEP_4=3'd5,OUT=3'd6;
reg [5:0] cnt_STEP1;
reg [4:0] cnt_STEP2;
reg [2:0] cnt_out,cnt_STEP4;
reg [2:0] cs,ns;
reg [8:0] a [5:0],d [5:0],b_temp [5:0],e_temp [5:0];
reg [10:0] e [5:0];
reg [17:0] b [5:0],c [5:0], B[5:0];
reg [2:0] mode;
wire [17:0] AB_0,BB_0,AB_1,BB_1,AB_2,BB_2,AB_3,BB_3,AB_4,BB_4,AB_5,BB_5,C0,C1,C2,C3,C4,C5;
wire [12:0] B0_mod,b0_mod,B1_mod,b1_mod,B2_mod,b2_mod,B3_mod,b3_mod,B4_mod,b4_mod,B5_mod,b5_mod;
wire [12:0] C0_mod,C1_mod,C2_mod,C3_mod,C4_mod,C5_mod;
wire [9:0]  C0_sub,C1_sub,C2_sub,C3_sub,C4_sub,C5_sub;
wire [9:0] b0_sub,b1_sub,b2_sub,b3_sub,b4_sub,b5_sub;
wire [12:0] E0_ACC,E1_ACC,E2_ACC,E3_ACC,E4_ACC,E5_ACC;
wire [12:0] E0_mod,E1_mod,E2_mod,E3_mod,E4_mod,E5_mod;
wire [10:0] E0_sub,E1_sub,E2_sub,E3_sub,E4_sub,E5_sub;
reg sort,start,start_buf,have_received_sort_data;
wire sort_done;
reg [8:0] d_sort;


bubble_sort B0(.clk(clk) ,.rst_n(rst_n) ,.start(sort) 
              ,.data0(c[0][8:0]) ,.data1(c[1][8:0]) ,.data2(c[2][8:0]) 
              ,.data3(c[3][8:0]) ,.data4(c[4][8:0]) ,.data5(c[5][8:0])
              ,.out_valid(sort_done) ,.out(d_sort) ,.done(have_received_sort_data));

assign AB_0 = b[0][8:0] * B[0][8:0];
assign BB_0 = B[0][8:0] * B[0][8:0];
assign B0_mod = B[0][17:9] * 3 + B[0][8:0];
assign b0_mod = b[0][17:9] * 3 + b[0][8:0];
assign b0_sub = (b[0] >= 9'd509)? b[0] - 509: b[0];;
assign AB_1 = b[1][8:0] * B[1][8:0];
assign BB_1 = B[1][8:0] * B[1][8:0];
assign B1_mod = B[1][17:9] * 3 + B[1][8:0];
assign b1_mod = b[1][17:9] * 3 + b[1][8:0];
assign b1_sub = (b[1] >= 9'd509)? b[1] - 509: b[1];
assign AB_2 = b[2][8:0] * B[2][8:0];
assign BB_2 = B[2][8:0] * B[2][8:0];
assign B2_mod = B[2][17:9] * 3 + B[2][8:0];
assign b2_mod = b[2][17:9] * 3 + b[2][8:0];
assign b2_sub = (b[2] >= 9'd509)? b[2] - 509: b[2];;
assign AB_3 = b[3][8:0] * B[3][8:0];
assign BB_3 = B[3][8:0] * B[3][8:0];
assign B3_mod = B[3][17:9] * 3 + B[3][8:0];
assign b3_mod = b[3][17:9] * 3 + b[3][8:0];
assign b3_sub = (b[3] >= 9'd509)? b[3] - 509: b[3];;
assign AB_4 = b[4][8:0] * B[4][8:0];
assign BB_4 = B[4][8:0] * B[4][8:0];
assign B4_mod = B[4][17:9] * 3 + B[4][8:0];
assign b4_mod = b[4][17:9] * 3 + b[4][8:0];
assign b4_sub = (b[4] >= 9'd509)? b[4] - 509: b[4];;
assign AB_5 = b[5][8:0] * B[5][8:0];
assign BB_5 = B[5][8:0] * B[5][8:0];
assign B5_mod = B[5][17:9] * 3 + B[5][8:0];
assign b5_mod = b[5][17:9] * 3 + b[5][8:0];
assign b5_sub = (b[5] >= 9'd509)? b[5] - 509: b[5];;

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) mode<=0;
    else if(cs == IDLE && in_valid) mode<=in_mode;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        a[5]<=0;
        a[4]<=0;
        a[3]<=0;
        a[2]<=0;
        a[1]<=0;
        a[0]<=0;
    end
    else if(in_valid) begin
        a[5]<=in_data;
        a[4]<=a[5];
        a[3]<=a[4];
        a[2]<=a[3];
        a[1]<=a[2];
        a[0]<=a[1];
    end
end

always@(posedge clk)
begin
     if(mode[0] == 0 & in_valid == 0) begin
        b[5]<=a[5];
        b[4]<=a[4];
        b[3]<=a[3];
        b[2]<=a[2];
        b[1]<=a[1];
        b[0]<=a[0];
    end
    else begin
        case(cnt_STEP1)
            1:begin
                b[5]<=a[5];
                b[4]<=a[4];
                b[3]<=a[3];
                b[2]<=a[2];
                b[1]<=a[1];
                b[0]<=a[0];
            end

            6,14,18,22,26,30,34:begin
                b[0]<=AB_0;
                b[1]<=AB_1;
                b[2]<=AB_2;
                b[3]<=AB_3;
                b[4]<=AB_4;
                b[5]<=AB_5;
            end

            7,8,15,16,19,20,23,24,27,28,31,32,35,36:begin
                b[0]<=b0_mod;
                b[1]<=b1_mod;
                b[2]<=b2_mod;
                b[3]<=b3_mod;
                b[4]<=b4_mod;
                b[5]<=b5_mod;
            end

            9,17,21,25,29,33,37:begin
                b[0]<=b0_sub;
                b[1]<=b1_sub;
                b[2]<=b2_sub;
                b[3]<=b3_sub;
                b[4]<=b4_sub;
                b[5]<=b5_sub;
            end
        endcase
    end
end

always@(posedge clk)
begin
    if(mode[0] & in_valid == 0) begin 
        case(cnt_STEP1)
            1:begin
                B[5]<={9'b0,a[5]};
                B[4]<={9'b0,a[4]};
                B[3]<={9'b0,a[3]};
                B[2]<={9'b0,a[2]};
                B[1]<={9'b0,a[1]};
                B[0]<={9'b0,a[0]};
            end

            2,6,10,14,18,22,26,30:begin
                B[5]<=BB_5;
                B[4]<=BB_4;
                B[3]<=BB_3;
                B[2]<=BB_2;
                B[1]<=BB_1;
                B[0]<=BB_0;
            end
            3,4,5,7,8,9,11,12,13,15,16,17,19,20,21,23,24,25,27,28,29,31,32:begin
                B[5]<=B5_mod;
                B[4]<=B4_mod;
                B[3]<=B3_mod;
                B[2]<=B2_mod;
                B[1]<=B1_mod;
                B[0]<=B0_mod;
            end
        endcase
    end
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cnt_STEP1<=0;
    else if(cs == STEP_1 & mode[0]) cnt_STEP1<=(cnt_STEP1 == 37)?0:cnt_STEP1+1;
    else cnt_STEP1<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cnt_STEP2<=0;
    else if(cs == STEP_2 & mode[1]) cnt_STEP2<=(cnt_STEP2 == 17)?0:cnt_STEP2+1;
    else cnt_STEP2<=0;
end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cnt_STEP4<=0;
    else if(cs == STEP_4) cnt_STEP4<=(cnt_STEP4 == 6)?0:cnt_STEP4+1;
    else cnt_STEP4<=0;
end

assign C0 = c[0] * b_temp[0];
assign C0_mod = c[0][17:9] * 3 + c[0][8:0];
assign C0_sub = (c[0] >= 9'd509)? c[0] - 509: c[0];
assign C1 = c[1] * b_temp[1];
assign C1_mod = c[1][17:9] * 3 + c[1][8:0];
assign C1_sub = (c[1] >= 9'd509)? c[1] - 509: c[1];
assign C2 = c[2] * b_temp[2];
assign C2_mod = c[2][17:9] * 3 + c[2][8:0];
assign C2_sub = (c[2] >= 9'd509)? c[2] - 509: c[2];
assign C3 = c[3] * b_temp[3];
assign C3_mod = c[3][17:9] * 3 + c[3][8:0];
assign C3_sub = (c[3] >= 9'd509)? c[3] - 509: c[3];
assign C4 = c[4] * b_temp[4];
assign C4_mod = c[4][17:9] * 3 + c[4][8:0];
assign C4_sub = (c[4] >= 9'd509)? c[4] - 509: c[4];
assign C5 = c[5] * b_temp[5];
assign C5_mod = c[5][17:9] * 3 + c[5][8:0];
assign C5_sub = (c[5] >= 9'd509)? c[5] - 509: c[5];

always@(posedge clk)
begin
        case(cnt_STEP2) 
            1:begin
            b_temp[5]<=b[1];
            b_temp[4]<=b[0];
            b_temp[3]<=b[5];
            b_temp[2]<=b[4];
            b_temp[1]<=b[3];
            b_temp[0]<=b[2];
            end

            5,9,13:begin
            b_temp[5]<=b_temp[0];
            b_temp[4]<=b_temp[5];
            b_temp[3]<=b_temp[4];
            b_temp[2]<=b_temp[3];
            b_temp[1]<=b_temp[2];
            b_temp[0]<=b_temp[1];
            end

        endcase

end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        c[5]<=0;
        c[4]<=0;
        c[3]<=0;
        c[2]<=0;
        c[1]<=0;
        c[0]<=0;
    end
    else if(mode[1] == 0) begin
        c[5]<=b[5];
        c[4]<=b[4];
        c[3]<=b[3];
        c[2]<=b[2];
        c[1]<=b[1];
        c[0]<=b[0];
    end
    else begin
        case(cnt_STEP2)
            1:begin
                c[5]<=b[0];
                c[4]<=b[5];
                c[3]<=b[4];
                c[2]<=b[3];
                c[1]<=b[2];
                c[0]<=b[1];
            end

            2,6,10,14:begin
                c[5]<=C5;
                c[4]<=C4;
                c[3]<=C3;
                c[2]<=C2;
                c[1]<=C1;
                c[0]<=C0;
            end

            3,4,7,8,11,12,15,16:begin
                c[5]<=C5_mod;
                c[4]<=C4_mod;
                c[3]<=C3_mod;
                c[2]<=C2_mod;
                c[1]<=C1_mod;
                c[0]<=C0_mod;
            end

            5,9,13,17:begin
                c[5]<=C5_sub;
                c[4]<=C4_sub;
                c[3]<=C3_sub;
                c[2]<=C2_sub;
                c[1]<=C1_sub;
                c[0]<=C0_sub;
            end

        endcase
    end
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) start<=0;
    else if(cs == STEP_2 && ns == STEP_3 && mode[2]) start<=1;
    else if(ns == STEP_3) start<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) start_buf<=0;
    else start_buf<=start;
end



always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) sort<=0;
    else if(mode[2]) sort<=start_buf;//include start,start_buf in order to delay 2 cycle,avoid timing violation and logic error
end

always@(posedge clk)
begin
    if(cs == IDLE) cnt_out<=0;
    else if(cs == OUT) cnt_out<=cnt_out+1;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
            d[0]<=0;
            d[1]<=0;
            d[2]<=0;
            d[3]<=0;
            d[4]<=0;
            d[5]<=0;
    end
    else if(mode[2] == 0) begin
        d[5]<=c[5];
        d[4]<=c[4];
        d[3]<=c[3];
        d[2]<=c[2];
        d[1]<=c[1];
        d[0]<=c[0];
    end
    else if(sort_done) begin
        d[5]<=d[4];
        d[4]<=d[3];
        d[3]<=d[2];
        d[2]<=d[1];
        d[1]<=d[0];
        d[0]<=d_sort;
    end
end

assign E0_ACC = e[0] + e_temp[0];
assign E0_mod = e[0][10:9] * 3 + e[0][8:0];
assign E0_sub = (e[0] >= 9'd509)? e[0] - 509: e[0];
assign E1_ACC = e[1] + e_temp[1];
assign E1_mod = e[1][10:9] * 3 + e[1][8:0];
assign E1_sub = (e[1] >= 9'd509)? e[1] - 509: e[1];
assign E2_ACC = e[2] + e_temp[2];
assign E2_mod = e[2][10:9] * 3 + e[2][8:0];
assign E2_sub = (e[2] >= 9'd509)? e[2] - 509: e[2];
assign E3_ACC = e[3] + e_temp[3];
assign E3_mod = e[3][10:9] * 3 + e[3][8:0];
assign E3_sub = (e[3] >= 9'd509)? e[3] - 509: e[3];
assign E4_ACC = e[4] + e_temp[4];
assign E4_mod = e[4][10:9] * 3 + e[4][8:0];
assign E4_sub = (e[4] >= 9'd509)? e[4] - 509: e[4];
assign E5_ACC = e[5] + e_temp[5];
assign E5_mod = e[5][10:9] * 3 + e[5][8:0];
assign E5_sub = (e[5] >= 9'd509)? e[5] - 509: e[5];


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
            e_temp[0]<=0;
            e_temp[1]<=0;
            e_temp[2]<=0;
            e_temp[3]<=0;
            e_temp[4]<=0;
            e_temp[5]<=0;
    end
    else begin
        case(cnt_STEP4)
            1:begin
                e_temp[0]<=b[0];
                e_temp[1]<=b[1];
                e_temp[2]<=b[2];
                e_temp[3]<=b[3];
                e_temp[4]<=b[4];
                e_temp[5]<=b[5];
            end
            2:begin
                e_temp[0]<=d[0];
                e_temp[1]<=d[1];
                e_temp[2]<=d[2];
                e_temp[3]<=d[3];
                e_temp[4]<=d[4];
                e_temp[5]<=d[5];
            end

            3:begin
                e_temp[0]<=c[0];
                e_temp[1]<=c[1];
                e_temp[2]<=c[2];
                e_temp[3]<=c[3];
                e_temp[4]<=c[4];
                e_temp[5]<=c[5];
            end
        endcase
    end
end

always@(posedge clk)
begin
        case(cnt_STEP4)
            1:begin
                e[5]<=a[5];
                e[4]<=a[4];
                e[3]<=a[3];
                e[2]<=a[2];
                e[1]<=a[1];
                e[0]<=a[0];
            end

            2,3,4:begin
                e[0]<=E0_ACC;
                e[1]<=E1_ACC;
                e[2]<=E2_ACC;
                e[3]<=E3_ACC;
                e[4]<=E4_ACC;
                e[5]<=E5_ACC;
            end

            5:begin
                e[0]<=E0_mod;
                e[1]<=E1_mod;
                e[2]<=E2_mod;
                e[3]<=E3_mod;
                e[4]<=E4_mod;
                e[5]<=E5_mod;
            end

            6:begin
                e[0]<=E0_sub;
                e[1]<=E1_sub;
                e[2]<=E2_sub;
                e[3]<=E3_sub;
                e[4]<=E4_sub;
                e[5]<=E5_sub;
            end

        endcase

end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cs<=IDLE;
    else cs<=ns;
end

always@(*)
begin
    case(cs)
        IDLE:ns=(in_valid)?INPUT:IDLE;
        INPUT:ns=(in_valid)?INPUT:STEP_1;
        STEP_1:ns=(cnt_STEP1 == 37 | mode[0] == 0)?STEP_2:STEP_1;
        STEP_2:ns=(cnt_STEP2 == 17 | mode[1] == 0)?STEP_3:STEP_2;
        STEP_3:ns=(mode[2] == 0 | have_received_sort_data)?STEP_4:STEP_3;
        STEP_4:ns=(cnt_STEP4 == 6)?OUT:STEP_4;
        OUT:ns=(cnt_out == 5)?IDLE:OUT;
        default:ns=IDLE;
    endcase
end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        out_valid<=0;
        out_data<=0;
    end
    else if(cs == OUT) begin
        out_valid<=1;
        out_data<=e[cnt_out][8:0];
    end
    else begin
        out_data<=0;
        out_valid<=0;
    end

end


endmodule


module bubble_sort(clk,rst_n,start,data0,data1,data2,data3,data4,data5,out,out_valid,done);
input [8:0] data0,data1,data2,data3,data4,data5;
input clk,rst_n,start;
output reg [8:0] out ;
output reg done;
output  out_valid;


localparam IDLE=0,R1=1,R2=2,R3=3,R4=4,R5=5,FIN=6;
reg [2:0] cs,ns,cnt,end_cnt,cnt_out;
reg [8:0] temp [5:0];
assign out_valid = (cs == FIN)?1:0;

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) done<=0;
    else done<=(ns == IDLE && cs == FIN)?1:0;
end

always@(posedge clk)
begin
    if(ns == FIN) cnt_out<=cnt_out+1;
    else cnt_out<=0;
end


always@(*)
begin
    case(cs)
        IDLE:ns=(start)?R1:IDLE;
        R1:ns=(cnt == 5)?R2:R1;
        R2:ns=(cnt == 4)?R3:R2;
        R3:ns=(cnt == 3)?R4:R3;
        R4:ns=(cnt == 2)?R5:R4;
        R5:ns=(cnt == 1)?FIN:R5;
        FIN:ns=(cnt_out == 6)?IDLE:FIN;
        default:ns = IDLE;
    endcase
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) out<=0;
    else if(ns == FIN) out<=temp[cnt_out];
end

always@(*)
begin
    case(cs)
        R1:end_cnt=5;
        R2:end_cnt=4;
        R3:end_cnt=3;
        R4:end_cnt=2;
        R5:end_cnt=1;
        default:end_cnt=5;
    endcase
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cs<=IDLE;
    else cs<=ns;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cnt<=0;
    else if(cs == IDLE) cnt<=0;
    else cnt<=(cnt == end_cnt)?0:cnt+1;
end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        temp[0]<=0;
        temp[1]<=0;
        temp[2]<=0;
        temp[3]<=0;
        temp[4]<=0;
        temp[5]<=0;
    end
    else if(start & (cs == IDLE)) begin
        temp[0]<=data0;
        temp[1]<=data1;
        temp[2]<=data2;
        temp[3]<=data3;
        temp[4]<=data4;
        temp[5]<=data5;
    end
    else if(temp[cnt] < temp[cnt + 1]) begin
        temp[cnt]<=temp[cnt + 1];
        temp[cnt + 1]<=temp[cnt];
    end
end

endmodule


