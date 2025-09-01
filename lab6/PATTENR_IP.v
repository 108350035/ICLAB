//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//      (C) Copyright Optimum Application-Specific Integrated System Laboratory
//      All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : PATTERN_IP.v
//   	Module Name : PATTERN_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`ifdef RTL
    `define CYCLE_TIME 60.0
`endif

`ifdef GATE
    `define CYCLE_TIME 60.0
`endif

module PATTERN_IP #(parameter IP_WIDTH = 6) (
    // Output signals
    IN_1, IN_2,
    // Input signals
    OUT_INV
);



// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg[IP_WIDTH-1:0] IN_1, IN_2;
input  [IP_WIDTH-1:0] OUT_INV;

reg [IP_WIDTH-1:0] a,b,c;
integer patcount,y,z;
parameter PATNUM = (IP_WIDTH == 5) ? 500 : ((IP_WIDTH == 6) ? 1000 : 1500);
//---------------------------------------------------------------------
//   Main Program
//---------------------------------------------------------------------

initial begin
    case(IP_WIDTH)
        5:z =$fopen("test5.txt","r");
        6:z =$fopen("test6.txt","r");
        7:z =$fopen("test7.txt","r");
    endcase
    #6;
    $display("Start Testbench of PATTERN_IP with IP_WIDTH = %d",IP_WIDTH);
    for(patcount = 0;patcount < PATNUM;patcount = patcount + 1) begin
        input_task;
        compare;
        #6;
    end
    #3;
    pass_task;
    #3;
    $finish;
end




task input_task;
begin
    y = $fscanf(z,"%d %d %d",a,b,c);
    #1;
    IN_1 = a;
    IN_2 = b;
    #58;
end
endtask

task compare;
begin
    if(c != OUT_INV) begin
            $display("************************************************************");
            $display("*                       LAB06_FAIL                         *");
            $display("*                    Test Case incorrect!                  *");
            $display("************************************************************");
            $display("%d(%b), %d(%b) = %d(%b)",a,a,b,b,c,c);
            $display("Your wrong answer: %d(%b)",OUT_INV, OUT_INV);
            #1;
            $finish;
        end
    else begin
            $display("Pass testcase %04d: (%03d, %03d)",patcount, a, b);
        end
        #2;
end
endtask


                
    
task pass_task; 
begin
  $display ("--------------------------------------------------------------------");
  $display ("          ~(￣▽￣)~(＿△＿)~(￣▽￣)~(＿△＿)~(￣▽￣)~           			 ");
  $display ("                         Congratulations!                           ");
  $display ("                  You have passed all patterns for IP_WIDTH = %d   ",IP_WIDTH);
  $display ("--------------------------------------------------------------------");       
  $finish;
end
endtask

endmodule