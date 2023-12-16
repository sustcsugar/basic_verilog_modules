module sram_mod_2prf #(
    parameter ADDR_WIDTH = 10,         // Address width parameter
    parameter DATA_WIDTH = 8,          // Data width parameter
    parameter ADDR_SPACE = 1024)       // Address space parameter
(
    input clk_w,                       // Clock input
    input [ADDR_WIDTH-1:0] addr_w,     // Write address input
    input [DATA_WIDTH-1:0] din_w,      // Write data input
    input ce_w,                        // Write chip enable input (low-active)
    input en_w,                        // Write enable input (low-active)
    input clk_r,                       // Clock input
    input [ADDR_WIDTH-1:0] addr_r,     // Read address input
    input ce_r,                        // Read chip enable input (low-active)
    input en_r,                        // Read enable input (low-active)
    output reg [DATA_WIDTH-1:0] dout_r // Read data output
);

reg [DATA_WIDTH-1:0] memory [ADDR_SPACE-1:0]; // Declare memory array

always @(posedge clk_w) begin
    if (!ce_w) begin // if chip enable is low (active low)
        if (!en_w) begin // if write enable is low (active low)
            memory[addr_w] <= din_w; // Write data to memory at the specified address and bit position
        end
        else;
    end
    else;
end

always @(posedge clk_r) begin
    if (!ce_r && !en_r) begin // Check if read chip enable
        dout_r <= memory[addr_r];
        
        if(!ce_w && !en_w && addr_w == addr_r) begin
            //Waring: if reading and writing same address
            $display("Waring: 2prf sram reading and writing same address at time:  %.1f ns", $time);
        end
    end
    else begin
        dout_r <= {DATA_WIDTH{1'bz}}; // output high-impedance when chip is disabled
    end
end

endmodule
