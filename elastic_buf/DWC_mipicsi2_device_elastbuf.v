//-- Description   : Elasticity buffer
module  DWC_mipicsi2_device_elastbuf
#(
  parameter   ADDR_DEPTH  = 2
, parameter   DATA_WIDTH  = 32
)
(
  input   wire                  clk     //- clock input
, input   wire                  rstz    //- asynchronous rstz = reset_n
, input   wire                  write   //- write enable, active high
, input   wire [DATA_WIDTH-1:0] datain  //- data input
, input   wire                  read    //- read enable, active high
, output  wire [DATA_WIDTH-1:0] dataout //- data output

, input   wire                  clrbuff //- synchronous clear FIFO, active high
, output  wire                  emptyz  //- empty, active low
, output  wire                  fullz   //- full, active low

, output  wire                  almost_full  //- almost full, remain 1, active high

);
///////////////////////////////////////////////////////////////////////////////
//INTERNAL DECLARATIONS////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
reg     [ADDR_DEPTH-1:0]  writeptr;
reg     [DATA_WIDTH-1:0]  memshift [ADDR_DEPTH-1:0];
wire    full;
wire    empty;
wire    [1:0] rw_flag;
///////////////////////////////////////////////////////////////////////////////
//MAIN FUNCTION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//This block implements a serial buffer that has its size parameterizable. The
//buffer is always written from the LSBuffer to the MSBuffer. The last written
//value will always be available in the LSBuffer and a write pointer will be
//used to keep track of the positions that have not yet been filled with data.
//When a read operation is issued the buffer will shift all buffers contents to
//the right and when write operation is issue the content is written in the
//buffers that do not contain data. A write pointer is generated to keep track
//of the buffers that have valid data and the ones that do not.
assign  full     = writeptr[ADDR_DEPTH-1];
assign  fullz    = ~full;
assign  emptyz   = writeptr[0];
assign  empty    = ~emptyz;
assign  dataout  = memshift[0];
    // spyglass disable_block checkNetReceiver
    // SMD: Each internal net must have at least one receiver.
    // SJ: Some bits of the signal may not be needed in different configurations.
    // spyglass disable_block OutNotUsed
    // SMD: No output of a gate is used
    // SJ: For IDI inteface, these signals are not used
assign  almost_full  = writeptr == {1'h0,{(ADDR_DEPTH-1){1'h1}}};
    // spyglass enable_block OutNotUsed
    // spyglass enable_block checkNetReceiver
assign  rw_flag  = {read,write};
///////////////////////////////////////////////////////////////////////////////
//WRITE POINTER GENERATION/////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//The writeptr contains the information on the buffer that do not contain valid
//data. writeptr is shift register that is filled with ones as the buffers get
//filled with data. This way when hte writeptr pointer contains a register bit
//with a zero it means that the respective buffer position can be written with
//new data.
  always @ (posedge clk or negedge rstz) begin : writeptr_PROC
      if(!rstz)
          writeptr[ADDR_DEPTH-1:0]      <= {ADDR_DEPTH{1'b0}};
      else
          if(clrbuff)
            writeptr[ADDR_DEPTH-1:0]    <= {ADDR_DEPTH{1'b0}};
          else
            case(rw_flag)
                2'b10: begin
                    writeptr[ADDR_DEPTH-1:0]<= {1'b0, writeptr[ADDR_DEPTH-1:1]};//read a new value, shift right
                end
                2'b01: begin
                    writeptr[ADDR_DEPTH-1:0]<= {writeptr[ADDR_DEPTH-2:0], 1'b1};//write a value, shit left
                end
                2'b11: begin
                    //ccx_line_begin: ; External logic ensures the read in empty or the write in full to appear
                    if(full)                                                             //if the buffer is full
                        writeptr[ADDR_DEPTH-1:0]<= {1'b0, writeptr[ADDR_DEPTH-1:1]};     //read a new value, shift right
                    else
                        if(empty)
                            writeptr[ADDR_DEPTH-1:0]<= {writeptr[ADDR_DEPTH-2:0], 1'b1}; //write a value, shit left
                    //ccx_line_end
                end
                default: begin
                    writeptr[ADDR_DEPTH-1:0]<= writeptr[ADDR_DEPTH-1:0];
                end
            endcase

      end// writeptr_PROC

///////////////////////////////////////////////////////////////////////////////
//MEMORY BUFFERS GENERATION////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//memshift is a array of memory slots that will define the buffer.
//The MSBuffer is different from all other because since this is the last
//buffer when a shift right is made the shifted content is either a new value
//or a clear value.
generate
genvar i;
for (i=0; i<=(ADDR_DEPTH-1); i=i+1)
begin : shift_register

if(i==(ADDR_DEPTH-1)) begin: shift_register_end
  //MSBuffer
  always @ (posedge clk or negedge rstz) begin: shift_register_end_PROC
      if(!rstz) begin
          memshift[i] <= {DATA_WIDTH{1'b0}};
      end else begin
          if(clrbuff) begin
              memshift[i] <= {DATA_WIDTH{1'b0}};
          end else begin
              case(rw_flag)
                  2'b10: begin
                      memshift[i] <= {DATA_WIDTH{1'b0}};
                  end
                  2'b01: begin
                      if(~writeptr[i])                        //if current position is available
                          memshift[i]  <= datain;
                  end
                  2'b11: begin
                      if(~writeptr[i])                        //if the marginal register get
                          memshift[i]  <= datain;
                      else begin
                      //ccx_line: ; External logic ensures the read in empty or the write in full to appear
                          memshift[i] <= {DATA_WIDTH{1'b0}};
                      end
                  end
                  default: begin
                      memshift[i] <= memshift[i];
                  end
              endcase
          end
      end
  end //shift_register_end_PROC

end else begin: shift_register_start_continue

  always @ (posedge clk or negedge rstz) begin: shift_register_start_continue_PROC
    if (!rstz)begin
        memshift[i] <= {DATA_WIDTH{1'b0}};
    end else begin
        if(clrbuff) begin
            memshift[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            case(rw_flag)
                2'b10: begin
                    // spyglass disable_block SelfDeterminedExpr-ML
                    // SMD: Self determined expression detected
                    // SJ: These expressions are correct.
                    if(writeptr[i+1])                        //if next position is filled
                        memshift[i] <= memshift[i+1];
                    else begin
                        memshift[i] <= {DATA_WIDTH{1'b0}};
                    end
                    // spyglass enable_block SelfDeterminedExpr-ML
                end
                2'b01: begin
                    if(~writeptr[i])                         //if current position is available
                        // spyglass disable_block RegInputOutput-ML
                        // SMD: Module output and input port should be registered
                        // SJ: This is expected and reviewed.
                        memshift[i] <= datain;               //else leave it the same
                        // spyglass enable_block RegInputOutput-ML
                end
                2'b11: begin
                    // spyglass disable_block SelfDeterminedExpr-ML
                    // SMD: Self determined expression detected
                    // SJ: These expressions are correct.
                    if((~writeptr[i]) | ((~writeptr[i+1]) & writeptr[i]))  //if the marginal register get
                        memshift[i] <= datain;
                    else
                    //ccx_line: ; External logic ensures the read in empty or the write in full to appear
                        memshift[i] <= memshift[i+1];                  //else shift left
                    // spyglass enable_block SelfDeterminedExpr-ML
                end
                default: begin
                    memshift[i] <= memshift[i];
                end
            endcase
        end
      end
    end //shift_register_start_continue_PROC
end//End of conditional generate

end//End of For generate shift_register
endgenerate


endmodule
