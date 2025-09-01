module CHIP(
  // input signals

  clk,
  rst_n,
  in_valid,
  in_valid2,
  matrix,
  matrix_size,
  i_mat_idx,
  w_mat_idx,

  // output signals

  out_valid,
  out_value 
);

input clk, rst_n;
input in_valid, in_valid2;
input matrix;
input [1:0] matrix_size;
input i_mat_idx, w_mat_idx;

output out_valid;
output out_value;

//input wires
wire C_clk, BUF_CLK;
wire C_rst_n;
wire C_in_valid, C_in_valid2;
wire C_matrix;
wire [1:0] C_matrix_size;
wire C_i_mat_idx;
wire C_w_mat_idx;
//output wires
wire C_out_valid;
wire C_out_value;

//core module
MMSA CORE(
	.clk(BUF_CLK),
	.rst_n(C_rst_n),
	.in_valid(C_in_valid),
	.in_valid2(C_in_valid2),
	.matrix_size(C_matrix_size),
	.i_mat_idx(C_i_mat_idx),
	.w_mat_idx(C_w_mat_idx),
	.matrix(C_matrix),
	
	.out_valid(C_out_valid),
	.out_value(C_out_value)
);

CLKBUFX20 CLKB(.A(C_clk),.Y(BUF_CLK));
PDUSDGZ I_CLK(.PAD(clk), .C(C_clk));
PDUSDGZ I_RESET(.PAD(rst_n), .C(C_rst_n));
PDUSDGZ I_VALID(.PAD(in_valid), .C(C_in_valid));
PDUSDGZ I_VALID2(.PAD(in_valid2), .C(C_in_valid2));
PDUSDGZ I_MATRIX(.PAD(matrix), .C(C_matrix));
PDUSDGZ I_I_MAT_IDX(.PAD(i_mat_idx), .C(C_i_mat_idx));
PDUSDGZ I_W_MAT_IDX(.PAD(w_mat_idx), .C(C_w_mat_idx));
PDUSDGZ I_MATRIX_SIZE_0(.PAD(matrix_size[0]), .C(C_matrix_size[0]));
PDUSDGZ I_MATRIX_SIZE_1(.PAD(matrix_size[1]), .C(C_matrix_size[1]));


PDU16SDGZ O_VALID(.OEN(1'b0), .I(C_out_valid), .PAD(out_valid), .C());
PDU16SDGZ O_VALUE(.OEN(1'b0), .I(C_out_value), .PAD(out_value), .C());



//I/O power 3.3V 8 pads  (DVDD + DGND)
PVDD2DGZ VDDP0 ();
PVSS2DGZ GNDP0 ();
PVDD2DGZ VDDP1 ();
PVSS2DGZ GNDP1 ();
PVDD2DGZ VDDP2 ();
PVSS2DGZ GNDP2 ();
PVDD2DGZ VDDP3 ();
PVSS2DGZ GNDP3 ();
PVDD2DGZ VDDP4 ();
PVSS2DGZ GNDP4 ();
PVDD2DGZ VDDP5 ();
PVSS2DGZ GNDP5 ();
PVDD2DGZ VDDP6 ();
PVSS2DGZ GNDP6 ();
PVDD2DGZ VDDP7 ();
PVSS2DGZ GNDP7 ();





//Core poweri 1.8V 8 pads  (VDD + GND)

PVDD1DGZ VDDC0 ();
PVSS1DGZ GNDC0 ();
PVDD1DGZ VDDC1 ();
PVSS1DGZ GNDC1 ();
PVDD1DGZ VDDC2 ();
PVSS1DGZ GNDC2 ();
PVDD1DGZ VDDC3 ();
PVSS1DGZ GNDC3 ();
PVDD1DGZ VDDC4 ();
PVSS1DGZ GNDC4 ();
PVDD1DGZ VDDC5 ();
PVSS1DGZ GNDC5 ();
PVDD1DGZ VDDC6 ();
PVSS1DGZ GNDC6 ();
PVDD1DGZ VDDC7 ();
PVSS1DGZ GNDC7 ();




endmodule


