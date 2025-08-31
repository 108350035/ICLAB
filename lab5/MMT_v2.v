//synopsys translate_off
//`include "/home/synopsys/syn/O-2018.06-SP1/dw/sim_ver/DW02_prod_sum1.v"
//synopsys translate_on
module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n;
input in_valid;
input signed [7:0] matrix;
input [1:0]  matrix_size;

input in_valid2;
input [4:0]  matrix_idx;
input [1:0]  mode;

output reg       	     out_valid;
output reg signed [49:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER, WIRE AND REG DECLARATION
//---------------------------------------------------------------------
parameter [2:0] IDLE=3'd0,W_INPUT=3'd1,M_SEL=3'd2,AB_DIF=3'd3,AB_SAM=3'd4,CAL_C=3'd5,OUT=3'd6;
reg [4:0] idx [2:0];
reg [1:0] matrix_mode;
reg [7:0] matrix_temp;
reg [3:0] boundary,WEN;
reg [2:0] cs,ns;
reg [2:0] mat0;
wire shift,equal;
reg valid,odd,C_WEN,mul_add_done;
reg [3:0] row0,col0,row1,col1,iter;
wire [3:0] row0_ns,col0_ns,row1_ns,col1_ns,row2_ns,col2_ns;
wire [2:0] mat0_ns;
reg [10:0] addr0,addr1,addr2,addr3;
reg signed [19:0] A;
reg signed [7:0] B,A_temp;
reg signed [33:0] C,ACC;
wire signed [33:0] SUM,ANS_ns;
reg signed [35:0] ANS;
assign ANS_ns = ANS + SUM;
wire signed [7:0] SRAM0_Q;
MATRIX M0(.Q(SRAM0_Q),.CLK(clk),.CEN(1'b0),.WEN(WEN[0]),.A(addr0),.D(matrix_temp),.OEN(1'b0));

wire signed [7:0] SRAM1_Q;
MATRIX M1(.Q(SRAM1_Q),.CLK(clk),.CEN(1'b0),.WEN(WEN[1]),.A(addr1),.D(matrix_temp),.OEN(1'b0));

wire signed [7:0] SRAM2_Q;
MATRIX M2(.Q(SRAM2_Q),.CLK(clk),.CEN(1'b0),.WEN(WEN[2]),.A(addr2),.D(matrix_temp),.OEN(1'b0));

wire signed [7:0] SRAM3_Q;
MATRIX M3(.Q(SRAM3_Q),.CLK(clk),.CEN(1'b0),.WEN(WEN[3]),.A(addr3),.D(matrix_temp),.OEN(1'b0));
wire signed [19:0] SRAM4_Q;
reg [3:0] row2,col2;
MATRIX2 M4(.Q(SRAM4_Q),.CLK(clk),.CEN(1'b0),.WEN(C_WEN),.A({row2,col2}),.D({ACC[33],ACC[18:0]}),.OEN(1'b0));

DW02_prod_sum1 #(20, 8, 34) MA0 ( .A(A), .B(B), .C(C), .TC(1'b1), .SUM(SUM) );//TC=1 signed operation
assign equal = (idx[0][4:3] == idx[1][4:3]) && (idx[1][4:3] != idx[2][4:3]);
always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        out_valid<=0;
        out_value<=0;
    end
    else if(cs == OUT) begin
        out_valid<=1;
        out_value<=ANS;
    end
    else begin
        out_valid<=0;
        out_value<=0;
    end
end

always@(posedge clk)
begin
    if(cs == M_SEL) odd<=1;
    else if(cs == AB_SAM) odd<=(ns == CAL_C)?0:~odd;
    else odd<=in_valid;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) iter<=0;
    else if(out_valid) iter<=(iter == 9)?0:iter+1;
end

assign row0_ns = (col0 == boundary)?((row0 == boundary)?0:row0+1):row0;
assign col0_ns = (col0 == boundary)?0:col0+1;
assign mat0_ns = (col0 == boundary && row0 == boundary)?mat0+1:mat0;

assign row1_ns = (col1 == boundary)?((row1 == boundary)?0:row1+1):row1;
assign col1_ns = (col1 == boundary)?0:col1+1;

