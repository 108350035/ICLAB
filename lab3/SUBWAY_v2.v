module SUBWAY(
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    out_valid,
    out
);


input clk, rst_n;
input in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 
output reg       out_valid;
output reg [1:0] out;


//==============================================//
//       parameter & register declaration       //
//==============================================//
integer i,j;
parameter idle=1'b0,MOVE_INPUT=1'b1;
parameter [1:0] road=2'd0,lo_obstacle=2'd1,hi_obstacle=2'd2,train=2'd3;
parameter [1:0] forward=2'd0,right=2'd1,left=2'd2,jump=2'd3;
reg  cs,ns;
reg [1:0] curr_row;
reg [6:0] cnt;
reg [5:0] cnt_out;
reg [1:0] map [3:0] [3:0];
reg [1:0] temp_out [0:62];
//==============================================//
//       parameter & register declaration       //
//==============================================//
//=============state transfer==================///
always@(posedge clk,negedge rst_n)
begin
        if(!rst_n) cs<=idle;
        else cs<=ns;
end

//=============ns===============================///
always@(*)
begin
	case(cs)
		
		idle:ns=(cnt==7'd63)?MOVE_INPUT:idle;
		MOVE_INPUT:ns=(cnt_out==6'd62)?idle:MOVE_INPUT;
	endcase
end
	 
//============map==============================///
always@(posedge clk,negedge rst_n)
begin
		if(!rst_n) begin
			for(i=0;i<4;i=i+1) begin
				for(j=0;j<4;j=j+1) 
					map[i][j]<=2'b00;
			end
		end
		else if(in_valid) begin 
			map[3][0]<=in0;
			map[3][1]<=in1;
			map[3][2]<=in2;
			map[3][3]<=in3;
			
			for(i=0;i<3;i=i+1) begin  
				for(j=0;j<4;j=j+1)
					map[i][j]<=map[i+1][j];
			end
		end
		else begin
			for(i=0;i<3;i=i+1) begin  
				for(j=0;j<4;j=j+1)
					map[i][j]<=map[i+1][j];
			end
		end
		
end
//==============cnt==============//
always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) cnt<=7'd0;
	else if((in_valid) || cnt>7'd62) cnt<=cnt+7'b1;
	else cnt<=7'b0;
end

always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) cnt_out<=6'd0;
    else if(cs==MOVE_INPUT) cnt_out<=cnt_out+6'b1;
    else cnt_out<=0;
end



always@(posedge clk,negedge rst_n)
begin
	if(!rst_n) begin
			for(i=0;i<63;i=i+1) 
				temp_out[i]<=2'b0;
				curr_row<=2'b00;
		end
	else if(cnt==7'd0) curr_row<=init;
	else if(cnt[0]==1'b0) begin
		if(map[2][curr_row]==lo_obstacle) begin
			if(curr_row>2'd1 && map[2][curr_row-2'd1]==road) begin
					curr_row<=curr_row-2'd1;
					temp_out[cnt-7'd3]<=left;
				end
			else if(curr_row<2'd2 && map[2][curr_row+2'd1]==road) begin
					curr_row<=curr_row+2'd1;
					temp_out[cnt-7'd3]<=right;
				end
			else temp_out[cnt-7'd3]<=jump;
			end
		else if(map[2][curr_row]==train) begin
                if(curr_row<2'd2) begin
				    if(map[2][curr_row+2'd1]==road) begin
					    curr_row<=curr_row+2'd1;
					    temp_out[cnt-7'd3]<=right;
				    end
                    else begin
                        curr_row<=curr_row-2'd1;
					    temp_out[cnt-7'd3]<=left;
				    end
                end
				else if(map[2][curr_row-2'd1]==road) begin
					curr_row<=curr_row-2'd1;
					temp_out[cnt-7'd3]<=left;
				end
		        else begin
                    curr_row<=curr_row+2'd1;
					temp_out[cnt-7'd3]<=right;
				end
            end
        else temp_out[cnt-7'd3]<=forward;
	end
	else if(cnt>7'd2&&cnt[0]==1'b1) begin
			if(map[3][curr_row]==train) begin
                    if(curr_row==2'd0) begin
					    curr_row<=(map[3][curr_row+2'd1]==train)?curr_row+2'd1:curr_row;
					    temp_out[cnt-7'd3]<=(map[3][curr_row+2'd1]==train)?right:forward;
				    end
                    else if(curr_row==2'd1) begin
                        temp_out[cnt-7'd3]<=(map[3][curr_row+2'd1]==train)?((map[3][curr_row-2'd1]==train)?right:left):forward;
                        curr_row<=(map[3][curr_row+2'd1]==train)?((map[3][curr_row-2'd1]==train)?curr_row+2'd1:curr_row-2'b1):curr_row;
                    end
                    else if(curr_row==2'd2) begin
                        temp_out[cnt-7'd3]<=(map[3][curr_row+2'd1]==train)?left:forward;
                        curr_row<=(map[3][curr_row+2'd1]==train)?curr_row-2'd1:curr_row;
                    end
                    else if(curr_row==2'd3) begin
					    curr_row<=(map[3][curr_row-2'd1]==train)?curr_row-2'd1:curr_row;
					    temp_out[cnt-7'd3]<=(map[3][curr_row-2'd1]==train)?left:forward;
				    end
                end
            else begin
                    if(curr_row<2'd1 && map[2][curr_row+2'd1]==road) begin
					    curr_row<=curr_row+2'd1;
					    temp_out[cnt-7'd3]<=right;
				    end
                    else if(curr_row>2'd2 && map[2][curr_row-2'd1]==road) begin
					    curr_row<=curr_row-2'd1;
					    temp_out[cnt-7'd3]<=left;
				    end
                    else temp_out[cnt-7'd3]<=forward;
			    end
		    end
end

//=================output assignment=====//
always@(posedge clk,negedge rst_n)
begin
		if(!rst_n) begin
			out<=2'b0;
			out_valid<=1'b0;
		end
		else if(cs==MOVE_INPUT) begin
			out<=temp_out[cnt_out];
			out_valid<=1'b1;
		end
		else begin
            out_valid<=1'b0;
            out<=2'b0;
        end
end
				
			
					
						
			
endmodule



