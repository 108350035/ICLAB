module CHIP( 	
	clk,
    rst_n,
    in_valid,
    in_x,
    in_y,
    move_num,
    priority_num,
    out_valid,
    out_x,
    out_y,
    move_out);

input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output out_valid;
output [2:0] out_x,out_y;
output [4:0] move_out;

wire   C_clk;
wire   C_rst_n;
wire   C_in_valid;
wire  [2:0] C_in_x,C_in_y;
wire  [4:0] C_move_num;
wire  [2:0] C_priority_num;

wire  C_out_valid;
wire  [2:0] C_out_x,C_out_y;
wire  [4:0] C_move_out;

wire BUF_clk;
CLKBUFX20 buf0(.A(C_clk),.Y(BUF_clk));

KT I_KT(
	// Input signals
	.clk(BUF_clk),
	.rst_n(C_rst_n),
	.in_valid(C_in_valid),
	.in_x(C_in_x),
	.in_y(C_in_y),
	.move_num(C_move_num),
    .priority_num(C_priority_num),
    .out_valid(C_out_valid),
    .out_x(C_out_x),
    .out_y(C_out_y),
    .move_out(C_move_out)
);

// Input Pads
PDUSDGZ I_CLK(.PAD(clk), .C(C_clk));
PDUSDGZ I_RESET(.PAD(rst_n), .C(C_rst_n));
PDUSDGZ I_IN_VALID(.PAD(in_valid), .C(C_in_valid));
PDUSDGZ I_IN_X_2(.PAD(in_x[2]), .C(C_in_x[2]));
PDUSDGZ I_IN_X_1(.PAD(in_x[1]), .C(C_in_x[1]));
PDUSDGZ I_IN_X_0(.PAD(in_x[0]), .C(C_in_x[0]));
PDUSDGZ I_IN_Y_2(.PAD(in_y[2]), .C(C_in_y[2]));
PDUSDGZ I_IN_Y_1(.PAD(in_y[1]), .C(C_in_y[1]));
PDUSDGZ I_IN_Y_0(.PAD(in_y[0]), .C(C_in_y[0]));
PDUSDGZ I_MOVE_NUM_4(.PAD(move_num[4]), .C(C_move_num[4]));
PDUSDGZ I_MOVE_NUM_3(.PAD(move_num[3]), .C(C_move_num[3]));
PDUSDGZ I_MOVE_NUM_2(.PAD(move_num[2]), .C(C_move_num[2]));
PDUSDGZ I_MOVE_NUM_1(.PAD(move_num[1]), .C(C_move_num[1]));
PDUSDGZ I_MOVE_NUM_0(.PAD(move_num[0]), .C(C_move_num[0]));
PDUSDGZ I_PRIORITY_NUM_2(.PAD(priority_num[2]), .C(C_priority_num[2]));
PDUSDGZ I_PRIORITY_NUM_1(.PAD(priority_num[1]), .C(C_priority_num[1]));
PDUSDGZ I_PRIORITY_NUM_0(.PAD(priority_num[0]), .C(C_priority_num[0]));
// Output Pads
PDD08SDGZ O_OUT_VALID(.OEN(1'b0), .I(C_out_valid), .PAD(out_valid), .C());
PDD08SDGZ O_OUT_X_0(.OEN(1'b0), .I(C_out_x[0]), .PAD(out_x[0]), .C());
PDD08SDGZ O_OUT_X_1(.OEN(1'b0), .I(C_out_x[1]), .PAD(out_x[1]), .C());
PDD08SDGZ O_OUT_X_2(.OEN(1'b0), .I(C_out_x[2]), .PAD(out_x[2]), .C());
PDD08SDGZ O_OUT_Y_0(.OEN(1'b0), .I(C_out_y[0]), .PAD(out_y[0]), .C());
PDD08SDGZ O_OUT_Y_1(.OEN(1'b0), .I(C_out_y[1]), .PAD(out_y[1]), .C());
PDD08SDGZ O_OUT_Y_2(.OEN(1'b0), .I(C_out_y[2]), .PAD(out_y[2]), .C());
PDD08SDGZ O_MOVE_OUT_0(.OEN(1'b0), .I(C_move_out[0]), .PAD(move_out[0]), .C());
PDD08SDGZ O_MOVE_OUT_1(.OEN(1'b0), .I(C_move_out[1]), .PAD(move_out[1]), .C());
PDD08SDGZ O_MOVE_OUT_2(.OEN(1'b0), .I(C_move_out[2]), .PAD(move_out[2]), .C());
PDD08SDGZ O_MOVE_OUT_3(.OEN(1'b0), .I(C_move_out[3]), .PAD(move_out[3]), .C());
PDD08SDGZ O_MOVE_OUT_4(.OEN(1'b0), .I(C_move_out[4]), .PAD(move_out[4]), .C());

// IO power 
PVDD2DGZ VDDP0 ();
PVSS2DGZ GNDP0 ();
PVDD2DGZ VDDP1 ();
PVSS2DGZ GNDP1 ();
PVDD2DGZ VDDP2 ();
PVSS2DGZ GNDP2 ();
PVDD2DGZ VDDP3 ();
PVSS2DGZ GNDP3 ();


// Core power
PVDD1DGZ VDDC0 ();
PVSS1DGZ GNDC0 ();
PVDD1DGZ VDDC1 ();
PVSS1DGZ GNDC1 ();
PVDD1DGZ VDDC2 ();
PVSS1DGZ GNDC2 ();
PVDD1DGZ VDDC3 ();
PVSS1DGZ GNDC3 ();


endmodule
module CHIP( 	
	clk,
    rst_n,
    in_valid,
    in_x,
    in_y,
    move_num,
    priority_num,
    out_valid,
    out_x,
    out_y,
    move_out);

input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output out_valid;
output [2:0] out_x,out_y;
output [4:0] move_out;

wire   C_clk;
wire   C_rst_n;
wire   C_in_valid;
wire  [2:0] C_in_x,C_in_y;
wire  [4:0] C_move_num;
wire  [2:0] C_priority_num;

wire  C_out_valid;
wire  [2:0] C_out_x,C_out_y;
wire  [4:0] C_move_out;

wire BUF_clk;
CLKBUFX20 buf0(.A(C_clk),.Y(BUF_clk));

KT I_KT(
	// Input signals
	.clk(BUF_clk),
	.rst_n(C_rst_n),
	.in_valid(C_in_valid),
	.in_x(C_in_x),
	.in_y(C_in_y),
	.move_num(C_move_num),
    .priority_num(C_priority_num),
    .out_valid(C_out_valid),
    .out_x(C_out_x),
    .out_y(C_out_y),
    .move_out(C_move_out)
);

// Input Pads
PDUSDGZ I_CLK(.PAD(clk), .C(C_clk));
PDUSDGZ I_RESET(.PAD(rst_n), .C(C_rst_n));
PDUSDGZ I_IN_VALID(.PAD(in_valid), .C(C_in_valid));
PDUSDGZ I_IN_X_2(.PAD(in_x[2]), .C(C_in_x[2]));
PDUSDGZ I_IN_X_1(.PAD(in_x[1]), .C(C_in_x[1]));
PDUSDGZ I_IN_X_0(.PAD(in_x[0]), .C(C_in_x[0]));
PDUSDGZ I_IN_Y_2(.PAD(in_y[2]), .C(C_in_y[2]));
PDUSDGZ I_IN_Y_1(.PAD(in_y[1]), .C(C_in_y[1]));
PDUSDGZ I_IN_Y_0(.PAD(in_y[0]), .C(C_in_y[0]));
PDUSDGZ I_MOVE_NUM_4(.PAD(move_num[4]), .C(C_move_num[4]));
PDUSDGZ I_MOVE_NUM_3(.PAD(move_num[3]), .C(C_move_num[3]));
PDUSDGZ I_MOVE_NUM_2(.PAD(move_num[2]), .C(C_move_num[2]));
PDUSDGZ I_MOVE_NUM_1(.PAD(move_num[1]), .C(C_move_num[1]));
PDUSDGZ I_MOVE_NUM_0(.PAD(move_num[0]), .C(C_move_num[0]));
PDUSDGZ I_PRIORITY_NUM_2(.PAD(priority_num[2]), .C(C_priority_num[2]));
PDUSDGZ I_PRIORITY_NUM_1(.PAD(priority_num[1]), .C(C_priority_num[1]));
PDUSDGZ I_PRIORITY_NUM_0(.PAD(priority_num[0]), .C(C_priority_num[0]));
// Output Pads
PDD08SDGZ O_OUT_VALID(.OEN(1'b0), .I(C_out_valid), .PAD(out_valid), .C());
PDD08SDGZ O_OUT_X_0(.OEN(1'b0), .I(C_out_x[0]), .PAD(out_x[0]), .C());
PDD08SDGZ O_OUT_X_1(.OEN(1'b0), .I(C_out_x[1]), .PAD(out_x[1]), .C());
PDD08SDGZ O_OUT_X_2(.OEN(1'b0), .I(C_out_x[2]), .PAD(out_x[2]), .C());
PDD08SDGZ O_OUT_Y_0(.OEN(1'b0), .I(C_out_y[0]), .PAD(out_y[0]), .C());
PDD08SDGZ O_OUT_Y_1(.OEN(1'b0), .I(C_out_y[1]), .PAD(out_y[1]), .C());
PDD08SDGZ O_OUT_Y_2(.OEN(1'b0), .I(C_out_y[2]), .PAD(out_y[2]), .C());
PDD08SDGZ O_MOVE_OUT_0(.OEN(1'b0), .I(C_move_out[0]), .PAD(move_out[0]), .C());
PDD08SDGZ O_MOVE_OUT_1(.OEN(1'b0), .I(C_move_out[1]), .PAD(move_out[1]), .C());
PDD08SDGZ O_MOVE_OUT_2(.OEN(1'b0), .I(C_move_out[2]), .PAD(move_out[2]), .C());
PDD08SDGZ O_MOVE_OUT_3(.OEN(1'b0), .I(C_move_out[3]), .PAD(move_out[3]), .C());
PDD08SDGZ O_MOVE_OUT_4(.OEN(1'b0), .I(C_move_out[4]), .PAD(move_out[4]), .C());

// IO power 
PVDD2DGZ VDDP0 ();
PVSS2DGZ GNDP0 ();
PVDD2DGZ VDDP1 ();
PVSS2DGZ GNDP1 ();
PVDD2DGZ VDDP2 ();
PVSS2DGZ GNDP2 ();
PVDD2DGZ VDDP3 ();
PVSS2DGZ GNDP3 ();


// Core power
PVDD1DGZ VDDC0 ();
PVSS1DGZ GNDC0 ();
PVDD1DGZ VDDC1 ();
PVSS1DGZ GNDC1 ();
PVDD1DGZ VDDC2 ();
PVSS1DGZ GNDC2 ();
PVDD1DGZ VDDC3 ();
PVSS1DGZ GNDC3 ();


endmodule

