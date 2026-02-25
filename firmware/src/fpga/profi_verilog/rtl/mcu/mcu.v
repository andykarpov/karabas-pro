`default_nettype none

module mcu(
    input wire         clk,
    input wire         reset,
    
    input wire         mcu_mosi,
    output wire        mcu_miso,
    input wire         mcu_sck,
    input wire         mcu_cs_n,

    output reg [7:0]   ms_x,
    output reg [7:0]   ms_y,
    output reg [3:0]   ms_z,
    output reg [2:0]   ms_b,
    output reg         ms_upd,

    output reg [7:0]   kb_status,
    output reg [7:0]   kb_dat0,
    output reg [7:0]   kb_dat1,
    output reg [7:0]   kb_dat2,
    output reg [7:0]   kb_dat3,
    output reg [7:0]   kb_dat4,
    output reg [7:0]   kb_dat5,

    output reg [7:0]   kb_scancode,
    output reg         kb_scancode_upd,

    output reg [7:0]   xt_scancode,
    output reg         xt_scancode_upd,

    output reg [12:0]  joystick,

    input wire [7:0]   rtc_a,
    input wire [7:0]   rtc_di,
    output wire [7:0]  rtc_do,
    input wire         rtc_cs,
    input wire         rtc_wr_n,

    output reg [7:0]   usb_uart_rx_data,
    output reg [7:0]   usb_uart_rx_idx,
    input wire [7:0]   usb_uart_tx_data,
    input wire         usb_uart_tx_wr,
    input wire         usb_uart_tx_mode, // 0 - 115200, // 1 - dll/dlm

    input wire [7:0]   usb_uart_dll,
    input wire [7:0]   usb_uart_dlm,
    input wire         usb_uart_dll_wr,
    input wire         usb_uart_dlm_wr,

    output reg [7:0]   esp_uart_rx_data,
    output reg [7:0]   esp_uart_rx_idx,
    input wire [7:0]   esp_uart_tx_data,
    input wire         esp_uart_tx_wr,

    output reg [15:0]  softsw_command,
    output reg [15:0]  osd_command,

    output reg         romloader_active,
    output reg [31:0]  romloader_addr,
    output reg [7:0]   romloader_data,
    output reg         romloader_wr,
     
    input wire [31:0]  flash_a_bus,
    input wire [7:0]   flash_di_bus,
    output reg [7:0]   flash_do_bus,
    input wire         flash_rd_n,
    input wire         flash_wr_n,
    input wire         flash_er_n,
    output reg         flash_busy,
    output reg         flash_ready,

    input wire [15:0]  debug_addr,
    input wire [15:0]  debug_data,
    
    output reg         busy = 1
);

localparam [7:0] CMD_KBD          = 8'h01;
localparam [7:0] CMD_MOUSE        = 8'h02;
localparam [7:0] CMD_JOY          = 8'h03;
localparam [7:0] CMD_BTN          = 8'h04;
localparam [7:0] CMD_SWITCHES     = 8'h05;
localparam [7:0] CMD_ROMBANK      = 8'h06;
localparam [7:0] CMD_ROMDATA      = 8'h07;
localparam [7:0] CMD_ROMLOADER    = 8'h08;
localparam [7:0] CMD_PS2_SCANCODE = 8'h0b;
localparam [7:0] CMD_OSD          = 8'h20;
localparam [7:0] CMD_DEBUG_ADDR   = 8'h30;
localparam [7:0] CMD_DEBUG_DATA   = 8'h31; 
localparam [7:0] CMD_FLASH        = 8'hf9;   
localparam [7:0] CMD_RTC          = 8'hfa;
localparam [7:0] CMD_ESP_UART     = 8'hfb;
localparam [7:0] CMD_USB_UART     = 8'hfc;
localparam [7:0] CMD_INIT_START   = 8'hfd;
localparam [7:0] CMD_INIT_DONE    = 8'hfe;    
localparam [7:0] CMD_NOPE         = 8'hff;

// spi slave
wire spi_do_valid;
wire [23:0] spi_di, spi_do;
wire spi_di_req;
spi_slave #(.N(24), .CPOL(1'b0), .CPHA(1'b0), .PREFETCH(2)) spi_slave(
    .clk_i         (clk),
    .spi_sck_i     (mcu_sck),
    .spi_ssel_i    (mcu_cs_n),
    .spi_mosi_i    (mcu_mosi),
    .spi_miso_o    (mcu_miso),
    .di_req_o      (spi_di_req),
    .di_i          (spi_di),
    .wren_i        (1'b1),
    .do_valid_o    (spi_do_valid),
    .do_o          (spi_do)
);
assign spi_di = queue_do;

// memory for rtc registers
wire [7:0] rtcr_do;
dpram #(.DATAWIDTH(8), .ADDRWIDTH(8)) rtc( 
    .clock         (clk),
    .data_a        (rtcw_di),
    .address_a     (rtcw_a),
    .wren_a        (rtcw_wr),
    .q_a           (),
    .address_b     (rtc_a),
    .data_b        (8'b0),
    .wren_b        (1'b0),
    .q_b           (rtcr_do)
	);
assign rtc_do = rtcr_do;
    
// fifo for write commands to send them on mcu side 
reg [23:0] queue_di;
wire [23:0] queue_do;
reg queue_wr_req;
wire queue_rd_empty, queue_wr_full;

fifo #(.ADDR_WIDTH(6), .DATA_WIDTH(24)) queue(
    .clk           (clk),
    .reset         (reset),

    .empty         (queue_rd_empty),
    .full          (queue_wr_full),
		
    .rd            (queue_rd_req),
    .dout          (queue_do),
		
    .wr            (queue_wr_req),
    .din           (queue_di)
	);

// pull queue data
reg prev_spi_di_req;
reg queue_rd_req;
always @(posedge clk) begin
    queue_rd_req <= 0;
    if (spi_di_req && ~prev_spi_di_req)
        queue_rd_req <= 1;
    prev_spi_di_req <= spi_di_req;
end

// parse incoming spi command
wire [7:0] spi_command = spi_do[23:16];
wire [7:0] spi_address = spi_do[15:8];
wire [7:0] spi_data = spi_do[7:0];
reg rtcr_command;
reg [31:0] tmp_romload_addr;
reg [15:0] prev_debug_addr, prev_debug_data;
reg prev_spi_do_valid = 0;
always @(posedge clk) begin
    prev_spi_do_valid <= spi_do_valid;
    if (spi_do_valid && ~prev_spi_do_valid)
        case (spi_command)
            CMD_KBD: 
                case (spi_address)
                    0: kb_status <= spi_data;
                    1: kb_dat0 <= spi_data;
                    2: kb_dat1 <= spi_data;
                    3: kb_dat2 <= spi_data;
                    4: kb_dat3 <= spi_data;
                    5: kb_dat4 <= spi_data;
                    6: kb_dat5 <= spi_data;
                endcase
            CMD_MOUSE:
                case (spi_address)
                    0: ms_x <= spi_data;
                    1: ms_y <= spi_data;
                    2: ms_z <= spi_data[3:0];
                    3: begin ms_b <= spi_data[2:0]; ms_upd <= ~ms_upd; end
                endcase
            CMD_JOY:
                case (spi_address)
                    0: joystick[7:0] <= spi_data[7:0]; // B A START RIGHT LEFT DOWN UP ON
                    1: joystick[12:8] <= spi_data[4:0]; // MODE Z Y X C
                endcase
            CMD_SWITCHES: softsw_command <= {spi_address, spi_data};
            CMD_OSD: osd_command <= {spi_address, spi_data};
            CMD_ROMLOADER: romloader_active <= spi_data[0];
            CMD_ROMBANK:
                case (spi_address)
                    0: tmp_romload_addr[15:8] <= spi_data;
                    1: tmp_romload_addr[23:16] <= spi_data;
                    2: tmp_romload_addr[31:24] <= spi_data;
                endcase
            CMD_ROMDATA:
            begin
                romloader_addr[31:0] <= {tmp_romload_addr[31:8], spi_address};
                romloader_data[7:0] <= spi_data;
            end
            CMD_RTC:
            begin
                rtcr_a <= spi_address;
                rtcr_d <= spi_data;
                rtcr_command <= ~rtcr_command;
            end
            CMD_USB_UART:
            begin
                usb_uart_rx_data <= spi_data;
                usb_uart_rx_idx <= spi_address;
            end
            CMD_ESP_UART:
            begin
                esp_uart_rx_data <= spi_data;
                esp_uart_rx_idx <= spi_address;
            end
                CMD_FLASH:
                begin
                    flash_busy <= spi_address[0];
                    flash_ready <= spi_address[1];
                    flash_do_bus <= spi_data;
                end
            CMD_PS2_SCANCODE:
                case (spi_address)
                    0: begin kb_scancode <= spi_data; kb_scancode_upd <= ~kb_scancode_upd; end
                    1: begin xt_scancode <= spi_data; xt_scancode_upd <= ~xt_scancode_upd; end
                endcase
            CMD_INIT_START: busy <= 1;
            CMD_INIT_DONE: busy <= 0;
            
        endcase
end

// romloader wr strobe
reg [31:0] prev_romloader_addr = 32'hFFFFFFFF;
always @(posedge clk) begin
    romloader_wr <= 0;
    if (prev_romloader_addr != romloader_addr && romloader_active) begin
        romloader_wr <= 1;
        prev_romloader_addr <= romloader_addr;
    end
end

// fifo handling / queue commands to mcu side
reg [7:0] rtcr_a, rtcr_d, last_rtcr_a, last_rtcr_d;
reg [31:0] prev_flash_a_bus;
reg prev_flash_wr_n, prev_flash_rd_n, prev_flash_er_n;
always @(posedge clk) begin
    queue_wr_req <= 0;
     prev_flash_wr_n <= flash_wr_n;
     prev_flash_rd_n <= flash_rd_n;
     prev_flash_er_n <= flash_er_n;
    if (usb_uart_tx_wr) begin
        queue_wr_req <= 1;
        case (usb_uart_tx_mode)
            0: queue_di <= {CMD_USB_UART, 8'b00000000, usb_uart_tx_data}; // zifi rs232 - usb
                1: queue_di <= {CMD_USB_UART, 8'b00000011, usb_uart_tx_data}; // evo rs232 - usb
        endcase
    end
    else if (usb_uart_dll_wr) begin queue_wr_req <= 1; queue_di <= {CMD_USB_UART, 8'b00000001, usb_uart_dll}; end 
    else if (usb_uart_dlm_wr) begin queue_wr_req <= 1; queue_di <= {CMD_USB_UART, 8'b00000010, usb_uart_dlm}; end 
     else if (esp_uart_tx_wr)  begin queue_wr_req <= 1; queue_di <= {CMD_ESP_UART, 8'b00000000, esp_uart_tx_data}; end
    else if (~rtc_wr_n && rtc_cs && ~busy && rtc_a != 8'h0c && rtc_a < 8'hf0) begin queue_wr_req <= 1; queue_di <= {CMD_RTC, rtc_a, rtc_di}; end
     else if (flash_a_bus[31:24] != prev_flash_a_bus[31:24]) begin queue_wr_req <= 1; queue_di <= {CMD_FLASH, 8'h00, flash_a_bus[31:24]}; prev_flash_a_bus[31:24] <= flash_a_bus[31:24]; end
     else if (flash_a_bus[23:16] != prev_flash_a_bus[23:16]) begin queue_wr_req <= 1; queue_di <= {CMD_FLASH, 8'h01, flash_a_bus[23:16]}; prev_flash_a_bus[23:16] <= flash_a_bus[23:16]; end
     else if (flash_a_bus[15:8]  != prev_flash_a_bus[15:8])  begin queue_wr_req <= 1; queue_di <= {CMD_FLASH, 8'h02, flash_a_bus[15:8]};  prev_flash_a_bus[15:8]  <= flash_a_bus[15:8]; end
     else if (flash_a_bus[7:0]   != prev_flash_a_bus[7:0])   begin queue_wr_req <= 1; queue_di <= {CMD_FLASH, 8'h03, flash_a_bus[7:0]};   prev_flash_a_bus[7:0]   <= flash_a_bus[7:0]; end
     else if (~flash_wr_n && prev_flash_wr_n) begin queue_wr_req <= 1; queue_di <= {CMD_FLASH, 8'h04, flash_di_bus}; end
     else if (~flash_rd_n && prev_flash_rd_n) begin queue_wr_req <= 1; queue_di <= {CMD_FLASH, 8'h05, 8'h00}; end
     else if (~flash_er_n && prev_flash_er_n) begin queue_wr_req <= 1; queue_di <= {CMD_FLASH, 8'h06, 8'h00}; end
    else if (debug_addr != prev_debug_addr) begin queue_wr_req <= 1; queue_di <= {CMD_DEBUG_ADDR, debug_addr}; prev_debug_addr <= debug_addr; end
    else if (debug_data != prev_debug_data) begin queue_wr_req <= 1; queue_di <= {CMD_DEBUG_DATA, debug_data}; prev_debug_data <= debug_data; end
    else if (queue_rd_empty) begin queue_wr_req <= 1; queue_di <= {CMD_NOPE, 16'b0}; end

end

// write RTC registers into ram from host / mcu
reg [7:0] rtcw_di, rtcw_a;
reg rtcw_wr;
reg last_rtcr_command;
always @(posedge clk) begin
    rtcw_wr <= 0;
    if (~rtc_wr_n && rtc_cs && ~busy) begin
        rtcw_wr <= 1; rtcw_a <= rtc_a; rtcw_di <= rtc_di;
    end 
    else if (last_rtcr_command != rtcr_command) begin
        rtcw_wr <= 1; rtcw_a <= rtcr_a; rtcw_di <= rtcr_d; last_rtcr_command <= rtcr_command;    
    end
end

endmodule

