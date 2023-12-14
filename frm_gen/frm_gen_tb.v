`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2023 03:24:07 PM
// Design Name: 
// Module Name: frm_gen_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module frm_gen_tb();
    
parameter frame_width=1920;
parameter frame_height=1080;
parameter line_blank=50;
parameter frame_blank=5;

parameter CLK_PERIOD = 5;



reg pixclk;
reg rst_n;
reg en_1;
reg en_2;

wire         data_in_lval ;
wire         data_in_fval ;
wire [11:0]  pixel_counter;
wire [11:0]  line_counter ;

wire         sec_data_in_lval ;
wire         sec_data_in_fval ;
wire [11:0]  sec_pixel_counter;
wire [11:0]  sec_line_counter ;



// **********************************************************
//             init : rst_n & clk & pvci_en
// **********************************************************
initial begin
    pixclk = 1'b0;
    rst_n = 1'b0;
    en_1   = 1'b0;
    en_2   = 1'b0;
end

initial begin
    pixclk = 1'b0;
    forever
        #(CLK_PERIOD) pixclk = ~pixclk;
end

initial begin
    #10 rst_n = 1'b1;
end
// **********************************************************
//             Main logic
// **********************************************************
initial begin
    #10 en_1 = 1'b1;
    #1000 en_2 = 1'b1;
    //repeat(800) @ (posedge pixclk);
    wait (line_counter == (frame_height+frame_blank+frame_blank));
    #10000
    $finish();
end

// **********************************************************
//             UUT
// **********************************************************
frm_gen
#(
.frame_width    (frame_width ),
.frame_height   (frame_height),
.line_blank     (line_blank  ),
.frame_blank    (frame_blank )
)
UUT_grm_gen_1(
  .pixclk       ( pixclk      )              // input               
, .rst_n        ( rst_n      )               // input               
, .en           ( en_1          )              // input               

, .data_in_lval ( data_in_lval      )        // output reg          
, .data_in_fval ( data_in_fval      )        // output reg          
, .pixel_counter( pixel_counter     )        // output reg [11:0]   
, .line_counter ( line_counter      )        // output reg [11:0]   

);


frm_gen
#(
.frame_width    (frame_width ),
.frame_height   (frame_height),
.line_blank     (line_blank  ),
.frame_blank    (frame_blank )
)
UUT_grm_gen_2(
  .pixclk       ( pixclk      )              // input               
, .rst_n        ( rst_n      )               // input               
, .en           ( en_2          )              // input               

, .data_in_lval ( sec_data_in_lval      )        // output reg          
, .data_in_fval ( sec_data_in_fval      )        // output reg          
, .pixel_counter( sec_pixel_counter     )        // output reg [11:0]   
, .line_counter ( sec_line_counter      )        // output reg [11:0]   

);


endmodule
