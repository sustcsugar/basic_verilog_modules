// Synchronized Asynchronous Reset
//-- Description   : Synchronize rest module
module syncrstz

  #(//---------- PARAMETER DECLARATION ---------------------------------------------------
  parameter DEPTH = 2
  )

  (//----------- PORTS DECLARATION -------------------------------------------------------
    input  wire        clk,   // Clock input signal
    input  wire        rstz,  // Asynchronous reset input, active low
    output wire        srstz  // Synchronized reset output, active low
  );

  //----------- SIGNALS DECLARATION ------------------------------------------------------
  reg [DEPTH:0]      regrstz;               // Synchronization register

  always@(posedge clk or negedge rstz)
      if (!rstz)
          regrstz[0] <= 1'b0;     
      else                        
          regrstz[0] <= 1'b1;

  always@(posedge clk)
      regrstz[DEPTH:1] <= regrstz[DEPTH-1:0];

  assign srstz = &regrstz[DEPTH:0];

endmodule
