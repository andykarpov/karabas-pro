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

    output reg [7:0]   uart_rx_data,
    output reg [7:0]   uart_rx_idx,

    input wire [7:0]   uart_tx_data,
    input wire         uart_tx_wr,
    input wire [1:0]   uart_tx_mode, // 0 - zifi rs232 @ 115200, // 1 - evo rs232 @ dll/dlm, 2 - zifi esp8266 @ 115200 

    input wire [7:0]   uart_dll,
    input wire [7:0]   uart_dlm,
    input wire         uart_dll_wr,
    input wire         uart_dlm_wr,

    output reg [15:0]  softsw_command,
    output reg [15:0]  osd_command,

    output reg         romloader_active,
    output reg [31:0]  romloader_addr,
    output reg [7:0]   romloader_data,
    output reg         romloader_wr,

    input wire [15:0]  debug_addr,
    input wire [15:0]  debug_data,
    
    output reg         busy
);

localparam CMD_KBD          = 8'h01;
localparam CMD_MOUSE        = 8'h02;
localparam CMD_JOY          = 8'h03;
localparam CMD_BTN          = 8'h04;
localparam CMD_SWITCHES     = 8'h05;
localparam CMD_ROMBANK      = 8'h06;
localparam CMD_ROMDATA      = 8'h07;
localparam CMD_ROMLOADER    = 8'h08;
localparam CMD_PS2_SCANCODE = 8'h0b;
localparam CMD_OSD          = 8'h20;
localparam CMD_DEBUG_ADDR   = 8'h30;
localparam CMD_DEBUG_DATA   = 8'h31;    
localparam CMD_RTC          = 8'hfa;
localparam CMD_UART         = 8'hfc;
localparam CMD_INIT_START   = 8'hfd;
localparam CMD_INIT_DONE    = 8'hfe;    
localparam CMD_NOPE         = 8'hff;

// spi slave
wire spi_do_valid;
wire [23:0] spi_di, spi_do;
wire spi_di_req;

spi_slave #(.N(24)) spi_slave(
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
dpram #(.DATAWIDTH(8), .ADDRWIDTH(8)) rtc_ram(
    .clock         (clk),
    .data_a        (rtcw_di),
    .address_a     (rtcw_a),
    .wren_a        (rtcw_wr),
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

fifo #(.ADDR_WIDTH(9), .DATA_WIDTH(24)) fifo(
    .clk          (clk),
    .reset        (reset),
    .empty        (queue_rd_empty),
    .full         (queue_wr_full),
    .rd           (queue_rd_req),
    .dout         (queue_do),
    .wr           (queue_wr_req),
    .din          (queue_di)
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
always @(posedge clk) begin
    if (spi_do_valid)
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
            CMD_SWITCHES: softsw_command <= spi_do[15:0];
            CMD_OSD: osd_command <= spi_do[15:0];
            CMD_ROMLOADER: romloader_active <= spi_do[0];
            CMD_ROMBANK:
                case (spi_address)
                    0: tmp_romload_addr[15:8] <= spi_data;
                    1: tmp_romload_addr[23:16] <= spi_data;
                    2: tmp_romload_addr[31:24] <= spi_data;
                endcase
            CMD_ROMDATA:
            begin
                romloader_addr[31:8] <= tmp_romload_addr[31:8];
                romloader_addr[7:0] <= spi_do[15:8];
                romloader_data[7:0] <= spi_do[7:0];
            end
            CMD_RTC:
            begin
                rtcr_a <= spi_address;
                rtcr_d <= spi_data;
                rtcr_command <= ~rtcr_command;
            end
            CMD_UART:
            begin
                uart_rx_data <= spi_data;
                uart_rx_idx <= spi_address;
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
always @(posedge clk) begin
    queue_wr_req <= 0;
    if (uart_tx_wr) begin
        queue_wr_req <= 1;
        case (uart_tx_mode)
            1: queue_di <= {CMD_UART, 8'b00000011, uart_tx_data}; // evo rs232 - usb
            0: queue_di <= {CMD_UART, 8'b00000000, uart_tx_data}; // zifi rs232 - usb
            // todo: esp8266 access
        endcase
    end
    else if (uart_dll_wr) begin queue_wr_req <= 1; queue_di <= {CMD_UART, 8'b00000001, uart_dll}; end 
    else if (uart_dlm_wr) begin queue_wr_req <= 1; queue_di <= {CMD_UART, 8'b00000010, uart_dlm}; end 
    else if (~rtc_wr_n && rtc_cs && ~busy && rtc_a != 8'h0c && rtc_a < 8'hf0) begin queue_wr_req <= 1; queue_di <= {CMD_RTC, rtc_a, rtc_di}; end
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

