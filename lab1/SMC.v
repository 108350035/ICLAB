module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
output [9:0] out_n;         							// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
 //output reg [9:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [9:0] temp0,temp1,temp2,temp3,temp4,temp5;
wire [9:0] temp0_S,temp1_S,temp2_S,temp3_S,temp4_S,temp5_S;
wire [9:0] a,b,c;
//================================================================
//    DESIGN
//================================================================
// --------------------------------------------------
// write your design here
// --------------------------------------------------
sel_gm_id A0(.W(W_0) ,.VGS(V_GS_0) ,.VDS(V_DS_0) ,.mode(mode[0]) ,.result(temp0));
sel_gm_id A1(.W(W_1) ,.VGS(V_GS_1) ,.VDS(V_DS_1) ,.mode(mode[0]) ,.result(temp1));
sel_gm_id A2(.W(W_2) ,.VGS(V_GS_2) ,.VDS(V_DS_2) ,.mode(mode[0]) ,.result(temp2));
sel_gm_id A3(.W(W_3) ,.VGS(V_GS_3) ,.VDS(V_DS_3) ,.mode(mode[0]) ,.result(temp3));
sel_gm_id A4(.W(W_4) ,.VGS(V_GS_4) ,.VDS(V_DS_4) ,.mode(mode[0]) ,.result(temp4));
sel_gm_id A5(.W(W_5) ,.VGS(V_GS_5) ,.VDS(V_DS_5) ,.mode(mode[0]) ,.result(temp5));

//=================================================
bubble_sort S1(.temp0(temp0),.temp1(temp1),.temp2(temp2),.temp3(temp3),.temp4(temp4),.temp5(temp5),.temp0_S(temp0_S),.temp1_S(temp1_S),.temp2_S(temp2_S),.temp3_S(temp3_S),.temp4_S(temp4_S),.temp5_S(temp5_S));
//=================================================
assign a = (mode[1])?temp0_S:temp3_S;
assign b = (mode[1])?temp1_S:temp4_S;
assign c = (mode[1])?temp2_S:temp5_S;
assign out_n = (mode[0])?((a<<1)+a)+(b<<2)+((c<<2)+c):(a+b)+c;
//=================================================
endmodule

//================================================================
//   SUB MODULE
//================================================================
module bubble_sort(temp0,temp1,temp2,temp3,temp4,temp5,temp0_S,temp1_S,temp2_S,temp3_S,temp4_S,temp5_S);
input [9:0] temp0,temp1,temp2,temp3,temp4,temp5;
output  [9:0] temp0_S,temp1_S,temp2_S,temp3_S,temp4_S,temp5_S;
//wire [9:0] R0,R1,R2,R3,R4,R5,R6,R7,R8,A0,A1,A2,A3,A4,A5,A6,B0,B1,B2,B3,B4,C0,C1,C2,C3;
integer i,j;
reg [9:0] sort [5:0];
reg [9:0] temp;

always@(*)
    begin
        sort[0]=temp0;
        sort[1]=temp1;
        sort[2]=temp2;
        sort[3]=temp3;
        sort[4]=temp4;
        sort[5]=temp5;

//===================sort=============================
	for(i=0;i<6;i=i+1) begin:loop1
		for(j=0;j<5-i;j=j+1) begin:loop2
			if(sort[j]<sort[j+1]) begin
				temp = sort[j];
				sort[j]=sort[j+1];
				sort[j+1]=temp;
			end
		end
	end

end

assign temp0_S = sort[0];
assign temp1_S = sort[1];
assign temp2_S = sort[2];
assign temp3_S = sort[3];
assign temp4_S = sort[4];
assign temp5_S = sort[5];

//第二種寫法，但面積較大
/*assign R0 = (temp1 > temp0)?temp0:temp1;//R0 
assign R1 = (temp1 > temp0)?temp1:temp0;//R0
assign R2 = (temp2 > R1)?R1:temp2;//R0 R2
assign R3 = (temp2 > R1)?temp2:R1;//R0 R2
assign R4 = (temp3 > R3)?R3:temp3;//R0 R2 R4
assign R5 = (temp3 > R3)?temp3:R3;//R0 R2 R4
assign R6 = (temp4 > R5)?R5:temp4;//R0 R2 R4 R6
assign R7 = (temp4 > R5)?temp4:R5;//R0 R2 R4 R6
assign R8 = (temp5 > R7)?R7:temp5;//R0 R2 R4 R6 R8
assign temp0_S = (temp5 > R8)?temp5:R7;//R0 R2 R4 R6 R8 R9

assign A0 = (R0 > R2)?R2:R0;//A0 
assign A1 = (R0 > R2)?R0:R2;//A0      
assign A2 = (A1 > R4)?R4:A1;//A0 A2
assign A3 = (A1 > R4)?A1:R4;//A0 A2
assign A4 = (A3 > R6)?R6:A3;//A0 A2 A4
assign A5 = (A3 > R6)?A3:R6;//A0 A2 A4
assign A6 = (A5 > R8)?R8:A5;//A0 A2 A4 A6
assign temp1_S = (A5 > R8)?A5:R8;//A0 A2 A4 A6 A7

assign B0 = (A0 > A2)?A2:A0;//B0
assign B1 = (A0 > A2)?A0:A2;//B0
assign B2 = (B1 > A4)?A4:B1;//B0 B2
assign B3 = (B1 > A4)?B1:A4;//B0 B2
assign B4 = (B3 > A6)?A6:B3;//B0 B2 B4
assign temp2_S = (B3 > A6)?B3:A6;//B0 B2 B4 B5

assign C0 = (B0 > B2)?B2:B0;//C0
assign C1 = (B0 > B2)?B0:B2;//C0
assign C2 = (C1 > B4)?B4:C1;//C0 C2
assign temp3_S = (C1 > B4)?C1:B4;//C0 C2 C3

assign temp5_S = (C0 > C2)?C2:C0;//D0
assign temp4_S = (C0 > C2)?C0:C2;//D0*/


endmodule

module sel_gm_id(W,VGS,VDS,mode,result);
input [2:0] W,VGS,VDS;
input mode;
output reg [9:0] result;

wire [2:0] Vov;
wire REGION_0;

assign Vov = VGS - 3'b1;
assign REGION_0 = (Vov>VDS)?1:0;
always@(*)
begin
    if(mode) result = (REGION_0)?(W*(((VDS*Vov)<<1)-(VDS**2)))/3:(W*(Vov**2))/3;
    else result = (REGION_0)?((W*VDS)<<1)/3:(((W*Vov))<<1)/3;
end

endmodule

// module BBQ (meat,vagetable,water,cost);
// input XXX;
// output XXX;
// 
// endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
// 	out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
// 	case(op)
// 		2'b00: output_reg = a + b;
// 		2'b10: output_reg = a - b;
// 		2'b01: output_reg = a * b;
// 		2'b11: output_reg = a / b;
// 		default: output_reg = 0;
// 	endcase
// end
// --------------------------------------------------
