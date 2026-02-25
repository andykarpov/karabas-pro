`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:37:59 08/15/2016 
// Design Name: 
// Module Name:    audio_test 
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
module audio_test (
   input wire clk,  // 14MHz
   output wire [15:0] left,
   output wire [15:0] right,
   output wire led
   );
   
   reg [11:0] sample_addr = 12'd0;
   reg [7:0] sample;
   reg [12:0] cnt_2000 = 13'd0;
   reg leftright = 1'b0;

   reg [7:0] audiomem[0:3999];
   initial begin
      $readmemh ("left_audio.hex", audiomem, 0);
      $readmemh ("right_audio.hex", audiomem, 2000);
   end
   
   always @(posedge clk) begin
      if (cnt_2000 == 13'd6999) begin  // prescaler para pasar de 14MHz a 2kHz, que es nuestra frecuencia de muestreo
         cnt_2000 <= 13'd0;
         sample <= audiomem[sample_addr];
         if (sample_addr == 12'd1999)  // Si hemos llegado a la mitad de la memoria
            leftright <= 1'b1;         // La memoria contiene en una mitad, el sample izquierdo, y en la otra mitad, el derecho
         if (sample_addr == 12'd3999) begin // Si hemos llegado al final de la memoria
            sample_addr <= 12'd0;      // Volver al principio
            leftright <= 1'b0;         // Y seleccionar salida al izquierdo
         end
         else
            sample_addr <= sample_addr + 12'd1;
      end
      else
         cnt_2000 <= cnt_2000 + 13'd1;
   end
   
   assign left = (leftright == 1'b0)? {4'b0000, sample, 4'b0000} : 16'b0000000000000000;
   assign right = (leftright == 1'b1)? {4'b0000, sample, 4'b0000} : 16'b0000000000000000;
   assign led = ~leftright;
endmodule



