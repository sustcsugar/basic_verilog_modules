`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2023 10:26:33 AM
// Design Name: 
// Module Name: dual_sync_fifo_tb.v
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


module dual_sync_fifo_tb();



parameter CLK_PERIOD = 5;
parameter DEPTH  = 8191;
parameter AWIDTH = 13;
parameter DWIDTH = 8;
parameter CWIDTH = 13;

parameter frame_width=640;
parameter frame_height=480;
parameter line_blank=20;
parameter frame_blank=1;

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

wire        o_pixclk     ;
wire        o_image_hs   ;
wire        o_image_vs   ;
wire        o_image_valid;
wire [15:0] o_image_data ;

// **********************************************************
//             init : rst_n & clk & pvci_en
// **********************************************************
initial begin
    pixclk = 1'b0;
    rst_n = 1'b0;
end
initial begin
    pixclk <= 1'b0;
    forever
        #(CLK_PERIOD) pixclk <= ~pixclk;
end
initial begin
    #10 rst_n = 1'b1;
end

// **********************************************************
//             Main logic
// **********************************************************
initial begin
    en_1=1'b0;
    en_2=1'b0;
    
    #10 en_2 = 1'b1;
    repeat(6000) @ (posedge pixclk);
    en_1 = 1'b1;
    
    #100000000 $finish();
end

// **********************************************************
//             UUT
// **********************************************************
wire [7:0] image1_data;
wire [7:0] image2_data;
assign  image1_data = (    data_in_lval&    data_in_fval)?    pixel_counter[7:0]:0;
assign  image2_data = (sec_data_in_lval&sec_data_in_fval)?sec_pixel_counter[7:0]:0;

dual_sync_fifo
#(
    .DEPTH   (  DEPTH ) ,
    .AWIDTH  ( AWIDTH ),
    .DWIDTH  ( DWIDTH ),
    .CWIDTH  ( CWIDTH )
)
UUT_sync_fifo
(
      .rst_n        (  rst_n          )      // input           
      
    , .pixclk1      (  pixclk                 )      // input           
    , .image1_hs    (  data_in_lval&data_in_fval           )      // input           
    , .image1_vs    (  data_in_fval           )      // input           
    , .image1_valid (  data_in_lval&data_in_fval           )      // input           
    , .image1_data  (  image1_data     )      // input   [7:0]   
      
    , .pixclk2      (   pixclk                )      // input           
    , .image2_hs    (   sec_data_in_lval&sec_data_in_fval      )      // input           
    , .image2_vs    (   sec_data_in_fval      )      // input           
    , .image2_valid (   sec_data_in_lval&sec_data_in_fval      )      // input           
    , .image2_data  (   image2_data)      // input   [7:0]   
      
    , .o_pixclk     (   o_pixclk              )      // output          
    , .o_image_hs   (   o_image_hs            )      // output          
    , .o_image_vs   (   o_image_vs            )      // output          
    , .o_image_valid(   o_image_valid         )      // output          
    , .o_image_data (   o_image_data          )      // output  [15:0]  

);
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
, .en           ( en_1          )            // input               

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
UUT_frm_gen_2(
  .pixclk       ( pixclk      )              // input               
, .rst_n        ( rst_n       )              // input               
, .en           ( en_2        )              // input               

, .data_in_lval ( sec_data_in_lval      )    // output reg          
, .data_in_fval ( sec_data_in_fval      )    // output reg          
, .pixel_counter( sec_pixel_counter     )    // output reg [11:0]   
, .line_counter ( sec_line_counter      )    // output reg [11:0]   

);

reg data_in_fval_dly,sec_data_in_fval_dly;

always @ (posedge pixclk or negedge rst_n) begin
    if (~rst_n) begin
            data_in_fval_dly <= 1'b0;
        sec_data_in_fval_dly <= 1'b0;
    end else begin
            data_in_fval_dly <=     data_in_fval;
        sec_data_in_fval_dly <= sec_data_in_fval;
    end
end


endmodule
