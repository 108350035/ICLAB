module CLK_1_MODULE(// Input signals
			clk_1,
			clk_2,
			in_valid,
			rst_n,
			message,
			mode,
			CRC,
			// Output signals
			clk1_0_message,
			clk1_1_message,
			clk1_CRC,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0,
			clk1_flag_1,
			clk1_flag_2,
			clk1_flag_3,
			clk1_flag_4,
			clk1_flag_5,
			clk1_flag_6,
			clk1_flag_7,
			clk1_flag_8,
			clk1_flag_9
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_1; 
input clk_2;	
input rst_n;
input in_valid;
input[59:0]message;
input CRC;
input mode;

output reg [59:0] clk1_0_message;
output reg [59:0] clk1_1_message;
output reg clk1_CRC;
output reg clk1_mode;
output reg [9 :0] clk1_control_signal;
output clk1_flag_0;
output clk1_flag_1;
output clk1_flag_2;
output clk1_flag_3;
output clk1_flag_4;
output clk1_flag_5;
output clk1_flag_6;
output clk1_flag_7;
output clk1_flag_8;
output clk1_flag_9;

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------


reg [59:0] message_temp;

syn_XOR(.IN(in_valid) ,.OUT(clk1_flag_9) ,.TX_CLK(clk_1) ,.RX_CLK(clk_2) ,.RST_N(rst_n));

always@(*)
begin
    if(in_valid) begin
        case({mode,CRC})
            2'b00: message_temp = {message[51:0],8'b0};
            2'b01: message_temp = {message[54:0],5'b0};
            default: message_temp = message;
        endcase
    end
    else message_temp = 0;
end

always@(posedge clk_1,negedge rst_n)
begin
    if(!rst_n) begin
                clk1_0_message<=0;
            end
    else if(in_valid) clk1_0_message<=message_temp;
end

always@(posedge clk_1,negedge rst_n)
begin
    if(!rst_n) begin
            clk1_CRC<=0;
            clk1_mode<=0;
        end
    else if(in_valid) begin
            clk1_CRC<=CRC;
            clk1_mode<=mode;
        end
end


endmodule


