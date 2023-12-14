`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2023 07:10:59 PM
// Design Name: 
// Module Name: rise_edge_det
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

//-- Description: Rising edge detector
module edge_det

    #(//---- PARAMETERS DECLARATION -------------------------------------------
    parameter WIDTH = 8
    )

    (//---- PORTS DECLARATION -------------------------------------------------
    input                   clk,
    input                   rst_n,
    input       [WIDTH-1:0] src,
    output wire [WIDTH-1:0] rise_pulse,
    output wire [WIDTH-1:0] down_pulse
    );

    reg   [WIDTH-1:0]  src_r;

    always @(posedge clk or negedge rst_n) begin : proc_src_dly
        if(~rst_n)
            src_r <= {WIDTH{1'b0}};
        else
            src_r <= src;
    end // proc_src_dly

    // Rising edge detection
    assign rise_pulse[WIDTH-1:0] = ( (src[WIDTH-1:0]) & (~src_r[WIDTH-1:0]) );
    assign down_pulse[WIDTH-1:0] = ( (~src[WIDTH-1:0]) & (src_r[WIDTH-1:0]) );


endmodule