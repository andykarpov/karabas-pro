`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    05:02:03 08/19/2016 
// Design Name: 
// Module Name:    eartest 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module eartest (
   input wire clk,
   input wire ear,
   input wire vs,
   output reg [7:0] code
   );
   
   initial code = " ";
   
   reg [3:0] earsynchr = 2'b00;
   reg [1:0] vsedge = 2'b11;
   wire [1:0] earedge = earsynchr[3:2];   
   always @(posedge clk) begin
      earsynchr <= {earsynchr[2:0], ear};
      vsedge <= {vsedge[0], vs};
   end
   
   wire posflanco = (earedge == 2'b01);
   wire negflanco = (earedge == 2'b10);
   
   reg posdetect = 1'b0, negdetect = 1'b0, vsdetect = 1'b0;
   reg [7:0] codes[0:3];
   initial begin
      codes[0] = "-";
      codes[1] = "`";
      codes[2] = "|";
      codes[3] = "/";
   end
   reg [1:0] idxcode = 2'd0;
   
   always @(posedge clk) begin
      if (vsedge == 2'b10 && vsdetect == 1'b0) begin
         vsdetect <= 1'b1;
         posdetect <= 1'b0;
         negdetect <= 1'b0;
      end
      if (vsdetect == 1'b1) begin
         if (posflanco && negdetect == 1'b0)
            posdetect <= 1'b1;
         if (negflanco && posdetect == 1'b1)
            negdetect <= 1'b1;
         if (posdetect && negdetect) begin
            code <= codes[idxcode];
            idxcode <= idxcode + 2'd1;
            vsdetect <= 1'b0;
         end
      end
   end
endmodule
