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

parameter [1:0] IDLE=2'd0,INPUT=2'd1,TOUR=2'd2,OUTPUT=2'd3;
integer i;
reg [1:0] cs,ns;
reg [2:0] temp_x,temp_y,direction,pri;
reg [2:0] x [24:0],y [24:0];
reg [4:0] cnt,cnt_out;
reg [24:0] valid;
wire signed [3:0] pre_x,pre_y;
wire [2:0] pre_direction;
reg [7:0] have_tried_direction [24:0];
wire can_try;

assign can_try = ~(&have_tried_direction[cnt]);
assign pre_x = x[cnt-1] - x[cnt-2];
assign pre_y = y[cnt-1] - y[cnt-2];
assign pre_direction = (pre_x == -1 && pre_y == 2)?3'd0:(
                       (pre_x == 1 && pre_y == 2)?3'd1:
                       (pre_x == 2 && pre_y == 1)?3'd2:
                       (pre_x == 2 && pre_y == -1)?3'd3:
                       (pre_x == 1 && pre_y == -2)?3'd4:
                       (pre_x == -1 && pre_y == -2)?3'd5:
                       (pre_x == -2 && pre_y == -1)?3'd6:
                       (pre_x == -2 && pre_y == 1)?3'd7:3'd0);


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cnt_out<=0;
    else if(cs == OUTPUT) cnt_out<=cnt_out+1;
    else cnt_out<=0;
end


always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cnt<=0;
    else if(in_valid) cnt<=cnt+1;
    else if(cs == TOUR) begin
        if(&valid && can_try) cnt<=cnt+1;
        else if(can_try == 0 || direction + 3'd1 == pri) cnt<=cnt-1;
    end
    else if(cs == IDLE) cnt<=0;
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) cs<=IDLE;
    else cs<=ns;
end

always@(*)
begin
    case(cs)
        IDLE:ns=(in_valid)?INPUT:IDLE;
        INPUT:ns=(in_valid)?INPUT:TOUR;
        TOUR:ns=(cnt == 25)?OUTPUT:TOUR;
        OUTPUT:ns=(cnt_out == 24)?IDLE:OUTPUT;
    endcase
end



always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        out_x<=0;
        out_y<=0;
        out_valid<=0;
        move_out<=0;
    end
    else if(cs == OUTPUT) begin
        out_x<=x[cnt_out];
        out_y<=y[cnt_out];
        out_valid<=1;
        move_out<=cnt_out+1;
    end
    else begin
        out_x<=0;
        out_y<=0;
        out_valid<=0;
        move_out<=0;
    end
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
        pri<=0;
        direction<=0;
    end
    else if(cs == IDLE) begin
        pri<=(in_valid)?priority_num:0;
        direction<=(in_valid)?priority_num:0;
    end
    else if(cs == TOUR) begin
        if(&valid & can_try) direction<=pri;
        else if(can_try == 0 || direction +3'd1 == pri) direction<=pre_direction+1;
        else direction<=direction+1;
    end
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
            for(i=0;i<25;i=i+1) begin
                x[i]<=7;
                y[i]<=7;
        end
    end
    else if(cs == OUTPUT) begin
            x[cnt_out]<=7;
            y[cnt_out]<=7;
    end
    else if(in_valid) begin
        x[cnt]<=in_x;
        y[cnt]<=in_y;
    end
    else if(cs == TOUR && cnt < 25) begin
        if(&valid & can_try) begin
            x[cnt]<=temp_x;
            y[cnt]<=temp_y;
        end
        else if(can_try == 0 || direction + 3'd1 == pri) begin
            x[cnt-1]<=5;
            y[cnt-1]<=7;
        end

    end
end


genvar k;
generate
    for(k=0;k<25;k=k+1) begin:valid_loop
        always@(*) begin
            if(temp_x >=0 && temp_x <= 4 && temp_y >=0 && temp_y <= 4) begin
                if(temp_x == x[k] && temp_y == y[k]) valid[k]=0;
                else valid[k] = 1;
            end
            else valid[k] = 0;
        end
    end
endgenerate

always@(*)
begin
    case(direction)
        3'd0:begin
            temp_x = x[cnt-1] - 1;
            temp_y = y[cnt-1] + 2;
        end

        3'd1:begin
            temp_x = x[cnt-1] + 1;
            temp_y = y[cnt-1] + 2;
        end

        3'd2:begin
            temp_x = x[cnt-1] + 2;
            temp_y = y[cnt-1] + 1;
        end

        3'd3:begin
            temp_x = x[cnt-1] + 2;
            temp_y = y[cnt-1] - 1;
        end

        3'd4:begin
            temp_x = x[cnt-1] + 1;
            temp_y = y[cnt-1] - 2;
        end

        3'd5:begin
            temp_x = x[cnt-1] - 1;
            temp_y = y[cnt-1] - 2;
        end

        3'd6:begin
            temp_x = x[cnt-1] - 2;
            temp_y = y[cnt-1] - 1;
        end

        3'd7:begin
            temp_x = x[cnt-1] - 2;
            temp_y = y[cnt-1] + 1;
        end
    endcase
end

always@(posedge clk,negedge rst_n)
begin
    if(!rst_n) begin
            for(i=0;i<25;i=i+1) begin
                have_tried_direction[i]<=0;
            end
    end
    else if(cs == OUTPUT) begin
            have_tried_direction[cnt_out]<=0;
    end
    else if(cs == TOUR) begin
        if(&valid && can_try) have_tried_direction[cnt][direction]<=1;
        else if(can_try == 0 || pri == direction + 3'd1) have_tried_direction[cnt]<=0;
        else have_tried_direction[cnt][direction]<=1;
    end
end



endmodule
