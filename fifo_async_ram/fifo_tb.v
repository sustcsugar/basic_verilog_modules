`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2023 10:26:33 AM
// Design Name: 
// Module Name: fifo_tb
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


module fifo_tb();



parameter CLK_PERIOD = 5;
parameter AWIDTH = 12;
parameter DWIDTH = 8;
parameter CWIDTH = 8;


reg pixclk;
reg rst_n;

wire ram_wclk;
wire ram_rclk;
reg [DWIDTH-1:0] wdata;
wire [DWIDTH-1:0] rdata;
reg ram_wen_req;
reg ram_ren;

wire push_overflow    ;
wire [CWIDTH-1:0] push_word_count  ;
wire ram_we_n          ;
wire [AWIDTH-1:0]ram_waddr        ;
wire pop_empty      ;
wire elast_underflow;
wire [AWIDTH-1:0]ram_raddr      ;


// **********************************************************
//             init : rst_n & clk & pvci_en
// **********************************************************
initial begin
    pixclk = 1'b0;
    rst_n = 1'b0;
    wdata = 0;
end
initial begin
    pixclk <= 1'b0;
    forever
        #(CLK_PERIOD) pixclk <= ~pixclk;
end
initial begin
    #10 rst_n = 1'b1;
end

assign ram_wclk=pixclk;
assign ram_rclk=pixclk;




// **********************************************************
//             read write tasks
// **********************************************************
task write;
begin
    @(posedge pixclk)
    ram_wen_req <= 1'b1;
    @(posedge pixclk)
    ram_wen_req <= 1'b0;
end
endtask

task read;
begin
    @(posedge pixclk)
    ram_ren <= 1'b1;
    @(posedge pixclk)
    ram_ren <= 1'b0;
end
endtask


task read_write;
begin
    @(posedge pixclk)
    ram_ren <= 1'b1;
    ram_wen_req <= 1'b1;
    wdata <= wdata + 1;
end
endtask

// **********************************************************
//             Main logic
// **********************************************************

always @ (posedge pixclk or negedge rst_n) begin
    if (~rst_n) 
        wdata <= 0;
    else if(~ram_we_n)
        wdata <= wdata + 1;
end

initial begin
    wait(rst_n == 1'b0);
    wait(rst_n == 1'b1);

    repeat(3) @ (posedge pixclk);
    write();
    write();
    write();
    write();
    write();
    write();
    write();
    write();

    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    
    $finish();
end


// **********************************************************
//             UUT
// **********************************************************
DWC_mipi_csi2_host_bcm07
#(
      .ADDR_WIDTH       ( AWIDTH       )
    , .COUNT_WIDTH      ( CWIDTH       )   //Bus width to report the number of words in the fifo
    , .PUSH_AE_LVL      ( 1                           )
    , .PUSH_AF_LVL      ( 1                           )
    , .POP_AE_LVL       ( 1                           )
    , .POP_AF_LVL       ( 1                           )
    , .ERR_MODE         ( 1                           )
    // Selects the number of synchronization stages used for clock domain crossing.  
    // All stages capture the data on the rising edge of the clock. 
    , .PUSH_SYNC        ( 2 )
    , .POP_SYNC         ( 2 )
    , .EARLY_PUSH_STAT  ( 0                           )
    , .EARLY_POP_STAT   ( 0                           )
)
 UUT(
      .clk_push         ( pixclk           )              // input   Push domain clk input
    , .rst_push_n       ( rst_n             )              // input   Push domain active low async reset
    
    , .init_push_n      ( 1'b1              )              // input   Push domain active low sync reset
    , .push_req_n       ( ~ram_wen_req      )              // input   Push domain active high push reqest
    , .push_empty       (                   )              // output  Push domain Empty status flag
    , .push_ae          (                   )              // output  Push domain Almost Empty status flag
    , .push_hf          (                   )              // output  Push domain Half full status flag
    , .push_af          (                   )              // output  Push domain Almost full status flag
    , .push_full        (                   )              // output  Push domain Full status flag
    , .push_error       ( push_overflow     )              // output  Push domain Error status flag
    , .push_word_count  ( push_word_count   )              // output  Push domain word count
    , .we_n             ( ram_we_n           )              // output  Push domain active low RAM write enable
    , .wr_addr          ( ram_waddr         )              // output  Push domain RAM write address

    , .clk_pop          ( pixclk           )              // input   Pop domain clk input
    , .rst_pop_n        ( rst_n             )              // input   Pop domain active low async reset
    , .init_pop_n       ( 1'b1              )              // input   Pop domain active low sync reset
    , .pop_req_n        ( ~ram_ren          )              // input   Pop domain active high pop request
    , .pop_empty        ( pop_empty         )              // output  Pop domain Empty status flag
    , .pop_ae           (                   )              // output  Pop domain Almost Empty status flag
    , .pop_hf           (                   )              // output  Pop domain Half full status flag
    , .pop_af           (                   )              // output  Pop domain Almost full status flag
    , .pop_full         (                   )              // output  Pop domain Full status flag
    , .pop_word_count   (                   )              // output  Pop domain Error status flag
    , .pop_error        ( elast_underflow   )              // output  Pop domain word count
    , .rd_addr          ( ram_raddr         )              // output  Pop domain RAM read address
);


dpram_4096x8 u_dpram_4096x8 (
  .clka     (  ram_wclk      ),  // input wire clka
  .ena      (  1'b1          ),  // input wire ena
  .wea      ( ~ram_we_n       ),  // input wire [0 : 0] wea
  .addra    (  ram_waddr     ),  // input wire [11 : 0] addra
  .dina     (  wdata     ),  // input wire [7 : 0] dina
  .clkb     (  ram_rclk      ),  // input wire clkb
  .enb      (  1'b1          ),  // input wire enb
  .addrb    (  ram_raddr     ),  // input wire [11 : 0] addrb
  .doutb    (  rdata     )   // output wire [7 : 0] doutb
);




endmodule
