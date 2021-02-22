`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:26:34 10/17/2015 
// Design Name: 
// Module Name:    zxunouart 
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

module zxunouart (
    input wire clk_bus,
	 input wire clk_div2,
	 input wire clk_div4,
	 input wire ds80,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe_n,
    output wire uart_tx,
    input wire uart_rx,
    output wire uart_rts
    );

    parameter UARTDATA = 8'hC6;
    parameter UARTSTAT = 8'hC7;

    wire txbusy;
    wire data_received;
    wire [7:0] rxdata;
    
    reg comenzar_trans = 1'b0;
    reg rxrecv = 1'b0;
    reg leyendo_estado = 1'b0;
 
    wire data_read;
    
    uart uartchip (
        .clk_bus(clk_bus),
		  .clk_div2(clk_div2),
		  .clk_div4(clk_div4),
		  .ds80(ds80),
        .txdata(din),
        .txbegin(comenzar_trans),
        .txbusy(txbusy),
        .rxdata(rxdata),
        .rxrecv(data_received),
        .data_read(data_read),
        .rx(uart_rx),
        .tx(uart_tx),
        .rts(uart_rts)
    );

    assign data_read = (zxuno_addr == UARTDATA && zxuno_regrd == 1'b1);

    always @* begin
        oe_n = 1'b1;
        dout = 8'hZZ;
        if (zxuno_addr == UARTDATA && zxuno_regrd == 1'b1) begin
            dout = rxdata;
            oe_n = 1'b0;
        end
        else if (zxuno_addr == UARTSTAT && zxuno_regrd == 1'b1) begin
            dout = {rxrecv, txbusy, 6'h00};
            oe_n = 1'b0;
        end
    end

    always @(posedge clk_bus) begin
		  if (clk_div2 == 1'b1 && clk_div4 == 1'b1) begin
			  if (zxuno_addr == UARTDATA && zxuno_regwr == 1'b1 && comenzar_trans == 1'b0 && txbusy == 1'b0) begin
					comenzar_trans <= 1'b1;
			  end
			  if (comenzar_trans == 1'b1 && txbusy == 1'b1) begin
					comenzar_trans <= 1'b0;
			  end

			  if (data_received == 1'b1)
					rxrecv <= 1'b1;

			  if (data_received == 1'b0) begin
					if (zxuno_addr == UARTSTAT && zxuno_regrd == 1'b1)
						 leyendo_estado <= 1'b1;
					if (leyendo_estado == 1'b1 && (zxuno_addr != UARTSTAT || zxuno_regrd == 1'b0)) begin
						 leyendo_estado <= 1'b0;
						 rxrecv <= 1'b0;
					end
			  end
		  end
    end
endmodule
