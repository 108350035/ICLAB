//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module INV_IP #(parameter IP_WIDTH = 5) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);

// ===============================================================
// Declaration
// ===============================================================
input  [IP_WIDTH-1:0] IN_1, IN_2; 
output reg [IP_WIDTH-1:0] OUT_INV;
// ===============================================================
// IN_WIDTH dependent parameters
// ===============================================================
//find x when a*x+b*y=1
generate
        wire [IP_WIDTH-1:0] a,b;
        assign b = (IN_1 > IN_2)?IN_1:IN_2;
        assign a = (IN_1 > IN_2)?IN_2:IN_1;
        reg [IP_WIDTH-1:0] r [6:0],q [7:0],INV;
        reg [IP_WIDTH:0] t [7:0];
        always@(*) begin
            r[0] = b % a;
            r[1] = a % r[0];
            r[2] = r[0] % r[1];
            r[3] = r[1] % r[2];
            r[4] = r[2] % r[3];
            r[5] = r[3] % r[4];
            r[6] = r[4] % r[5];
        end

        always@(*) begin
            t[0] = 0 - q[0];
            t[1] = 1 - q[1] * t[0];
            t[2] = t[0] - q[2] * t[1];
            t[3] = t[1] - q[3] * t[2];
            t[4] = t[2] - q[4] * t[3];
            t[5] = t[3] - q[5] * t[4];
            t[6] = t[4] - q[6] * t[5];
            t[7] = t[5] - q[7] * t[6];
        end

        always@(*) begin
            q[0] = b / a;
            q[1] = a / r[0];
            q[2] = r[0] / r[1];
            q[3] = r[1] / r[2];
            q[4] = r[2] / r[3];
            q[5] = r[3] / r[4];
            q[6] = r[4] / r[5];
            q[7] = r[5] / r[6];
        end

        always@(*) begin
            if(a == 1) INV = 1;
            else if(r[0] == 1) INV = (t[0][IP_WIDTH])?t[0]+b:t[0];
            else if(r[1] == 1) INV = (t[1][IP_WIDTH])?t[1]+b:t[1];
            else if(r[2] == 1) INV = (t[2][IP_WIDTH])?t[2]+b:t[2];
            else if(r[3] == 1) INV = (t[3][IP_WIDTH])?t[3]+b:t[3];
            else if(r[4] == 1) INV = (t[4][IP_WIDTH])?t[4]+b:t[4];
            else if(r[5] == 1) INV = (t[5][IP_WIDTH])?t[5]+b:t[5];
            else if(r[6] == 1) INV = (t[6][IP_WIDTH])?t[6]+b:t[6];
            else INV = (t[7][IP_WIDTH])?t[7]+b:t[7];
        end

        always@(*) OUT_INV = INV;
endgenerate

        

endmodule
