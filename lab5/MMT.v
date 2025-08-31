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
parameter [3:0] idle='d0,write_0=4'd1,write_1=4'd2,mode_wait=4'd3,prepare=4'd4,mem_same_A=4'd5,
					 mem_differ=4'd6,mem_same_B=4'd7,prepare_2=4'd8,mem_C=4'd9,OUT=4'd10,write_t=4'd11,result_acc=4'd12,write_t_same=4'd13;
reg [3:0] cs,ns;
reg [4:0] idx [2:0];
reg [7:0] matrix_buffer;
wire signed [7:0] SRAM0_Q,SRAM1_Q;
reg signed [7:0] SRAM1_D,SRAM0_D,A_temp;
reg [3:0] size;
reg [3:0] row_t,col_t;
wire [7:0] addr_t;
reg [1:0] matrix_mode;
reg [3:0] matrix_num_0,matrix_num_1,num_cal;
reg signed [19:0] A;
reg signed [7:0] B;
wire signed [33:0] SUM;
reg signed [33:0] C;
reg [3:0] round;
reg signed [33:0] out_temp;

reg SRAM0_WEN;
reg [11:0] addr_0;
reg [3:0] row_0,col_0;
reg [3:0] row_cal,col_cal;//used to multiple matrix in same mem
wire [11:0] addr_cal={num_cal,row_cal,col_cal};
wire [11:0] addr_0_wire={matrix_num_0,row_0,col_0};
RA1SH_16 SRAM0(.Q(SRAM0_Q),.CLK(clk),.CEN(1'b0),.WEN(SRAM0_WEN),.A(addr_0),.D(SRAM0_D),.OEN(1'b0));

reg SRAM1_WEN;
reg [11:0] addr_1;
reg [3:0] row_1,col_1;
wire [11:0] addr_1_wire = {matrix_num_1,row_1,col_1};
RA1SH_16 SRAM1(.Q(SRAM1_Q),.CLK(clk),.CEN(1'b0),.WEN(SRAM1_WEN),.A(addr_1),.D(SRAM1_D),.OEN(1'b0));

assign addr_t ={row_t,col_t};
reg SRAMT_WEN;
wire signed [19:0] SRAMT_Q;
reg signed [19:0] SRAMT_D;
RA1SH_1 SRAMT(.Q(SRAMT_Q),.CLK(clk),.CEN(1'b0),.WEN(SRAMT_WEN),.A(addr_t),.D(SRAMT_D),.OEN(1'b0));