assign row2_ns = (col2 == boundary)?((row2 == boundary)?0:row2+1):row2;
assign col2_ns = (col2 == boundary)?0:col2+1;

always@(posedge clk)
begin
    if(cs == CAL_C) ANS<=(col2 == 0 && row2 == 0 && valid == 0)?0:ANS_ns;
    else ANS<=0;
end
    

always@(*)
begin
    if(cs == AB_DIF) begin
        case(idx[0][4:3]) 
            2'd1:begin addr0 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr1 = (matrix_mode == 2'b01)?{idx[0][2:0],col0,row0}:{idx[0][2:0],row0,col0};
                       addr2 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr3 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
            end

            2'd0:begin addr0 = (matrix_mode == 2'b01)?{idx[0][2:0],col0,row0}:{idx[0][2:0],row0,col0};
                       addr1 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr2 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr3 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
            end

            2'd2:begin addr0 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr1 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr2 = (matrix_mode == 2'b01)?{idx[0][2:0],col0,row0}:{idx[0][2:0],row0,col0};
                       addr3 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
            end

            2'd3:begin addr0 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr1 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr2 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
                       addr3 = (matrix_mode == 2'b01)?{idx[0][2:0],col0,row0}:{idx[0][2:0],row0,col0};
            end
            
        endcase
    end
    else if(odd) begin
        addr0 = (matrix_mode == 2'b01)?{mat0,col0,row0}:{mat0,row0,col0};
        addr1 = (matrix_mode == 2'b01)?{mat0,col0,row0}:{mat0,row0,col0};
        addr2 = (matrix_mode == 2'b01)?{mat0,col0,row0}:{mat0,row0,col0};
        addr3 = (matrix_mode == 2'b01)?{mat0,col0,row0}:{mat0,row0,col0};
    end
    else begin
        addr0 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
        addr1 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
        addr2 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
        addr3 = (matrix_mode == 2'b10)?{idx[1][2:0],row1,col1}:{idx[1][2:0],col1,row1};
    end

end

       
assign shift=(mat0 == 3'b111 && row0 == boundary && col0 == boundary)?1:0;

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cs<=IDLE;
    else cs<=ns;
end

always@(*)
begin
    case(cs)
        IDLE:ns=(in_valid)?W_INPUT:IDLE;
        W_INPUT:ns=(in_valid2)?M_SEL:W_INPUT;
        M_SEL:ns=(valid)?M_SEL:((idx[0][4:3] == idx[1][4:3])?AB_SAM:AB_DIF);
        AB_SAM:ns=(col2 == boundary && row2 == boundary && C_WEN == 0)?CAL_C:AB_SAM;
        AB_DIF:ns=(col2 == boundary && row2 == boundary && C_WEN == 0)?CAL_C:AB_DIF;
        CAL_C:ns=(valid)?OUT:CAL_C;
        OUT:ns=(iter == 9)?IDLE:W_INPUT;
        default:ns=IDLE;
    endcase
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) A_temp<=0;
    else begin
    case(idx[0][4:3])
        2'd0:A_temp<=SRAM0_Q;
        2'd1:A_temp<=SRAM1_Q;
        2'd2:A_temp<=SRAM2_Q;
        2'd3:A_temp<=SRAM3_Q;
    endcase
    end
end


always@(*)
begin
    if(cs == AB_DIF) begin
        case(idx[0][4:3])
            0:A = SRAM0_Q;
            1:A = SRAM1_Q;
            2:A = SRAM2_Q;
            3:A = SRAM3_Q;
        endcase
    end
    else if(cs == AB_SAM)
        A = A_temp;
    else 
        A = SRAM4_Q;
end

always@(*)
begin
    case(idx[1][4:3])
        2'd0:B = SRAM0_Q;
        2'd1:B = SRAM1_Q;
        2'd2:B = SRAM2_Q;
        2'd3:B = SRAM3_Q;
    endcase
end

always@(posedge clk)
begin
    if(cs == AB_DIF) mul_add_done<=(col0 == boundary)?1:0;
    else mul_add_done<=(col1 == boundary)?1:0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) C_WEN<=1;
    else if(cs == AB_DIF) C_WEN<=~mul_add_done;
    else if(cs == AB_SAM && odd) C_WEN<=~mul_add_done;
    else C_WEN<=1;
end
   
always@(posedge clk)
begin
    if(cs == CAL_C) C<=0;
    else if(cs == AB_DIF) C<=(col0 == 0)?0:SUM;
    else if(odd& C_WEN) C<=(col1 == 0)?0:SUM;
end

always@(posedge clk)
begin
    if(cs == AB_DIF && mul_add_done) ACC<=SUM;
    else if(odd) ACC<=SUM;
    else ACC<=0;
end

always@(posedge clk)
begin
    if(cs == CAL_C) valid<=(col2 == boundary && row2 == boundary)?1:0;
    else valid<=in_valid2;
end
    

always@(posedge clk)
begin
    if(cs == IDLE) begin
        col2<=0;
        row2<=0;
    end
    else if(C_WEN == 0) begin
        col2<=col2_ns;
        row2<=row2_ns;
    end
    else if(cs == CAL_C) begin
        row2<=row2_ns;
        col2<=col2_ns;
    end
    else if(out_valid) begin
        row2<=0;
        col2<=0;
    end

end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        mat0<=0;
        col0<=0;
        row0<=0;
    end
    else if(&WEN == 0) begin
        mat0<=mat0_ns;
        row0<=row0_ns;
        col0<=col0_ns;
    end
    else if(cs == M_SEL) mat0<=idx[0][2:0]; 
    else if(cs == AB_DIF | odd) begin
        row0<=({row1,col1} == {boundary,boundary})?row0_ns:row0;
        col0<=col0_ns;
    end
    else if(out_valid) begin
        mat0<=0;
        row0<=0;
        col0<=0;
    end

end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        col1<=0;
        row1<=0;
    end
    else if(cs == AB_DIF) begin
        row1<=(ns == CAL_C)?0:row1_ns;
        col1<=(ns == CAL_C)?0:col1_ns;
    end
    else if(cs == AB_SAM & odd == 0) begin
        row1<=row1_ns;
        col1<=(ns == CAL_C)?0:col1_ns;
    end
    else if(cs == CAL_C) begin
        row1<=row1_ns;
        col1<=col1_ns;
    end
    else if(out_valid) begin
        row1<=0;
        col1<=0;
    end

end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) boundary<=0;
    else if(cs == IDLE && in_valid) begin
        case(matrix_size) 
            0:boundary<=1;
            1:boundary<=3;
            2:boundary<=7;
            3:boundary<=15;
        endcase
    end
end

always@(posedge clk)
begin
    if(in_valid) matrix_temp<=matrix;
    else matrix_temp<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) WEN<=4'b1111;
    else if(cs == IDLE) WEN[0]<=~in_valid;
    else if(cs == W_INPUT) begin
        if(shift & in_valid) begin
            WEN[0]<=WEN[3];
            WEN[1]<=WEN[0];
            WEN[2]<=WEN[1];
            WEN[3]<=WEN[2];
        end
        else if(in_valid == 0) WEN[3]<=1;
    end
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n)  matrix_mode<=0;
    else if(cs == W_INPUT && in_valid2) matrix_mode<=mode;
    else if(((in_valid2 == 0) && equal) || (ns == CAL_C && (C_WEN == 0))) begin
        case(matrix_mode)
            2'b01:matrix_mode<=2'b11;
            2'b10:matrix_mode<=2'b01;
            2'b11:matrix_mode<=2'b10;
        endcase
    end
    else if(out_valid) matrix_mode<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        idx[0]<=0;
        idx[1]<=0;
        idx[2]<=0;
    end
    else if(in_valid2) begin
        idx[2]<=matrix_idx;
        idx[1]<=idx[2];
        idx[0]<=idx[1];
    end
    else if( equal) begin
        idx[2]<=idx[0];
        idx[1]<=idx[2];
        idx[0]<=idx[1];
    end
    else if(ns == CAL_C) idx[1]<=idx[2];
end
    
endmodule

