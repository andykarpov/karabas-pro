`default_nettype none
// simplified version of the MCU unit to only show OSD
module mcu(
    input wire         clk,

    input wire         mcu_mosi,
    output wire        mcu_miso,
    input wire         mcu_sck,
    input wire         mcu_cs_n,

    output reg [15:0]  osd_command,

    output reg         busy
);

localparam [7:0] CMD_OSD          = 8'h20;
localparam [7:0] CMD_INIT_START   = 8'hfd;
localparam [7:0] CMD_INIT_DONE    = 8'hfe;
localparam [7:0] CMD_NOPE         = 8'hff;

// spi slave
wire spi_do_valid;
wire [23:0] spi_di, spi_do;
wire spi_di_req;

spi_slave #(.N(24), .CPOL(1'b0), .CPHA(1'b0), .PREFETCH(2)) spi_slave(
    .clk_i         (clk),
    .spi_ssel_i    (mcu_cs_n),
    .spi_sck_i     (mcu_sck),
    .spi_mosi_i    (mcu_mosi),
    .spi_miso_o    (mcu_miso),
    .di_req_o      (spi_di_req),
    .di_i          (spi_di),
    .wren_i        (1'b1),
    .do_valid_o    (spi_do_valid),
    .do_o          (spi_do),
    .do_transfer   (),
    .wren_o        (),
    .wren_ack_o    (),
    .rx_bit_reg_o  (),
    .state_dbg_o   ()
);
assign spi_di = {CMD_NOPE, 16'b0};

// parse incoming spi command
wire [7:0] spi_command = spi_do[23:16];
wire [7:0] spi_address = spi_do[15:8];
wire [7:0] spi_data = spi_do[7:0];
always @(posedge clk) begin
    if (spi_do_valid)
        case (spi_command)
            CMD_OSD: osd_command <= spi_do[15:0];
            CMD_INIT_START: busy <= 1;
            CMD_INIT_DONE: busy <= 0;
        endcase
end

endmodule

