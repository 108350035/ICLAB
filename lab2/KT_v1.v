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
//***************************************************//
// reg and wire and parameter
// *************************************************//
parameter [2:0] CHECK_2=3'd0,IDLE=3'd1,MOVE_INPUT=3'd2,MOVE_OUTPUT=3'd3,
			    TOUR=3'd4,RESET=3'd5,CHECK=3'd6;
reg [2:0] cs,ns;
reg [2:0] direction,dir_cur;
reg [2:0] temp_x [25:1];
reg [2:0] temp_y [25:1];
reg [4:0] cnt,cnt_move;
reg [4:0] board [0:4];
reg [2:0] cnt_curr [25:1];
wire [2:0] dir;
assign dir=direction+3'd7;
//FSM current state assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cs <= RESET;
	end
	else begin
		cs <= ns;
	end
end

//FSM next state assignment
always@(*) begin
	case(cs)
            RESET:ns=IDLE;

	    	IDLE: ns=(in_valid)?MOVE_INPUT:IDLE;
		
	    	MOVE_INPUT: ns=(in_valid)?MOVE_INPUT:TOUR;

	    	TOUR: begin 
                    if(cnt_move==5'd25) ns = MOVE_OUTPUT;
                    else begin case(dir_cur)
                     3'd0: ns=(temp_y[cnt_move]<=3'd2&&temp_x[cnt_move]>=3'b1)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
					 3'd1: ns=(temp_y[cnt_move]<=3'd2&&temp_x[cnt_move]<=3'd3)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
					 3'd2: ns=(temp_y[cnt_move]<=3'd3&&temp_x[cnt_move]<=3'd2)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
					 3'd3: ns=(temp_y[cnt_move]>=3'd1&&temp_x[cnt_move]<=3'd2)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
					 3'd4: ns=(temp_y[cnt_move]>=3'd2&&temp_x[cnt_move]<=3'd3)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
					 3'd5: ns=(temp_y[cnt_move]>=3'd2&&temp_x[cnt_move]>=3'd1)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
					 3'd6: ns=(temp_y[cnt_move]>=3'd1&&temp_x[cnt_move]>=3'd2)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
					 3'd7: ns=(temp_y[cnt_move]<=3'd3&&temp_x[cnt_move]>=3'd2)?CHECK:((dir_cur==dir)?CHECK_2:TOUR);
                     default:ns=TOUR;
                endcase
            end
        end

        CHECK: if(!board[temp_x[cnt_move+5'b1]][temp_y[cnt_move+5'b1]]) ns=TOUR;
               else ns=(dir_cur==direction)?CHECK_2:TOUR;

        CHECK_2: if(cnt_curr[cnt_move-5'b1]==direction) ns = CHECK_2;
                 else ns = TOUR;
                    

        MOVE_OUTPUT:if (cnt==5'd25) ns =RESET;
                        else ns=MOVE_OUTPUT;

            default: ns=TOUR;
        endcase
                    
    end


//Output assignment
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        move_out <= 5'b0;
        out_valid <= 1'b0;
        out_x <= 3'b0;
        out_y <= 3'b0;
    end
    else begin case(cs)
        RESET: begin
            out_valid <= 1'b0;
            move_out <= 5'b0;
            out_x <= 3'b0;
            out_y <= 3'b0;
        end

        MOVE_OUTPUT: begin
                out_valid <= 1'b1;
                move_out <= cnt;
                out_x <= temp_x[cnt];
                out_y <= temp_y[cnt];
            end
        endcase
    end
end


//reg  assignment
always@(posedge clk or negedge rst_n) begin
     if(!rst_n) begin
         cnt <= 5'b1;
         cnt_move<=5'b0;
         direction<=3'd0;
    end
    else begin case(cs)
        RESET: cnt <= 5'b1;

        IDLE: if(in_valid) begin
                cnt <= cnt+5'b1;
                cnt_move <= move_num;
                direction <= priority_num;
            end 

        MOVE_INPUT: if(in_valid) cnt <= cnt+5'b1;
                    else begin
                        dir_cur<=direction;
                        cnt<=5'b1;;
                        cnt_curr[cnt_move]<=direction;
                    end

        TOUR: dir_cur<=dir_cur+3'd1;

        CHECK: if(!board[temp_x[cnt_move+5'b1]][temp_y[cnt_move+5'b1]]) begin
                cnt_curr[cnt_move] <= dir_cur; 
                cnt_move<=cnt_move+5'b1;
                dir_cur<=direction;
            end 

        CHECK_2: begin
                cnt_move<=cnt_move-5'b1;
                dir_cur<=(cnt_curr[cnt_move-5'b1] == direction)?dir_cur:cnt_curr[cnt_move-5'b1];
            end

        MOVE_OUTPUT: cnt <= cnt+5'b1;

        endcase
    end
end

//reg assignment
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        board[4] <= 5'b0;
        board[3] <= 5'b0;
        board[2] <= 5'b0;
        board[1] <= 5'b0;
        board[0] <= 5'b0;
    end else begin case(cs)
        RESET: if(!in_valid) begin
                board[4] <= 5'b0;
                board[3] <= 5'b0;
                board[2] <= 5'b0;
                board[1] <= 5'b0;
                board[0] <= 5'b0;
        end

        CHECK: if(!board[temp_x[cnt_move+5'b1]][temp_y[cnt_move+5'b1]])
                board[temp_x[cnt_move+5'b1]][temp_y[cnt_move+5'b1]]<=1'b1;
        
        IDLE: if(in_valid) board[in_x][in_y]<=1'b1;

        CHECK_2: board[temp_x[cnt_move]][temp_y[cnt_move]]<=1'b0;

        MOVE_INPUT: if(in_valid) board[in_x][in_y]<=1'b1;
        
        endcase
    end
end

//input and reg assignment
integer i;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 1;i < 26;i = i + 1) begin:loop
            temp_x[i] <= 3'b0;
            temp_y[i] <= 3'b0;
        end
    end
        else begin case(cs)
            
            IDLE: if(in_valid) begin
		            temp_x[cnt] <= in_x;
                    temp_y[cnt] <= in_y;
            end

            MOVE_INPUT: if(in_valid) begin
		                    temp_x[cnt] <= in_x;
                            temp_y[cnt] <= in_y;
                     end 

            TOUR: if (cnt_move < 25) begin
                    case(dir_cur)
                     3'd0://方向0，檢查有無出界及走過。如果有，則狀態不變，方向切換至1
                        if(temp_y[cnt_move]<=3'd2 && temp_x[cnt_move]>=3'b1) begin
                          temp_y[cnt_move+5'b1] <= temp_y[cnt_move]+3'd2;
                          temp_x[cnt_move+5'b1] <= temp_x[cnt_move]-3'd1;
                end
            

					 3'd1: 
                        if(temp_y[cnt_move]<=3'd2&&temp_x[cnt_move]<=3'd3) begin
                            temp_y[cnt_move+5'b1] <= temp_y[cnt_move]+3'd2;
                            temp_x[cnt_move+5'b1] <= temp_x[cnt_move]+3'd1;
                end

					 3'd2: 
                        if(temp_y[cnt_move]<=3'd3&&temp_x[cnt_move]<=3'd2) begin
                            temp_y[cnt_move+5'b1] <= temp_y[cnt_move]+3'd1;
                            temp_x[cnt_move+5'b1] <= temp_x[cnt_move]+3'd2;
                end
                            
					 3'd3: 
                        if(temp_y[cnt_move]>=3'd1&&temp_x[cnt_move]<=3'd2) begin
                            temp_y[cnt_move+5'b1] <= temp_y[cnt_move]-3'd1;
                            temp_x[cnt_move+5'b1] <= temp_x[cnt_move]+3'd2;
                end

                        
					 3'd4: 
                        if(temp_y[cnt_move]>=3'd2&&temp_x[cnt_move]<=3'd3) begin
                            temp_y[cnt_move+5'b1] <= temp_y[cnt_move]-3'd2;
                            temp_x[cnt_move+5'b1] <= temp_x[cnt_move]+3'd1;
                end
                        
					 3'd5: 
                        if(temp_y[cnt_move]>=3'd2&&temp_x[cnt_move]>=3'd1) begin
                            temp_y[cnt_move+5'b1] <= temp_y[cnt_move]-3'd2;
                            temp_x[cnt_move+5'b1] <= temp_x[cnt_move]-3'd1;
                end

					 3'd6: 
                        if(temp_y[cnt_move]>=3'd1&&temp_x[cnt_move]>=3'd2) begin
                            temp_y[cnt_move+5'b1] <= temp_y[cnt_move]-3'd1;
                            temp_x[cnt_move+5'b1] <= temp_x[cnt_move]-3'd2;
                end
					 3'd7: 
                        if(temp_y[cnt_move]<=3'd3&&temp_x[cnt_move]>=3'd2) begin
                            temp_y[cnt_move+5'b1] <= temp_y[cnt_move]+3'd1;
                            temp_x[cnt_move+5'b1] <= temp_x[cnt_move]-3'd2;
                end
                
                endcase
            end


        endcase
    end
    
end
            
endmodule