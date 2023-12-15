`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2023 01:55:53 PM
// Design Name: 
// Module Name: dual_sync_fifo
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


module dual_sync_fifo
#(
    parameter DEPTH   =   720 ,
    parameter AWIDTH  =   10  ,
    parameter DWIDTH  =   8   ,
    parameter CWIDTH  =   10
)
(
      input           rst_n

    , input           pixclk1
    , input           image1_hs
    , input           image1_vs
    , input           image1_valid
    , input   [DWIDTH-1:0]   image1_data

    , input           pixclk2
    , input           image2_hs
    , input           image2_vs
    , input           image2_valid
    , input   [DWIDTH-1:0]   image2_data

    , output          o_pixclk
    , output          o_image_hs
    , output          o_image_vs
    , output          o_image_valid
    , output  [2*DWIDTH-1:0]  o_image_data

);

//mem fifo interface
wire              ram_rclk   ;             // output Data from read operations.
wire [AWIDTH-1:0] ram_raddr  ;             // output Address for read operations.
wire [DWIDTH-1:0] ram_rdata  ;             // input  Data from read operations.
wire              ram_ren    ;             // output Read enable.

wire              ram_wclk   ;             // output Data from read operations.
wire [AWIDTH-1:0] ram_waddr  ;             // output Address for write operations.
wire [DWIDTH-1:0] ram_wdata  ;             // output Data for write operations.
wire              ram_we_n    ;             // output Write enable.


// MUX 2 to 1
reg     [1:0]     image_sel    ;
reg               neg_flag     ;


wire [DWIDTH-1:0]        image_synced ;
wire [DWIDTH-1:0]        image_diret  ;

//edge detection
wire image1_hs_rise;
wire image1_vs_rise;
wire image1_hs_down;
wire image1_vs_down;

wire image2_hs_rise;
wire image2_vs_rise;
wire image2_hs_down;
wire image2_vs_down;

edge_det #(
    .WIDTH(1)
)
u_image1_hs_rise(
     .clk        (pixclk1)
   , .rst_n      (rst_n)
   , .src        (image1_hs)
   , .rise_pulse (image1_hs_rise)
   , .down_pulse (image1_hs_down)
);

edge_det #(
    .WIDTH(1)
)
u_image1_vs_rise(
     .clk        (pixclk1)
   , .rst_n      (rst_n)
   , .src        (image1_vs)
   , .rise_pulse (image1_vs_rise)
   , .down_pulse (image1_vs_down)
);


edge_det #(
    .WIDTH(1)
)
u_image2_hs_rise(
     .clk        (pixclk2)
   , .rst_n      (rst_n)
   , .src        (image2_hs)
   , .rise_pulse (image2_hs_rise)
   , .down_pulse (image2_hs_down)
);

edge_det #(
    .WIDTH(1)
)
u_image2_vs_rise(
     .clk        (pixclk2)
   , .rst_n      (rst_n)
   , .src        (image2_vs)
   , .rise_pulse (image2_vs_rise)
   , .down_pulse (image2_vs_down)
);


// always @ (posedge pixclk1 or negedge rst_n) begin : proc_image_mux_control_by_hs
//     if (!rst_n) begin
//         image_sel <= 2'b0;
//         neg_flag  <= 1'b0;
//     end
//     else begin
//         if (~neg_flag) begin
//             if (image1_hs_rise && ~image2_hs) begin // image 1 first
//                 image_sel <= 2'b10;
//                 neg_flag  <= image2_hs_down;
//             end
//             else if (image2_hs_rise && ~image1_hs) begin // image 2 first
//                 image_sel <= 2'b01;
//                 neg_flag  <= image1_hs_down;
//             end
//             else begin
//                 image_sel <= image_sel;
//                 neg_flag  <= neg_flag;
//             end
//         end
//         else begin
//             image_sel <= 2'b00;
//         end
//     end
// end // proc_image_mux_control_by_hs

reg write_flag_n;
reg read_flag_n;

always @ (posedge pixclk1 or negedge rst_n) begin : proc_image_mux_control_by_vs
    if (!rst_n) begin
        image_sel <= 2'b0;
        neg_flag  <= 1'b0;
        write_flag_n <= 1'b1;
        read_flag_n  <= 1'b1;
    end
    else begin
        if (~neg_flag) begin // lock image sel & write signal
            if (image1_vs_rise && ~image2_vs) begin // image 1 first
                image_sel <= 2'b10;
                //neg_flag  <= image2_vs_down;
                neg_flag  <= 1'b1;

                write_flag_n <= 1'b0;
            end
            else if (image2_vs_rise && ~image1_vs) begin // image 2 first
                image_sel <= 2'b01;
                //neg_flag  <= image1_vs_down;
                neg_flag  <= 1'b1;

                write_flag_n <= 1'b0;
            end
            else begin
                image_sel <= image_sel;
                neg_flag  <= neg_flag;

                write_flag_n <= write_flag_n;
            end
        end
        else begin

            // lock sel & read write signal
            image_sel <= image_sel;
            write_flag_n <= write_flag_n;

            // read operation
            if ( (image_sel == 2'b10) && (image2_vs_rise) )
                read_flag_n <= 1'b0;
            else if ( (image_sel == 2'b01) && (image1_vs_rise) )
                read_flag_n <= 1'b0;
            else
                read_flag_n  <= read_flag_n;



            // finish this frame, reset neg_flag, unlock sel & read & write
            if( ( (image_sel == 2'b10) && (image2_vs_down) ) || ( (image_sel == 2'b01) && (image1_vs_down) ) ) begin
                neg_flag <= 1'b0;
                image_sel <= 2'b0;
                write_flag_n <= 1'b1;
                read_flag_n  <= 1'b1;
            end

        end
    end
end // proc_image_mux_control_by_vs


// ram control logic
assign ram_rclk = pixclk1;
assign ram_wclk = pixclk1;



assign ram_wdata = image_sel[1]?image1_data:image2_data;
assign ram_wen_req = image_sel[1]?image1_hs:image2_hs;
assign ram_ren = image_sel[1]?image2_hs:image1_hs;


// Main Memory FIFO controller
DWC_mipi_csi2_host_bcm07
#(  
      .DEPTH            ( DEPTH   )
    , .ADDR_WIDTH       ( AWIDTH  )
    , .COUNT_WIDTH      ( CWIDTH  )   //Bus width to report the number of words in the fifo
    , .PUSH_AE_LVL      ( 1       )
    , .PUSH_AF_LVL      ( 1       )
    , .POP_AE_LVL       ( 1       )
    , .POP_AF_LVL       ( 1       )
    , .ERR_MODE         ( 1       )
    // Selects the number of synchronization stages used for clock domain crossing.  
    // All stages capture the data on the rising edge of the clock. 
    , .PUSH_SYNC        ( 2 )  
    , .POP_SYNC         ( 2 )
    , .EARLY_PUSH_STAT  ( 0 )
    , .EARLY_POP_STAT   ( 0 )
) 
sync_fifo(
      .clk_push         ( pixclk1           )              // input   Push domain clk input
    , .rst_push_n       ( rst_n             )              // input   Push domain active low async reset
    , .init_push_n      ( 1'b1              )              // input   Push domain active low sync reset
    , .push_req_n       ( write_flag_n      )              // input   Push domain active low push reqest
    , .push_empty       (                   )              // output  Push domain Empty status flag
    , .push_ae          (                   )              // output  Push domain Almost Empty status flag
    , .push_hf          (                   )              // output  Push domain Half full status flag
    , .push_af          (                   )              // output  Push domain Almost full status flag
    , .push_full        (                   )              // output  Push domain Full status flag
    , .push_error       ( push_overflow     )              // output  Push domain Error status flag
    , .push_word_count  ( push_word_count   )              // output  Push domain word count
    , .we_n             ( ram_we_n           )              // output  Push domain active low RAM write enable
    , .wr_addr          ( ram_waddr         )              // output  Push domain RAM write address

    , .clk_pop          ( pixclk2           )              // input   Pop domain clk input
    , .rst_pop_n        ( rst_n             )              // input   Pop domain active low async reset
    , .init_pop_n       ( 1'b1              )              // input   Pop domain active low sync reset
    , .pop_req_n        ( read_flag_n       )              // input   Pop domain active low pop request
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
  .dina     (  ram_wdata     ),  // input wire [7 : 0] dina
  .clkb     (  ram_rclk      ),  // input wire clkb
  .enb      (  1'b1          ),  // input wire enb
  .addrb    (  ram_raddr     ),  // input wire [11 : 0] addrb
  .doutb    (  ram_rdata     )   // output wire [7 : 0] doutb
);



// output logic
reg                 o_image_hs_reg   ;
reg                 o_image_vs_reg   ;
reg                 o_image_valid_reg;
reg [DWIDTH-1:0]    o_image_data_diret_reg;

reg                 o_image_hs_reg_2   ;
reg                 o_image_vs_reg_2   ;
reg                 o_image_valid_reg_2;
reg [2*DWIDTH-1:0]  o_image_data_reg   ;
reg [2*DWIDTH-1:0]  o_image_data_reg_2 ;


always @ (posedge pixclk1 or negedge rst_n)begin
    if(~rst_n)begin
            o_image_hs_reg <= 0;
            o_image_vs_reg <= 0;
            o_image_valid_reg <= 0;
            o_image_data_diret_reg <= 0;
    end
    else begin
        if (image_sel == 2'b10 ) begin
            o_image_hs_reg <= image2_hs;
            o_image_vs_reg <= image2_vs;
            o_image_valid_reg <= image2_valid;
            o_image_data_diret_reg <= image2_data;
        end
        else if (image_sel == 2'b01) begin
            o_image_hs_reg <= image1_hs;
            o_image_vs_reg <= image1_vs;
            o_image_valid_reg <= image1_valid;
            o_image_data_diret_reg <= image1_data;
        end
        else begin
            o_image_hs_reg    <= o_image_hs_reg   ;
            o_image_vs_reg    <= o_image_vs_reg   ;
            o_image_valid_reg <= o_image_valid_reg;
            o_image_data_diret_reg <= o_image_data_diret_reg;
        end
    end
end

// dly 1 clk to avoid 
always @ (posedge pixclk1 or negedge rst_n)begin
    o_image_hs_reg_2   <= o_image_hs_reg   ;
    o_image_vs_reg_2   <= o_image_vs_reg   ;
    o_image_valid_reg_2<= o_image_valid_reg;
    o_image_data_reg_2 <= {image_synced , image_diret};
end

assign o_pixclk      = pixclk1;
assign o_image_hs    = o_image_hs_reg_2   ;
assign o_image_vs    = o_image_vs_reg_2   ;
assign o_image_valid = o_image_valid_reg_2;

assign image_synced  = ram_rdata;
assign image_diret   = o_image_data_diret_reg;
//assign o_image_data = {image_synced , image_diret};
assign o_image_data  = o_image_data_reg_2;

endmodule