module CLK_2_MODULE(// Input signals
			clk_2,
			clk_3,
			rst_n,
			clk1_0_message,
			clk1_1_message,
			clk1_CRC,
			clk1_mode,
			clk1_control_signal,
			clk1_flag_0,
			clk1_flag_1,
			clk1_flag_2,
			clk1_flag_3,
			clk1_flag_4,
			clk1_flag_5,
			clk1_flag_6,
			clk1_flag_7,
			clk1_flag_8,
			clk1_flag_9,
			
			// Output signals
			clk2_0_out,
			clk2_1_out,
			clk2_CRC,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0,
			clk2_flag_1,
			clk2_flag_2,
			clk2_flag_3,
			clk2_flag_4,
			clk2_flag_5,
			clk2_flag_6,
			clk2_flag_7,
			clk2_flag_8,
			clk2_flag_9
		  
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_2;	
input clk_3;	
input rst_n;

input [59:0] clk1_0_message;
input [59:0] clk1_1_message;
input clk1_CRC;
input clk1_mode;
input [9  :0] clk1_control_signal;
input clk1_flag_0;
input clk1_flag_1;
input clk1_flag_2;
input clk1_flag_3;
input clk1_flag_4;
input clk1_flag_5;
input clk1_flag_6;
input clk1_flag_7;
input clk1_flag_8;
input clk1_flag_9;


output reg [59:0] clk2_0_out;
output reg [59:0] clk2_1_out;
output reg clk2_CRC;
output reg clk2_mode;
output reg [9  :0] clk2_control_signal;
output clk2_flag_0;
output clk2_flag_1;
output clk2_flag_2;
output clk2_flag_3;
output clk2_flag_4;
output clk2_flag_5;
output clk2_flag_6;
output clk2_flag_7;
output clk2_flag_8;
output clk2_flag_9;


//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------

localparam [1:0] receive=2'd0,cal=2'd1,transfer=2'd3;
reg [1:0] cs,ns;
reg [5:0] cnt;
wire flag;
reg [59:0] message_temp,message_temp2;
wire [8:0] a,b;
assign a = 9'b101011000 ^ message_temp[59:51];
assign b = 9'b100110001 ^ message_temp2[59:51];
assign flag = (cs == transfer)?1:0;
syn_XOR(.IN(flag) ,.OUT(clk2_flag_9) ,.TX_CLK(clk_2) ,.RX_CLK(clk_3) ,.RST_N(rst_n));


always@(posedge clk_2,negedge rst_n)
begin
    if(!rst_n) cs<=receive;
    else cs<=ns;
end

always@(posedge clk_2)
begin
    if(clk1_flag_9) begin
        message_temp2<=clk1_0_message;
    end
    else message_temp2<=(message_temp2[59])?{b[7:0],message_temp2[50:0],1'b0}:message_temp2<<1;
end

always@(posedge clk_2)
begin
    if(clk1_flag_9) begin
        message_temp<=clk1_0_message;
    end
    else message_temp<=(message_temp[59])?{a[7:3],message_temp[53:0],1'b0}:message_temp<<1;
end


always@(posedge clk_2,negedge rst_n)
begin
    if(!rst_n) cnt<=59;
    else if(cs == cal) cnt<=cnt-1;
    else if(cs == transfer) cnt<=59;
end


always@(*)
begin
    case(cs)
        receive:ns=(clk1_flag_9)?cal:receive;
        cal:if(clk1_CRC) ns=(cnt == 5)?transfer:cal;
            else ns=(cnt == 8)?transfer:cal;
        transfer:ns=receive;
        default:ns=receive;
    endcase
end

always@(posedge clk_2,negedge rst_n)
begin
    if(!rst_n) begin
        clk2_CRC<=0;
        clk2_mode<=0;
    end
    else if(clk1_flag_9) begin
        clk2_CRC<=clk1_CRC;
        clk2_mode<=clk1_mode;
    end
end

always@(posedge clk_2,negedge rst_n)
begin
    if(!rst_n) clk2_0_out<=0;
    else if(cs == transfer) clk2_0_out<=(clk1_CRC)?message_temp:message_temp2;
end

always@(posedge clk_2,negedge rst_n)
begin
    if(!rst_n) clk2_1_out<=0;
    else if(clk1_flag_9) clk2_1_out<=clk1_0_message;
end


endmodule



module CLK_3_MODULE(// Input signals
			clk_3,
			rst_n,
			clk2_0_out,
			clk2_1_out,
			clk2_CRC,
			clk2_mode,
			clk2_control_signal,
			clk2_flag_0,
			clk2_flag_1,
			clk2_flag_2,
			clk2_flag_3,
			clk2_flag_4,
			clk2_flag_5,
			clk2_flag_6,
			clk2_flag_7,
			clk2_flag_8,
			clk2_flag_9,
			
			// Output signals
			out_valid,
			out
		  
			);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------			
input clk_3;	
input rst_n;

input [59:0] clk2_0_out;
input [59:0] clk2_1_out;
input clk2_CRC;
input clk2_mode;
input [9  :0] clk2_control_signal;
input clk2_flag_0;
input clk2_flag_1;
input clk2_flag_2;
input clk2_flag_3;
input clk2_flag_4;
input clk2_flag_5;
input clk2_flag_6;
input clk2_flag_7;
input clk2_flag_8;
input clk2_flag_9;

output reg out_valid;
output reg [59:0]out;

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
wire [59:0] message_temp;

assign message_temp = (clk2_mode)?((clk2_0_out[59:51] == 0)?0:60'hfffffffffffffff):((clk2_CRC)?{clk2_1_out[59:5],clk2_0_out[59:55]}:{clk2_1_out[59:8],clk2_0_out[59:52]});

always@(posedge clk_3,negedge rst_n)
begin
    if(!rst_n) begin
        out_valid<=0;
        out<=0;
    end
    else if(clk2_flag_9) begin
        out_valid<=1;
        out<=message_temp;
    end
    else begin
        out_valid<=0;
        out<=0;
    end
end




endmodule


