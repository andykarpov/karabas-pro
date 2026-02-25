`timescale 1ns / 1ps
`default_nettype none

module zxunouart_emu (
    input wire clk_bus,
    input wire reset,
    input wire [7:0] zxuno_addr,
    input wire zxuno_regrd,
    input wire zxuno_regwr,
    input wire [7:0] din,
    output reg [7:0] dout,
    output reg oe_n,

    output wire [7:0] uart_tx_data,
    output wire uart_tx_req,
    input wire [7:0] uart_rx_data,
    input wire uart_rx_req,
	 output wire uart_rx_fifo_full
);

    parameter UARTDATA = 8'hC6;
    parameter UARTSTAT = 8'hC7;
    
    // rx fifo 64 bytes
    wire fifo_rx_full, fifo_rx_empty;
    wire [7:0] fifo_rx_do;
	 wire [5:0] fifo_rx_data_count;
    fifo #( .ADDR_WIDTH(6), .DATA_WIDTH(8)) fifo_rx (
        .clk(clk_bus),
        .reset(reset),

        .wr(uart_rx_req),
        .din(uart_rx_data),

        .rd(uart_rx_rd),
        .dout(fifo_rx_do),

        .full(fifo_rx_full),
        .empty(fifo_rx_empty),
		  
		  .data_count(fifo_rx_data_count)
    );
	 
	 assign uart_rx_fifo_full = (fifo_rx_data_count > 50) ? 1'b1 : 1'b0;

    wire uart_rx_rd = (zxuno_addr == UARTDATA && zxuno_regrd == 1'b1);
    wire uart_rx_stat = (zxuno_addr == UARTSTAT && zxuno_regrd == 1'b1);

    assign uart_tx_req = (zxuno_addr == UARTDATA && zxuno_regwr == 1'b1);
	 assign uart_tx_data = din;

    always @(posedge clk_bus) begin
        oe_n = 1'b1;
        dout = 8'hFF;
        if (uart_rx_rd) begin
            dout = fifo_rx_do;
            oe_n = 1'b0;
        end
        else if (uart_rx_stat) begin
            dout = {~fifo_rx_empty, 1'b0, 6'h00};
            oe_n = 1'b0;
        end
    end

endmodule

