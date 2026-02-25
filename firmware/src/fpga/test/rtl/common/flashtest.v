`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:05:57 08/18/2016 
// Design Name: 
// Module Name:    ramtest 
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

module flashtest (
   input wire clk,
   input wire rst,
   output wire spi_clk,    //
   output wire spi_di,     // Interface SPI
   input wire spi_do,      //
   output reg spi_cs,     //
   output reg test_in_progress,
   output reg test_result,
   output wire [15:0] vendor_code_hex
   );
   
   initial test_in_progress = 1'b1;
   initial test_result = 1'b0;
   
   reg send_data = 1'b0;
   reg receive_data = 1'b0;
   reg [7:0] data_to_flash = 8'hFF;
   wire [7:0] data_from_flash;
   wire ready;
   initial spi_cs = 1'b1;
   reg [15:0] delay = 16'h0000;

   bin2hex conversor_hex (
      .din(data_from_flash),
      .hexout(vendor_code_hex)
   );
	
	reg [3:0] divisor = 4'b0000;
   always @(posedge clk)
      divisor <= divisor + 4'd1;
   
	wire clkf;  // el reloj de la flash no puede superar los 4 MHz
   BUFG bclkf (
      .I(divisor[3]), // 40/16=2.5 MHz
      .O(clkf)
   );
	   
   spi chipflash (
      .clk(clkf),         // 2.5MHz
      .enviar_dato(send_data), // a 1 para indicar que queremos enviar un dato por SPI
      .recibir_dato(receive_data), // a 1 para indicar que queremos recibir un dato
      .din(data_to_flash),   // del bus de datos de salida de la CPU
      .dout(data_from_flash),  // al bus de datos de entrada de la CPU
      .wait_n(ready),
      .spi_clk(spi_clk),   // Interface SPI
      .spi_di(spi_di),     //
      .spi_do(spi_do)      //
   );
   
   reg [3:0] estado = INIT, retorno_de_sendspi = INIT, retorno_de_recvspi = INIT;
   parameter
      INIT = 4'd0,
      SENDJEDECID = 4'd1,
      CHECK = 4'd4,
      HALT = 4'd6,
      SENDSPI = 4'd7,
      WAIT1CLKSEND = 4'd9,
      WAITSEND = 4'd10,
      RECVSPI = 4'd11,
      WAIT1CLKRECV = 4'd13,
      WAITRECV = 4'd14
      ;
   always @(posedge clkf) begin
      case (estado)
         INIT:
            begin
               delay <= delay + 16'd1;
               if (delay == 16'hFFFF)
                  estado <= SENDJEDECID;
            end
         SENDJEDECID:
            begin
               spi_cs <= 1'b0;
               test_in_progress <= 1'b1;
               test_result <= 1'b0;
               data_to_flash <= 8'h9F; // comando READ JEDEC ID
               estado <= SENDSPI;
               retorno_de_sendspi <= RECVSPI;
               retorno_de_recvspi <= CHECK;
            end         
         CHECK:
            begin
               spi_cs <= 1'b1;
               if (data_from_flash == 8'h00 || data_from_flash == 8'hFF) begin  // no hay respuesta de READ JEDEC ID
                  test_in_progress <= 1'b0;
                  test_result <= 1'b0;
                  estado <= HALT;
               end
               else begin
                  test_in_progress <= 1'b0;
                  test_result <= 1'b1;
                  estado <= HALT;
               end
            end
         HALT:
            if (rst == 1'b1)
               estado <= INIT;
            
         SENDSPI:
            begin
               send_data <= 1'b1;
               estado <= WAIT1CLKSEND;
            end
         WAIT1CLKSEND:
            begin
               send_data <= 1'b0;
               estado <= WAITSEND;
            end
         WAITSEND:
            begin
               if (ready == 1'b1) begin
                  estado <= retorno_de_sendspi;
               end
            end
            
         RECVSPI:
            begin
               receive_data <= 1'b1;
               estado <= WAIT1CLKRECV;
            end
         WAIT1CLKRECV:
            begin
               receive_data <= 1'b0;
               estado <= WAITRECV;
            end
         WAITRECV:
            begin
               if (ready == 1'b1) begin
                  estado <= retorno_de_recvspi;
               end
            end
      endcase
   end      
endmodule

module bin2hex (
  input wire [7:0] din,
  output reg [15:0] hexout
  );
  
   reg [7:0] hexvalues[0:15];
   integer i;
   initial begin
      for (i=0;i<10;i=i+1) begin
         hexvalues[i] = "0" + i;
      end
      for (i=10;i<16;i=i+1) begin
         hexvalues[i] = "A" - 10 + i;
      end
   end  
  
  always @* begin
    hexout = {hexvalues[din[7:4]], hexvalues[din[3:0]]};
  end
endmodule
