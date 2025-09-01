//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
	input clk, rst_n, in_valid;
	input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
	output reg out_valid;
	output reg [6-1:0] out_Rx, out_Ry;
// ===============================================================
// parameters declaration
// ===============================================================
   	parameter [2:0] idle=3'd0,iter1=3'd1,iter2=3'd2,iter3=3'd3,iter4=3'd4;
// ===============================================================
// registers and wire delcaration
// ===============================================================
    reg [2:0] cs,ns;
    reg [5:0] Px,Py,Qx,Qy,prime,a;
    reg [5:0] Rx,Ry,deno,nume;
    wire [5:0] inv,p;
    wire [13:0] mult_out;
    reg [13:0] add1;
    reg [6:0] add2;
    reg [5:0] sub1,sub2,mult2;
    reg [7:0] mult1;
    wire [13:0] addsub;
// ===============================================================
// Instntiate IP
// ===============================================================
    INV_IP #(.IP_WIDTH(6)) IP1(.IN_1(deno),.IN_2(prime),.OUT_INV(inv));
// ===============================================================
// Shared Arithmetic Unit
// ===============================================================
    assign p = (in_valid)?in_prime:prime;
    assign mult_out = (mult1 * mult2);
    assign addsub = add1 + add2 - sub1 - sub2 ;
// ===============================================================
// FSM declaration
// ===============================================================

    always@(posedge clk,negedge rst_n)
    begin
        if(!rst_n) deno<=0;
        else if(in_valid) deno<=addsub % p;
        else if(cs == iter1) deno<=inv;
    end

    always@(posedge clk,negedge rst_n)
    begin
        if(!rst_n) nume<=0;
        else if(cs == iter1) nume<=addsub % p;
        else if(cs == iter2) nume<=addsub % p;
    end


    always@(*)
    begin
        case(cs)

            idle: if(in_valid && in_Px == in_Qx && in_Py == in_Qy) begin
                    add2 = 0;
                    sub1 = 0;
                    sub2 = 0;
                    add1 = mult_out;
                end
                else begin
                    add1 = in_Qx;
                    add2 = p;
                    sub1 = in_Px;
                    sub2 = 0;
                end
                    

            iter1:if(Px == Qx && Py == Qy) begin
                    add2 = a;
                    sub1 = 0;
                    sub2 = 0;
                    add1 = mult_out;
                end
                else begin
                    add1 = Qy;
                    add2 = p;
                    sub1 = Py;
                    sub2 = 0;
                end

            iter2:begin
                    add2 = 0;
                    sub1 = 0;
                    sub2 = 0;
                    add1 = mult_out;
                end

            iter3:begin
                    add2 = prime << 1;
                    sub1 = Px;
                    sub2 = Qx;
                    add1 = mult_out;
                end

            iter4:begin
                    add2 = prime;
                    sub1 = Py;
                    sub2 = 0;
                    add1 = mult_out;
                end

            default:begin
                    add2 = 0;
                    sub1 = 0;
                    sub2 = 0;
                    add1 = 0;
                end
        endcase
    end

                    
    
    always@(*)
    begin
        case(cs)
            idle: begin
                    mult1 = in_Py;
                    mult2 = 2;
                end

            iter1:begin
                    mult1 = 3 * Px;
                    mult2 = Px;
                end

            iter2: begin
                    mult1 = nume;
                    mult2 = deno;
                end

            iter3: begin
                    mult1 = nume;
                    mult2 = nume;
                end

            iter4: begin
                    mult1 = Px - Rx + p;
                    mult2 = nume;
                end
            default:begin
                    mult1 = 0;
                    mult2 = 0;
                end
        endcase
    end





    always@(posedge clk,negedge rst_n)
    begin
        if(!rst_n) begin
            Px<=0;
            Py<=0;
            Qx<=0;
            Qy<=0;
            a<=0;
            prime<=0;
        end
        else if(in_valid) begin
            Px<=in_Px;
            Py<=in_Py;
            Qx<=in_Qx;
            Qy<=in_Qy;
            a<=in_a;
            prime<=in_prime;
        end
    end

    always@(posedge clk,negedge rst_n)
    begin
        if(!rst_n) Rx<=0;
        else if(cs == iter3) Rx<=addsub % p;
    end

    
    always@(posedge clk,negedge rst_n)
    begin
        if(!rst_n) cs<=idle;
        else cs<=ns;
    end


    always@(*)
    begin
        case(cs)
            idle:ns=(in_valid)?iter1:idle;
            iter1:ns=iter2;
            iter2:ns=iter3;
            iter3:ns=iter4;
            iter4:ns=idle;
            default:ns=idle;
        endcase
    end

    always@(posedge clk,negedge rst_n)
    begin
        if(!rst_n) begin
            out_Rx<=0;
            out_Ry<=0;
            out_valid<=0;
        end
        else if(cs == iter4) begin
            out_Rx<=Rx;
            out_Ry<=addsub % p;
            out_valid<=1;
        end
        else begin
            out_Rx<=0;
            out_Ry<=0;
            out_valid<=0;
        end
    end

                          
    endmodule
