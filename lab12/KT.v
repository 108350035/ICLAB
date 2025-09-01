module KT(
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
    move_out
);


input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output reg out_valid;
output reg [2:0] out_x,out_y;
output reg [4:0] move_out;


reg signed [3:0] dir[0:4][0:4];
reg signed [3:0] dir_temp;


reg [2:0] state, n_state;
reg [4:0] count;
reg [4:0] step_in;
reg [2:0] prio_in;
reg [2:0] dir_num;


reg [2:0] start_x,start_y;
reg signed [3:0] current_x,current_y;
reg signed [3:0] next_x,next_y;

wire bound,nopath,done;
wire signed [3:0] diff_x,diff_y;
wire [2:0] prio_pre;
wire [7:0] dir_back;


integer i,j; 

parameter SIZE = 5;
parameter RESET = 'd0;
parameter IDLE  = 'd1;
parameter DATAIN = 'd2;
parameter NEXT_R = 'd3;
parameter RETURN = 'd4;
parameter OUTPUT = 'd5;


assign nopath  = ((current_x >= SIZE || current_x < 0)||(current_y >= SIZE || current_y < 0))? 1'b0 : (dir[current_x[2:0]][current_y[2:0]] == prio_pre)? 1'b1 : 1'b0;
assign bound   = ((next_x >= SIZE || next_x < 0)||(next_y >= SIZE || next_y < 0))? 'b1 : 'b0;
assign done    = (bound)? 'd0 : (dir[next_x[2:0]][next_y[2:0]] != -1)? 1'd1 : 1'd0;
assign diff_x = $signed({1'b0,in_x}) - current_x;
assign diff_y = $signed({1'b0,in_y}) - current_y;
assign prio_pre = (prio_in == 'd0)? 'd7 : prio_in - 'd1;


assign dir_back[0] = (current_x + 1 <  5 && current_x + 1 >=  0 && current_y - 2 >= 0 && current_y - 2 <  5)? (dir[current_x+1][current_y-2] == 0)? 1'b1 : 1'b0 : 1'b0;
assign dir_back[1] = (current_x - 1 <  5 && current_x - 1 >=  0 && current_y - 2 >= 0 && current_y - 2 <  5)? (dir[current_x-1][current_y-2] == 1)? 1'b1 : 1'b0 : 1'b0;
assign dir_back[2] = (current_x - 2 <  5 && current_x - 2 >=  0 && current_y - 1 >= 0 && current_y - 1 <  5)? (dir[current_x-2][current_y-1] == 2)? 1'b1 : 1'b0 : 1'b0;
assign dir_back[3] = (current_x - 2 <  5 && current_x - 2 >=  0 && current_y + 1 >= 0 && current_y + 1 <  5)? (dir[current_x-2][current_y+1] == 3)? 1'b1 : 1'b0 : 1'b0;
assign dir_back[4] = (current_x - 1 <  5 && current_x - 1 >=  0 && current_y + 2 >= 0 && current_y + 2 <  5)? (dir[current_x-1][current_y+2] == 4)? 1'b1 : 1'b0 : 1'b0;
assign dir_back[5] = (current_x + 1 <  5 && current_x + 1 >=  0 && current_y + 2 >= 0 && current_y + 2 <  5)? (dir[current_x+1][current_y+2] == 5)? 1'b1 : 1'b0 : 1'b0;
assign dir_back[6] = (current_x + 2 <  5 && current_x + 2 >=  0 && current_y + 1 >= 0 && current_y + 1 <  5)? (dir[current_x+2][current_y+1] == 6)? 1'b1 : 1'b0 : 1'b0;
assign dir_back[7] = (current_x + 2 <  5 && current_x + 2 >=  0 && current_y - 1 >= 0 && current_y - 1 <  5)? (dir[current_x+2][current_y-1] == 7)? 1'b1 : 1'b0 : 1'b0;

assign dir_back_test = dir_back;

//FSM current state assign
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state <= RESET;
	end
	else begin
		state <= n_state;
	end
end

//FSM next state assign
always@(*) begin
	case(state)
		RESET: begin
			n_state = IDLE;
		end
		IDLE: begin
			if(in_valid) begin
				if(move_num > 'd1) begin
					n_state = DATAIN;
				end
				else begin
					n_state = NEXT_R;
				end
			end
			else begin
				n_state = IDLE;
			end
		end
		DATAIN: begin
			if(count == step_in) begin
				n_state = NEXT_R;
			end
			else begin
				n_state = DATAIN;
			end
		
		end
		NEXT_R: begin
			if(count == 'd25) begin
				n_state = OUTPUT;
			end
			else if(nopath) begin
				n_state = RETURN;
			end
			else begin
				n_state = NEXT_R;
			end			
		end
		RETURN: begin
			n_state = NEXT_R;
		end
		OUTPUT: begin
			n_state = (count == 'd25)? IDLE : OUTPUT;
		end
		default: begin
			n_state = IDLE;
		end
	
	endcase
end

//count
always@(posedge clk) begin
	case(state)
		RESET: begin
			count <= 'b11111;
		end
		IDLE: begin
			count <= (in_valid)?(move_num > 'd1)? 'd2 : 'd1 : 'd0;
		end	
		DATAIN: begin
			count <= (count == step_in)? step_in : count + 1'd1;
		end
		NEXT_R: begin
			if(count == 'd25) begin
				count <= 'd1;
			end
			else if(done || nopath || bound) begin
				count <= count;
			end
			else begin
				count <= count + 1'b1;
			end
			
		end
		RETURN: begin
			count <= count - 'd1;
		end
		OUTPUT: begin
			count <= (count == 'd25)? 'd0 : count + 1'd1;
		end
	endcase
end


//start_x,start_y,step_in,prio_in
always@(posedge clk) begin
	case(state)
		RESET: begin
			start_x <= 'd0;
			start_y <= 'd0;
			step_in <= 'd0;
			prio_in <= 'd0;
		end
		IDLE: begin
			if(in_valid) begin
				start_x <= in_x;
				start_y <= in_y;
				step_in <= move_num;
				prio_in <= priority_num;
			end
		end	
	endcase
end

//current_x,current_y
always@(posedge clk) begin
	case(state)
		RESET: begin
			current_x <= -1;
			current_y <= -1;
		end
		IDLE: begin
			if(in_valid) begin
				current_x <= $signed({1'b0,in_x});
				current_y <= $signed({1'b0,in_y});
			end
			else begin
				current_x <= 0;
				current_y <= 0;
			end
		end
		DATAIN: begin
			if(in_valid) begin
				current_x <= $signed({1'b0,in_x});
				current_y <= $signed({1'b0,in_y});
			end
		end
		NEXT_R: begin
			if(count == 'd25) begin
				current_x <= start_x;
				current_y <= start_y;
			end			
			else if(nopath || done || bound) begin
				current_x <= current_x;
				current_y <= current_y;
			end
			else begin
				current_x <= next_x;
				current_y <= next_y;
			end
			
		end
		RETURN: begin
			current_x <= next_x;
			current_y <= next_y;
		end
		OUTPUT: begin
			current_x <= next_x;
			current_y <= next_y;
		end
	endcase
end

//dir 
always@(posedge clk) begin
	case(state)
		RESET: begin
			for(i = 0 ; i < SIZE ; i = i+1) begin
				for(j = 0 ; j < SIZE ; j = j+1) begin
					dir[i][j] <= -1;
				end
			end
		end
		IDLE: begin
			if(!in_valid) begin
				for(i = 0 ; i < SIZE ; i = i+1) begin
					for(j = 0 ; j < SIZE ; j = j+1) begin
						dir[i][j] <= -1;
					end
				end
			end
		end	
		DATAIN: begin
			dir[current_x[2:0]][current_y[2:0]] <= dir_temp;
		end
		NEXT_R: begin
			dir[current_x[2:0]][current_y[2:0]] <= $signed({1'b0,dir_num});
		end
		RETURN: begin
			dir[current_x[2:0]][current_y[2:0]] <= -1;
		end
	endcase
end

//diff_temp
always@(*) begin
	case(state)
		RESET: dir_temp = -1;
		DATAIN: begin
			if     (diff_x == -1 && diff_y ==  2) dir_temp = 0;
			else if(diff_x ==  1 && diff_y ==  2) dir_temp = 1;
			else if(diff_x ==  2 && diff_y ==  1) dir_temp = 2;
			else if(diff_x ==  2 && diff_y == -1) dir_temp = 3;
			else if(diff_x ==  1 && diff_y == -2) dir_temp = 4;
			else if(diff_x == -1 && diff_y == -2) dir_temp = 5;
			else if(diff_x == -2 && diff_y == -1) dir_temp = 6;
			else if(diff_x == -2 && diff_y ==  1) dir_temp = 7;
			else                                  dir_temp = -1;
		end
		default: dir_temp = -1;
	endcase

end

//dir_num
always@(*) begin
	case(state)
		RESET: begin
			dir_num = 0;
		end
		NEXT_R: begin
			if     (dir[current_x[2:0]][current_y[2:0]] == -1)       dir_num = prio_in;
			else    dir_num = (dir[current_x[2:0]][current_y[2:0]] == 'd7)? 'd0 : dir[current_x[2:0]][current_y[2:0]] + 1'd1;
		end
		default: begin
			dir_num = 0;
		end
	endcase

end

//next_x,next_y
always@(*) begin
	case(state)
		RESET: begin
			next_x = 0;
			next_y = 0;
		end
		NEXT_R: begin
			if(dir_num == 0) begin
				next_x = current_x - 1;
				next_y = current_y + 2;
			end
			else if(dir_num == 1) begin
				next_x = current_x + 1;
				next_y = current_y + 2;
			end
			else if(dir_num == 2) begin
				next_x = current_x + 2;
				next_y = current_y + 1;
			end
			else if(dir_num == 3) begin
				next_x = current_x + 2;
				next_y = current_y - 1;
			end
			else if(dir_num == 4) begin
				next_x = current_x + 1;
				next_y = current_y - 2;
			end
			else if(dir_num == 5) begin
				next_x = current_x - 1;
				next_y = current_y - 2;
			end
			else if(dir_num == 6) begin
				next_x = current_x - 2;
				next_y = current_y - 1;
			end
			else begin
				next_x = current_x - 2;
				next_y = current_y + 1;
			end
		end
		RETURN: begin
			if(dir_back[0]) begin
				next_x = current_x + 1;
				next_y = current_y - 2;
			end
			else if(dir_back[1]) begin
				next_x = current_x - 1;
				next_y = current_y - 2;
			end
			else if(dir_back[2]) begin
				next_x = current_x - 2;
				next_y = current_y - 1;
			end
			else if(dir_back[3]) begin
				next_x = current_x - 2;
				next_y = current_y + 1;
			end
			else if(dir_back[4]) begin
				next_x = current_x - 1;
				next_y = current_y + 2;
			end
			else if(dir_back[5]) begin
				next_x = current_x + 1;
				next_y = current_y + 2;
			end
			else if(dir_back[6]) begin
				next_x = current_x + 2;
				next_y = current_y + 1;
			end
			else begin
				next_x = current_x + 2;
				next_y = current_y - 1;
			end
		end
		OUTPUT: begin
			if(dir[current_x[2:0]][current_y[2:0]] == 0) begin
				next_x = current_x - 1;
				next_y = current_y + 2;
			end
			else if(dir[current_x[2:0]][current_y[2:0]] == 1) begin
				next_x = current_x + 1;
				next_y = current_y + 2;
			end
			else if(dir[current_x[2:0]][current_y[2:0]] == 2) begin
				next_x = current_x + 2;
				next_y = current_y + 1;
			end
			else if(dir[current_x[2:0]][current_y[2:0]] == 3) begin
				next_x = current_x + 2;
				next_y = current_y - 1;
			end
			else if(dir[current_x[2:0]][current_y[2:0]] == 4) begin
				next_x = current_x + 1;
				next_y = current_y - 2;
			end
			else if(dir[current_x[2:0]][current_y[2:0]] == 5) begin
				next_x = current_x - 1;
				next_y = current_y - 2;
			end
			else if(dir[current_x[2:0]][current_y[2:0]] == 6) begin
				next_x = current_x - 2;
				next_y = current_y - 1;
			end
			else begin
				next_x = current_x - 2;
				next_y = current_y + 1;
			end
		end
		
		default: begin
			next_x = 0;
			next_y = 0;
		end
	endcase

end

//output assign
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 'd0;
		out_x     <= 'd0;
		out_y     <= 'd0;
		move_out  <= 'd0;
	end
	else if(state == OUTPUT) begin
		out_valid <= 'd1;
		out_x     <= current_x[2:0];
		out_y     <= current_y[2:0];
		move_out  <= count;
	end
	else begin
		out_valid <= 'd0;
		out_x     <= 'd0;
		out_y     <= 'd0;
		move_out  <= 'd0;
	end
end

endmodule
