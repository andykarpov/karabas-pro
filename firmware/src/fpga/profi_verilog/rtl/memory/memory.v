`default_nettype none

module memory(
    input wire clk,
    input wire cpu_ena,
    input wire vid_ena,

    input wire [15:0] a,
    input wire [7:0] di,
    input wire iorq_n,
    input wire mreq_n,
    input wire rd_n,
    input wire wr_n,
    input wire m1_n,

    input wire loader_act,
    input wire [20:0] loader_a,
    input wire [7:0] loader_d,
    input wire loader_wr,

    output wire [7:0] do,
    output wire oe_n = 1,

    output wire [20:0] ma,
    inout wire [7:0] md = 8'bz,
    output wire mwr_n = 1,
    output wire mrd_n = 1,

    input wire [2:0] ram_bank,
    input wire [2:0] ram_ext,

    input wire trdos,

    input wire [13:0] va,
    output wire [7:0] vd,
    input wire vid_page,
    output reg vbus_mode,
    output reg vid_rd,
    input wire [2:0] vid_col,

    input wire ds80,
    input wire sco,
    input wire scr,
    input wire worom,

    input wire rom_bank,
    input wire [1:0] ext_rom_bank
);

wire vbus_req = ((~mreq_n || ~iorq_n) && (~wr_n || ~rd_n)) ? 0 : 1;
wire vbus_rdy = (~vid_ena || ~vid_col[0]) ? 0 : 1;

wire is_rom = (~mreq_n && a[15:14] == 2'b00 && ~worom) ? 1 : 0;
wire is_ram = (~mreq_n && ~is_rom) ? 1 : 0;
wire [1:0] rom_page = {~trdos, rom_bank};
assign oe_n = ((is_ram || is_rom) && ~rd_n) ? 0 : 1;

assign mrd_n = (loader_act) ? 1 : 
               (is_rom && ~rd_n && ~mreq_n) ? 0 : 
               (vbus_mode && ~vbus_rdy) ? 0 : 
               (~vbus_mode && ~rd_n && ~mreq_n) ? 0 : 1;
assign mwr_n = (loader_act) ? ~loader_wr : 
               (~vbus_mode && is_ram && ~wr_n && ~vid_col[0]) ? 0 : 1;

wire is_buf_wr = (~vbus_mode && ~vid_col[0]) ? 1 : 0; 

assign do = buf_md;
assign vd = md;

assign ma = (loader_act) ? loader_a[20:0] : 
            (is_rom && ~vbus_mode) ? {3'b100, ext_rom_bank[1:0], rom_page[1:0], a[13:0]} : // rom
            (~is_rom && ~vbus_mode) ? {ram_page[6:0], a[13:0]} :  // ram
            (vbus_mode && ~ds80) ? {5'b00001, vid_page, 1'b1, va[13:0]} : // spectrum vram
            (vbus_mode && ds80 && ~vid_rd) ? {5'b00001, vid_page, 1'b0, va[13:0]} :  // profi vram bitmap
            (vbus_mode && ds80 && vid_rd) ? {5'b01110, vid_page, 1'b0, va[13:0]} : {7'b0000000, va[13:0]}; // profi vram attr

assign md = (loader_act && loader_wr) ? loader_d : 
            (~loader_act && ~vbus_mode && ~wr_n && (is_ram || (~iorq_n && m1_n))) ? di : 8'bz;

// fill memory buf
reg [7:0] buf_md;
always @(negedge is_buf_wr) begin
    buf_md <= md;
end

// vbus access
reg vbus_ack;
always @(posedge clk) begin
    if (~vid_ena && vid_col[0]) begin
        if (~vbus_req && vbus_ack)
            vbus_mode <= 0;
        else begin
            vbus_mode <= 1;
            vid_rd <= ~vid_rd;
        end
        vbus_ack <= vbus_req;
    end
end

// ram page
reg [8:0] ram_page = 0;
always @(*) begin
    case (a[15:14])
        2'b00: ram_page <= 9'b000000000; // Seg0 ROM 0000-3FFF or Seg0 RAM 0000-3FFF
        2'b01: ram_page <= (~sco) ? 9'b000000101 : {3'b000, ram_ext[2:0], ram_bank[2:0]}; // Seg1 RAM 4000-7FFF
        2'b10: ram_page <= (~scr) ? 9'b000000010 : 9'b000000110; // Seg2 RAM 8000-BFFF
        2'b11: ram_page <= (~sco) ? {3'b000, ram_ext[2:0], ram_bank[2:0]} : 9'b000000111; // Seg3 RAM C000-FFFF
    endcase
end

endmodule

