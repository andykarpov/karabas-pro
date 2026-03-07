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

module sdtest (
   input wire clk,
   input wire rst,
   output wire spi_clk,    //
   output wire spi_di,     // Interface SPI
   input wire spi_do,      //
   output reg spi_cs,     //
   output reg test_in_progress,
   output reg test_result
   );
   
   initial test_in_progress = 1'b1;
   initial test_result = 1'b0;
   
   reg send_data = 1'b0;
   reg receive_data = 1'b0;
   reg [7:0] data_to_sd = 8'hFF;
   wire [7:0] data_from_sd;
   wire ready;
   initial spi_cs = 1'b1;
	
	reg [3:0] divisor = 4'b0000;
   always @(posedge clk)
      divisor <= divisor + 4'd1;
   
	wire clksd = divisor[3];  // el reloj de la SD no puede superar los 4 MHz
	
   spi slotsd (
      .clk(clksd),         // 2.5MHz
      .enviar_dato(send_data), // a 1 para indicar que queremos enviar un dato por SPI
      .recibir_dato(receive_data), // a 1 para indicar que queremos recibir un dato
      .din(data_to_sd),   // del bus de datos de salida de la CPU
      .dout(data_from_sd),  // al bus de datos de entrada de la CPU
      .wait_n(ready),
      .spi_clk(spi_clk),   // Interface SPI
      .spi_di(spi_di),     //
      .spi_do(spi_do)      //
   );
   
   reg [3:0] cnt = 4'd0;
   reg [7:0] tout = 8'd0;
   reg [7:0] cmd0[0:5];
   initial begin
      cmd0[0] = 8'h40;
      cmd0[1] = 8'h00;
      cmd0[2] = 8'h00;
      cmd0[3] = 8'h00;
      cmd0[4] = 8'h00;
      cmd0[5] = 8'h95;
   end
      
   reg [3:0] estado = SENDCLOCKS, retorno_de_sendspi = SENDCLOCKS, retorno_de_recvspi = SENDCLOCKS;
   parameter
      SENDCLOCKS = 4'd0,
      SEND8CLOCKS = 4'd1,
      SENDCMD0 = 4'd2,
      RESPUESTA = 4'd3,
      CHECK = 4'd4,
      SPARECLOCKS = 4'd5,
      HALT = 4'd6,
      SENDSPI = 4'd7,
      OKTOSEND = 4'd8,
      WAIT1CLKSEND = 4'd9,
      WAITSEND = 4'd10,
      RECVSPI = 4'd11,
      OKTORECV = 4'd12,
      WAIT1CLKRECV = 4'd13,
      WAITRECV = 4'd14
      ;
   always @(posedge clksd) begin
      case (estado)
         SENDCLOCKS:
            begin
               test_in_progress <= 1'b1;
               test_result <= 1'b0;
               cnt <= 4'd0;
               spi_cs <= 1'b1;
               data_to_sd <= 8'hFF;
               estado <= SEND8CLOCKS;
            end
         SEND8CLOCKS:
            begin
               if (cnt == 4'd10) begin
                  spi_cs <= 1'b0;
                  cnt <= 4'd0;                  
                  estado <= SENDCMD0;
               end
               else begin
                  cnt <= cnt + 4'd1;
                  estado <= SENDSPI;
                  retorno_de_sendspi <= SEND8CLOCKS;
               end
            end
         SENDCMD0:
            begin
               if (cnt == 4'd6) begin
                  tout <= 8'd0;
                  estado <= RESPUESTA;
               end
               else begin
                  data_to_sd <= cmd0[cnt];
                  cnt <= cnt + 4'd1; 
                  estado <= SENDSPI;
                  retorno_de_sendspi <= SENDCMD0;
               end
            end
         RESPUESTA:
            begin
               if (tout == 8'hFF) begin
                  test_in_progress <= 1'b0;
                  test_result <= 1'b0;
                  estado <= SPARECLOCKS;
               end
               else begin
                  estado <= RECVSPI;
                  retorno_de_recvspi <= CHECK;
                  tout <= tout + 8'd1;
               end
            end
         CHECK:
            begin
               if (data_from_sd[7] == 1'b1) begin
                  estado <= RESPUESTA;
               end
               else if (data_from_sd != 8'h01) begin
                  test_in_progress <= 1'b0;
                  test_result <= 1'b0;
                  estado <= SPARECLOCKS;
               end
               else begin
                  test_in_progress <= 1'b0;
                  test_result <= 1'b1;
                  estado <= SPARECLOCKS;
               end
            end
         SPARECLOCKS:
            begin
               spi_cs <= 1'b1;
               data_to_sd <= 8'hFF;
               estado <= SENDSPI;
               retorno_de_sendspi <= HALT;
            end
         HALT:
            if (rst == 1'b1)
               estado <= SENDCLOCKS;
            
         SENDSPI:
            begin
               if (ready == 1'b1)
                  estado <= OKTOSEND;
            end
         OKTOSEND:
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
               if (ready == 1'b1)
                  estado <= retorno_de_sendspi;
            end
            
         RECVSPI:
            begin
               if (ready == 1'b1)
                  estado <= OKTORECV;
            end
         OKTORECV:
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
               if (ready == 1'b1)
                  estado <= retorno_de_recvspi;
            end
      endcase
   end      
endmodule