// Instance of DW02_prod_sum1
  DW02_prod_sum1 #(20, 8, 34)
    U1 ( .A(A), .B(B), .C(C), .TC(1'b1), .SUM(SUM) );//TC=1 signed operation

//matrix buffer
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) matrix_buffer<=0;
    else if(in_valid) matrix_buffer<=matrix;
end


//data receive
always@(*)
begin
	if(cs == idle) SRAM0_D = 0;
	else if(cs == write_0) SRAM0_D = matrix_buffer;
	else SRAM0_D = 0;
end

//data receive
always@(*)
begin
    if(cs == idle) SRAM1_D = 0;
    else if(cs == write_1) SRAM1_D = matrix_buffer;
	else SRAM1_D = 0;
end

//state transfer
always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cs<=idle;
    else cs<=ns;
end


//write or read or cal address
always@(*)
begin
    if(cs == write_0 || cs == mem_differ || cs == mem_C || cs == result_acc || cs == mem_same_A || cs == write_1 ) begin
        addr_0 = addr_0_wire;
        addr_1 = addr_1_wire;
    end
    else if(cs == mem_same_B ) begin 
        if(idx[1][4]) begin
            addr_1 = addr_cal;
            addr_0 = 0;
        end
        else begin
            addr_0 = addr_cal;
            addr_1 = 0;
        end
    end
    else begin 
        addr_0 = 0;
        addr_1 = 0;
    end
end

	

//sram write or read enable	
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) begin
		SRAM0_WEN<= 1;
		SRAM1_WEN<= 1;
		SRAMT_WEN<= 1;
	end
	else if(cs == idle) SRAM0_WEN<=(in_valid)? 0:1;
	else if(cs==write_0) begin
		SRAM0_WEN<=(addr_0 == {4'b1111,size,size})?1:0;
		SRAM1_WEN<=(addr_0 == {4'b1111,size,size})?0:1;
	end
    else if(cs==write_1)
		SRAM1_WEN<=(addr_1 == {4'b1111,size,size})?1:0;
    else if(cs == mem_differ) begin
        case(idx[0][4])
				0: SRAMT_WEN<=(matrix_mode == 2'b10)?((col_1 == size)?0:1):((row_1 == size)?0:1);
				1: SRAMT_WEN<=(matrix_mode == 2'b10)?((col_0 == size)?0:1):((row_0 == size)?0:1);
		endcase
    end
    else if(cs == mem_same_B) SRAMT_WEN<=(matrix_mode == 2'b10)?((col_cal == size)?0:1):((row_cal == size)?0:1);
    else if(cs == write_t || cs == write_t_same) SRAMT_WEN<=1;
end

//matrix idx
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) begin
		idx[0]<='b0;
		idx[1]<='b0;
		idx[2]<='b0;
	end
	else if(in_valid2) begin
		idx[0]<=idx[1];
		idx[1]<=idx[2];
		idx[2]<=matrix_idx;
	end
end

//matrix mode
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) matrix_mode<=0;
	else if(in_valid2 && cs == mode_wait ) matrix_mode<=mode;
end
	

//matrix size
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) size<='b0;
	else if(in_valid&&cs==idle) begin
		case(matrix_size)
			2'b00: size<='d1;//2x2
			2'b01: size<='d3;//4x4
			2'b10: size<='d7;//8x8
			2'b11: size<='d15;//16x16
		endcase
	end
end

always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) begin
		matrix_num_0<=0;
		row_0<=0;
		col_0<=0;
        matrix_num_1<=0;
		row_1<=0;
		col_1<=0;
        num_cal<=0;
		row_cal<='b0;
		col_cal<='b0;
	end
	else if(cs == idle) begin
		matrix_num_0<= 0;
        matrix_num_1<=0;
	end
	else if(cs == write_0) begin
		matrix_num_0<=((col_0 == size) && (row_0 == size))?matrix_num_0+'b1:matrix_num_0;
		col_0<=(col_0 == size)?0:col_0+4'b1;
		row_0<=(col_0 == size)?((row_0 == size)?0:row_0+4'b1):row_0;
	end
	else if(cs == write_1) begin
		matrix_num_1<=((col_1 == size) && (row_1 == size))?matrix_num_1+'b1:matrix_num_1;
		col_1<=(col_1 == size)?0:col_1+4'b1;
		row_1<=(col_1 == size)?((row_1 == size)?0:row_1+4'b1):row_1;
	end
    else if(cs == prepare && !in_valid2) begin
            if(idx[0][4]) begin
                matrix_num_1<=idx[0][3:0];
                matrix_num_0<=idx[1][3:0];
                num_cal<=idx[1][3:0];
            end
            else begin
                matrix_num_0<=idx[0][3:0];
                matrix_num_1<=idx[1][3:0];
                num_cal<=idx[1][3:0];
            end
    end
    else if(cs == mode_wait || cs == prepare_2) begin
        if(idx[2][4]) matrix_num_1<=idx[2][3:0];
        else matrix_num_0<=idx[2][3:0];
    end
    
    else if(cs == mem_differ) begin
				if(idx[0][4]) begin
					case(matrix_mode)
						2'b00,2'b11: begin//AB
							row_1<=(row_0 == size && col_0 == size )?((row_1 == size)?0:row_1+1):row_1;
							col_1<=(col_1 == size)?0:col_1+1;
							row_0<=(row_0 == size)?0:row_0+1;
							col_0<=(row_0 == size)?((col_0 == size)?0:col_0+1):col_0;
						end
						2'b01:begin //A^T B
							col_1<=(row_0 == size && col_0 == size)?((col_1 == size)?0:col_1+'b1):col_1;
							row_1<=(row_1 == size)?'b0:row_1+'b1;
							row_0<=(row_0 == size)?'b0:row_0+'b1;
							col_0<=(row_0 == size)?((col_0 == size)?0:col_0+'b1):col_0;
						end
						2'b10: begin //A B^T
							row_1<=(row_0 == size && col_0 == size)?((row_1 == size)?0:row_1+'b1):row_1;
							col_1<=(col_1 == size)?'b0:col_1+'b1;
							row_0<=(col_0 == size)?((row_0 == size)?0:row_0+'b1):row_0;
							col_0<=(col_0 == size)?'b0:col_0+'b1;
						end
					endcase
				end
				else begin
					case(matrix_mode)
						2'b00,2'b11: begin//AB
							row_0<=(row_1 == size && col_1 == size)?((row_0 == size)?0:row_0+'b1):row_0;
							col_0<=(col_0 == size)?'b0:col_0+'b1;
							row_1<=(row_1 == size)?'b0:row_1+'b1;
							col_1<=(row_1 == size)?((col_1 == size)?0:col_1+'b1):col_1;
						end
						2'b01:begin //A^T B
							col_0<=(row_1 == size && col_1 == size)?((col_0 == size)?0:col_0+'b1):col_0;
							row_0<=(row_0 == size)?'b0:row_0+'b1;
							row_1<=(row_1 == size)?'b0:row_1+'b1;
							col_1<=(row_1 == size)?((col_1 == size)?0:col_1+'b1):col_1;
						end
						2'b10: begin //A B^T
							row_0<=(row_1 == size && col_1 == size)?((row_0 == size)?0:row_0+'b1):row_0;
							col_0<=(col_0 == size)?'b0:col_0+'b1;
							row_1<=(col_1 == size)?((row_1 == size)?0:row_1+'b1):row_1;
							col_1<=(col_1 == size)?'b0:col_1+'b1;
						end
					endcase
				end
            end
    
	else if(cs == mem_same_B) begin
         matrix_num_1<=idx[0][3:0];
         matrix_num_0<=idx[0][3:0];
			case(matrix_mode)
				2'b00,2'b01,2'b11: begin //B
                    col_cal<=(row_cal == size)?((col_cal == size)?0:col_cal+1):col_cal;
                    row_cal<=(row_cal == size)?0:row_cal+1;
				end
                                
                2'b10: begin //B^T
                    col_cal<=(col_cal == size)?0:col_cal+1;
                    row_cal<=(col_cal == size)?((row_cal == size)?0:row_cal+1):row_cal;
				end
			endcase
	end
	else if(cs == mem_same_A) begin
         matrix_num_1<=idx[1][3:0];
         matrix_num_0<=idx[1][3:0];
		if(idx[0][4]) begin
			case(matrix_mode)
				2'b00,2'b10,2'b11: begin //A
					col_1<=(col_1 == size)?0:col_1+1;
					row_1<=(row_cal == size && col_cal == size)?((row_1 == size)?0:row_1+1):row_1;
                end

                2'b01: begin //A^T
                    col_1<=(row_cal == size && col_cal == size)?((col_1 == size)?0:col_1+1):col_1;
					row_1<=(row_1 == size)?0:row_1+1;
				end
			endcase
		end
		else begin
			case(matrix_mode)
				2'b00,2'b10,2'b11: begin //A
					col_0<=(col_0 == size)?0:col_0+1;
					row_0<=(row_cal == size && col_cal == size)?((row_0 == size)?0:row_0+1):row_0;
				end
                2'b01: begin //A^T
                    col_0<=(row_cal == size && col_cal == size)?((col_0 == size)?0:col_0+1):col_0;
					row_0<=(row_0 == size)?0:row_0+1;
				end
			endcase
		end
    end
    
	else if(cs == mem_C) begin
		if(idx[2][4]) begin
		case(matrix_mode)
			2'b11: begin//C^T
				col_1<=(col_1 == size)?0:col_1+1;
				row_1<=(col_1 == size)?((row_1 == size)?0:row_1+1):row_1;
			end
			
			default: begin//C
				col_1<=(row_1 == size)?((col_1 == size)?0:col_1+1):col_1;
				row_1<=(row_1 == size)?0:row_1+1;
			end
		endcase
		end
		else begin
		case(matrix_mode)
			2'b11: begin//C^T
				col_0<=(col_0 == size)?0:col_0+1;
				row_0<=(col_0 == size)?((row_0 == size)?0:row_0+1):row_0;
			end
			
			default: begin//C
				col_0<=(row_0 == size)?((col_0 == size)?0:col_0+1):col_0;
				row_0<=(row_0 == size)?0:row_0+1;
			end
		endcase
		end
	end
end

//target address
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) begin
		row_t<=0;
		col_t<=0;
	end
	else if(cs == write_t || cs == write_t_same) begin
        col_t<=(col_t == size)?0:col_t+1;
        row_t<=(col_t == size)?row_t+1:row_t;
    end
    else if(cs == prepare_2) begin
		col_t<='b0;
		row_t<='b0;
	end
	
	else if(cs == mem_C) begin
		if(idx[2][4]) begin
            col_t<=(matrix_mode == 2'b11)?((col_1 == size)?0:col_t+1):((row_1 == size)?0:col_t+1);
		    row_t<=(col_t == size)?((row_t == size)?0:row_t+'b1):row_t;
        end
		else begin
			col_t<=(matrix_mode == 2'b11)?((col_0 == size)?0:col_t+1):((row_0 == size)?0:col_t+1);
	    	row_t<=(col_t == size)?((row_t == size)?0:row_t+'b1):row_t;
        end
	end
end
					
	
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) C<= 0;
	else if(cs == mem_differ) begin
        case(idx[0][4])
            1:C<=(matrix_mode == 2'b01)?((row_1 == 0)?0:SUM):((col_1 == 0)?0:SUM);
            0:C<=(matrix_mode == 2'b01)?((row_0 == 0)?0:SUM):((col_0 == 0)?0:SUM);
        endcase
	end
    else if(cs == mem_same_A) C<=(matrix_mode == 2'b10)?((col_cal == 0)?0:SUM):((row_cal == 0)?0:SUM);
        
	else if(cs == mem_C) C<=(col_t == 0)?0:SUM;
end
always@(*)
begin
	if(cs == write_t || cs == write_t_same) SRAMT_D = SUM[19:0];
    else SRAMT_D = 0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) A_temp<=0;
    else if(cs == mem_same_B) A_temp<=(idx[0][4])?SRAM1_Q:SRAM0_Q;
end
always@(*)
begin
	if(cs == mem_differ || cs == write_t) begin
		A =(idx[0][4])? SRAM1_Q:SRAM0_Q;
		B =(idx[0][4])? SRAM0_Q:SRAM1_Q;
	end
	else if(cs == mem_C || cs == result_acc) begin
		A = SRAMT_Q;
		B = (idx[2][4])?SRAM1_Q:SRAM0_Q;
	end
    else if(cs == mem_same_A || cs == write_t_same) begin
        A = A_temp;
        B = (idx[0][4])?SRAM1_Q:SRAM0_Q;
    end
    else begin
        A = 0;
        B = 0;
    end
end


always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) out_temp<='b0;
	else if(cs == result_acc) out_temp<=out_temp + SUM;
    else if(cs == prepare) out_temp<=0;
end


always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) begin
		out_valid<=0;
		out_value<=0;
	end
	else if(cs == OUT) begin
		out_valid<=1;
		out_value<=out_temp;
	end
	else begin
		out_valid<=0;
		out_value<=0;
	end
end

always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) round<='b0;
	else if(cs == OUT) round<=(round == 'd9)?'b0:round+'b1;
end

always@(*)
begin
	case(cs)
		idle:ns=(in_valid)?write_0:idle;
		write_0:ns=(addr_0 == {4'b1111,size,size})?write_1:write_0;
		write_1:ns=(addr_1 == {4'b1111,size,size})?mode_wait:write_1;
        mode_wait:ns=(in_valid2)?prepare:mode_wait;
        prepare:ns=(in_valid2)?prepare:((idx[0][4] == idx[1][4])?mem_same_A:mem_differ);
        mem_differ: begin
			case(idx[0][4])
				0: ns=(matrix_mode == 2'b10)?((col_1 == size)?write_t:mem_differ):((row_1 == size)?write_t:mem_differ);
				1: ns=(matrix_mode == 2'b10)?((col_0 == size)?write_t:mem_differ):((row_0 == size)?write_t:mem_differ);
			endcase
		end
       write_t:ns=(row_t == size && col_t == size)?prepare_2:mem_differ;
       prepare_2:ns=mem_C;
       mem_same_A:ns=mem_same_B;
	   mem_same_B: ns=(matrix_mode == 2'b10)?((col_cal == size)?write_t_same:mem_same_A):((row_cal == size)?write_t_same:mem_same_A);
        write_t_same:ns=(row_t == size && col_t == size)?prepare_2:mem_same_A;
		mem_C: ns=(col_t == size)?result_acc:mem_C;
        result_acc: ns=(row_t == 0 && col_t == 0)?OUT:mem_C;
		OUT:ns=(round == 'd9)?idle:mode_wait;
        default:ns = idle;
	endcase
end
endmodule
