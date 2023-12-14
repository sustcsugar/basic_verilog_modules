//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/14 00:24:54
// Design Name: 
// Module Name: fifo_reg
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


module fifo_reg
#(
    parameter DWIDTH = 8 ,
    parameter AWIDTH = 6 ,
)
(
    // global clk and async rst
    input   clk,
    input   rst_n,
    // control
    input   wr,
    input   rd,
    // data
    input   [DWIDTH-1:0]    wdata,
    output  [DWIDTH-1:0]    rdata,
    // status
    output  full,
    output  empty,
    output  [AWIDTH-1:0]    data_cnt
);

localparam DEPTH = 1 << DWIDTH;

// signal declaration

// reg array
reg [DWIDTH-1:0] reg_array [DEPTH-1:0];
// ptr 
reg [AWIDTH-1:0] wr_ptr_reg,wr_ptr_next;
reg [AWIDTH-1:0] rd_ptr_reg,rd_ptr_next;
reg full_reg , full_next;
reg empty_reg , empty_next;
reg [DWIDTH-1:0] data_cnt_reg,data_cnt_next;
wire wr_en;


// data operation
assign wr_en = wr & ~full;
always @(posedge clk ) begin
    if(wr_en)
        reg_array[wr_ptr_reg] <= wdata;    // write data
end

assign rdata =  reg_array[rd_ptr_reg];     // read data


// ptr control

always @(posedge clk or negedge rst_n) begin
    if (~rst_n)begin
        wr_ptr_reg <= {AWIDTH{1'b0}};
        rd_ptr_reg <= {AWIDTH{1'b0}};
        full_reg   <= 1'b0;
        empty_reg  <= 1'b0;
        data_cnt_reg  <= {DWIDTH{1'b1}};
    end
    else begin
        wr_ptr_reg <= wr_ptr_next;
        rd_ptr_reg <= rd_ptr_next;
        full_reg   <= full_next  ;
        empty_reg  <= empty_next ;
        data_cnt_reg<= data_cnt_next;
    end
end

always @(*) begin

    wr_ptr_next = wr_ptr_reg;
    rd_ptr_next = rd_ptr_reg;
    full_next =  full_reg;
    empty_next = empty_reg;
    data_cnt_next = data_cnt_reg;

    case({rd,wr}):
        2'b00: //no operation
        2'b01: //write
            begin
                if (~full_reg) begin
                    wr_ptr_next = wr_ptr_next + 1;
                    data_cnt_next = data_cnt_next + 1;

                    empty_next = 1'b0;
                    if ( (wr_ptr_next+1) == rd_ptr_reg )
                        full_next = 1'b1;
                end
            end
        2'b10://read
            begin
                if (~empty_reg) begin// not empty
                    rd_ptr_next = rd_ptr_next + 1;
                    data_cnt_next = data_cnt_next - 1;

                    full_next = 1'b0;
                    if ( (rd_ptr_next+1) == wr_ptr_reg )
                        empty_next = 1'b1;
                end
            end
        2'b11:// read write
            begin
                rd_ptr_next = rd_ptr_next + 1;
                wr_ptr_next = wr_ptr_next + 1;
            end
    endcase

end


assign full = full_reg;
assign empty = empty_reg;
assign data_cnt = data_cnt_reg;

endmodule
