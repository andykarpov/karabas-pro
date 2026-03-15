`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:30:12 08/17/2016 
// Design Name: 
// Module Name:    get_dna 
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
module get_dna (
   input wire clk,
   output reg [56:0] dna
   );

   reg [4:0] divisor = 5'b00000;
   always @(posedge clk)
      divisor <= divisor + 5'd1;
      
   wire clkdna;  // el reloj de la DNA no puede superar los 2 MHz
   BUFG bclkdna (
      .I(divisor[4]), // 40/32=1.25 MHz
      .O(clkdna)
   );

   reg load_dna = 1'b1;
   reg enable_dnashift = 1'b0;
   wire dnaout;
   DNA_PORT #(
      .SIM_DNA_VALUE(57'hAAAAAAAAAAAAAAA)  // Specifies the Pre-programmed factory ID value
   )
   dna_de_la_fpga (
      .DOUT(dnaout),   // 1-bit output: DNA output data
      .CLK(clkdna),     // 1-bit input: Clock input
      .DIN(1'b0),     // 1-bit input: User data input pin
      .READ(load_dna),   // 1-bit input: Active high load DNA, active low read input
      .SHIFT(enable_dnashift)  // 1-bit input: Active high shift enable input
   );
   
   reg [1:0] estado = INIT;
   reg [5:0] cnt = 6'd0;
   parameter
      INIT = 2'd0,
      SHIFT = 2'd1,
      HALT = 2'd2
      ;
   always @(posedge clkdna) begin
      case (estado)
         INIT:
            begin
               estado <= SHIFT;
               load_dna <= 1'b0;
               enable_dnashift <= 1'b1;
               cnt <= 6'd0;
               dna <= 57'h000000000000000;
            end
         SHIFT:
            if (cnt == 6'd57) begin
               enable_dnashift <= 1'b0;
               estado <= HALT;
            end
            else begin
               dna <= {dna[56:0],dnaout};
               cnt <= cnt + 6'd1;
            end
      endcase
   end         
endmodule
