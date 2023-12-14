`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2023 11:51:39 AM
// Design Name: 
// Module Name: frm_gen
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


module frm_gen
#(
parameter frame_width=1920,
parameter frame_height=1080,
parameter line_blank=50,
parameter frame_blank=5
)
(
input pixclk,
input rst_n,
input en,

output reg data_in_lval,
output reg data_in_fval,
output reg [11:0] pixel_counter,     
output reg [11:0] line_counter  

);
    
// **************************************
//             Fval & lval
// **********************************************************

//lval
always @(posedge pixclk or negedge rst_n) begin
    if (~rst_n) begin
        data_in_lval <= 1'b0;
        pixel_counter <= 'h0;
    end
    else if (en) begin
    
        pixel_counter <= pixel_counter + 1'b1;

        if (pixel_counter == line_blank + frame_width + line_blank) begin
            pixel_counter <= 'h0;
        end

        if (pixel_counter < line_blank) begin
            data_in_lval <= 1'b0;
        end
        else if (pixel_counter < frame_width + line_blank) begin
            data_in_lval <= 1'b1;
        end
        else if (pixel_counter < line_blank + frame_width + line_blank) begin
            data_in_lval <= 1'b0;
        end
        
    end
    else begin
        data_in_lval <= data_in_lval;
        pixel_counter <= pixel_counter;
    end
end

//fval
always @(posedge pixclk or negedge rst_n) begin
    if (~rst_n) begin
        data_in_fval <= 1'b0;
        line_counter <= 'h0;
    end
    else if(en) begin

        if (pixel_counter == line_blank + frame_width + line_blank ) begin

            if (line_counter == frame_blank + frame_height + frame_blank ) begin
                line_counter <= 'h0;
            end 
            else begin
                line_counter <= line_counter + 1'b1;
            end
        end


        if (line_counter < frame_blank) begin
            data_in_fval <= 1'b0;
        end
        else if (line_counter < frame_blank + frame_height ) begin //  +1 ensure last line is available
            data_in_fval <= 1'b1;
        end
        else if (line_counter < frame_blank + frame_height + frame_blank) begin
            data_in_fval <= 1'b0;
        end

    end
    
    else begin
        data_in_fval <= data_in_fval;
        line_counter <= line_counter;
    end
end

    
    
  
endmodule
