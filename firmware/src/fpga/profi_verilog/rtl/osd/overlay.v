`default_nettype none

module overlay (
    input wire          clk_bus,
    input wire          clk,
    input wire          ds80, // todo
    input wire [8:0]    rgb,
    output wire [8:0]   rgb_o,
    input wire          hs,
    input wire          vs,
    input wire [15:0]   osd_command,
    input wire          icon_cf, // todo
    input wire          icon_sd,
    input wire          icon_fdd
);

parameter DEFAULT  = 0;
parameter H_OFFSET = 32;
parameter V_OFFSET = 60;

localparam [10:0] paper_chars_h = 32; // count of characters in row
localparam [10:0] paper_chars_v = 26; // count of characters in column
localparam [10:0] paper_start_h = 0; 
localparam [10:0] paper_end_h   = paper_chars_h * 8;
localparam [10:0] paper_start_v = 0;
localparam [10:0] paper_end_v   = paper_chars_v * 8;

// todo: detect hs/vs polarity
localparam hsync_pol = 0;
localparam vsync_pol = 0;

wire hsync = hs;
wire vsync = vs;

// hcnt, vcnt, width, height
reg [10:0] hcnt_i, vcnt_i;
reg [10:0] width, height;
reg prev_hsync, prev_vsync;
reg [7:0] flash_cnt;
always @(posedge clk_bus) begin
    if (~clk) begin // negedge of video clk
		 prev_hsync <= hsync;
		 if (hsync == hsync_pol && prev_hsync != hsync) begin // new line (start of hsync pulse)
			  width <= hcnt_i;
			  hcnt_i <= 11'b00000000000;
			  vcnt_i <= vcnt_i + 1;
			  prev_vsync <= vsync;
			  if (vsync == vsync_pol && prev_vsync != vsync) begin // start of new frame (vsync pulse)
					height <= vcnt_i;
					vcnt_i <= 11'b00000000000;
					flash_cnt <= flash_cnt + 1;
			  end
		 end
		 else 
			  hcnt_i <= hcnt_i + 1;
    end

end

// normalize h/v values
wire [10:0] hcnt = (width < 500)  ? hcnt_i[10:0] - H_OFFSET         :
                   (width < 1200) ? {1'b0, hcnt_i[10:1]} - H_OFFSET :
                                    {2'b00, hcnt_i[10:2]} - H_OFFSET;

wire [10:0] vcnt = (height < 400) ? vcnt_i[10:0] - V_OFFSET         :
                   (height < 800) ? {1'b0, vcnt_i[10:1]} - V_OFFSET :
                                    {2'b00, vcnt_i[10:2]} - V_OFFSET;

// 8x8 font RAM (2kb)
wire [7:0] font_word;
dpram #(.DATAWIDTH(8), .ADDRWIDTH(11)) font_ram (
    .clock      (clk_bus),
    .address_a  (osdfont_addr),
    .data_a     (osdfont_data),
    .wren_a     (osdfont_we),
    .address_b  (rom_addr),
    .data_b     (8'b0),
    .wren_b     (1'b0),
    .q_b        (font_word)
);

// OSD VRAM (2kb)
wire [15:0] vram_do;
dpram #(.DATAWIDTH(16), .ADDRWIDTH(10)) v_ram (
    .clock      (clk_bus),
    .address_a  (addr_write),
    .data_a     (vram_di),
    .wren_a     (vram_wr),
    .address_b  (addr_read),
    .data_b     (16'b0),
    .wren_b     (1'b0),
    .q_b        (vram_do)
);

wire flash = flash_cnt[5];
wire [2:0] char_x = (osd_popup) ? hcnt[3:1] : hcnt[2:0];
wire [2:0] char_y = (osd_popup) ? vcnt[3:1] : vcnt[2:0];
wire paper2 = (hcnt >= paper_start_h && hcnt < paper_end_h && vcnt >= paper_start_v && vcnt < paper_end_v) ? 1'b1 : 1'b0;
wire paper =  (hcnt >= paper_start_h + 8 && hcnt < paper_end_h + 8 && vcnt >= paper_start_v && vcnt < paper_end_v) ? 1'b1 : 1'b0;
wire video_on = (osd_overlay || osd_popup || DEFAULT) ? 1'b1 : 1'b0;

// mem read character / attribute
reg [9:0] addr_read;
reg [7:0] attr, attr2;
always @(posedge clk_bus) begin
    if (clk) begin
		 if (osd_popup) 
			  case (hcnt[3:0])
					4'b1110: if (paper2) addr_read <= {vcnt[8:4], hcnt[8:4]};
					4'b1111: attr2 <= vram_do[7:0];
					4'b0000: attr <= attr2;
			  endcase 
		 else
			  case (char_x)
					3'b110: if (paper2) addr_read <= {vcnt[7:3], hcnt[7:3]};
					3'b111: attr <= vram_do[7:0];
			  endcase
	end
end

// pixel load from font
reg [10:0] rom_addr;
always @(posedge clk_bus) begin
	 if (clk && char_x == 3'b111)
		  rom_addr <= {vram_do[15:8], char_y};
end

reg load_pixel;
always @(posedge clk_bus) begin
    if (~clk) begin
		 load_pixel <= 0;
		 if (((~osd_popup && char_x == 3'b111) || (osd_popup && hcnt[3:0] == 4'b1111)) && ~load_pixel)
			  load_pixel <= 1;
	 end
end

// pixel doubler
wire pixel_reg;
pix_doubler pix_doubler (
    .clk_bus    (clk_bus),
    .clk        (clk),
    .load       (load_pixel),
    .d          (font_word),
    .quad       (osd_popup),
    .dout       (pixel_reg)
);

wire is_flash = (attr[3:0] == 4'b0001) ? 1'b1 : 1'b0;
wire [3:0] selector = {video_on, pixel_reg, flash, is_flash};
wire [8:0] rgb_fg = {attr[7] && attr[4], attr[7], attr[7], attr[6] && attr[4], attr[6], attr[6], attr[5] && attr[4], attr[5], attr[5]};
wire [8:0] rgb_bg = {attr[3] && attr[0], attr[3], attr[3], attr[2] && attr[0], attr[2], attr[2], attr[1] && attr[0], attr[1], attr[1]};
wire sel_fg = (selector == 4'b1111 || selector == 4'b1001 || selector == 4'b1100 || selector == 4'b1110) ? 1'b1 : 1'b0;
wire sel_bg = (selector == 4'b1011 || selector == 4'b1101 || selector == 4'b1000 || selector == 4'b1010) ? 1'b1 : 1'b0;
assign rgb_o = (rgb_fg != 9'b0 && paper && sel_fg) ? rgb_fg :
               (rgb_bg != 9'b0 && paper && sel_bg) ? rgb_bg :
               (video_on) ? {1'b0, rgb[8:7], 1'b0, rgb[5:4], 1'b0, rgb[2:1]} : rgb;

// data receiver
reg vram_wr;
reg [15:0] last_osd_command;
reg [10:0] osdfont_addr = 11'b11111111111;
reg [7:0] osdfont_data;
reg [9:0] addr_write;
reg [7:0] char_buf;
reg [15:0] vram_di;
reg osd_overlay, osd_popup;
reg osdfont_upd, osdfont_prev_upd, osdfont_we;
always @(posedge clk_bus) begin
    //if (clk) begin
		 vram_wr <= 0;
		 last_osd_command <= osd_command;
		 if (osd_command != last_osd_command) begin 
			  
			  case (osd_command[15:8]) 
					8'h01: begin vram_wr <= 0; osd_overlay <= osd_command[0]; end // osd enabled
					8'h02: begin vram_wr <= 0; osd_popup <= osd_command[0]; end // popup enabled
					8'h10: begin vram_wr <= 0; addr_write[4:0] <= osd_command[4:0]; end // x: 0...32
					8'h11: begin vram_wr <= 0; addr_write[9:5] <= osd_command[4:0]; end // y: 0...32
					8'h12: begin vram_wr <= 0; char_buf <= osd_command[7:0]; end // char
					8'h13: begin vram_wr <= 1; vram_di <= {char_buf, osd_command[7:0]}; end // attrs
					8'h20: if (osd_command[0]) begin 
							  osdfont_addr <= 11'b11111111111;
							  osdfont_upd <= 0;
							  osdfont_prev_upd <= 0;
						 end // reset font addr
					8'h21: begin 
							  osdfont_addr <= osdfont_addr + 1;
							  osdfont_data <= osd_command[7:0];
							  osdfont_upd <= ~osdfont_upd;
						 end // new font data
			  endcase
		 end

		 // wr signal / osd font loader
		 osdfont_we <= 0;
		 osdfont_prev_upd <= osdfont_upd;
		 if (osdfont_prev_upd != osdfont_upd) begin
			  osdfont_we <= 1;
		 end
	//end
end

endmodule

// pixel doubler
module pix_doubler(
    input wire       clk_bus,
    input wire       clk,
    input wire       load,
    input wire [7:0] d,
    input wire       quad,
    output wire      dout
);

reg [15:0] shift_16;
reg [31:0] shift_32;

always @(posedge clk_bus) begin
    if (~clk) begin
		 if (load) begin
			  shift_16 <= {d[7], d[7], d[6], d[6], d[5], d[5], d[4], d[4], d[3], d[3], d[2], d[2], d[1], d[1], d[0], d[0]};
			  shift_32 <= {d[7], d[7], d[7], d[7], d[6], d[6], d[6], d[6], d[5], d[5], d[5], d[5], d[4], d[4], d[4], d[4],
								d[3], d[3], d[3], d[3], d[2], d[2], d[2], d[2], d[1], d[1], d[1], d[1], d[0], d[0], d[0], d[0]};
		 end else begin 
			  shift_16 <= {shift_16[14:0], 1'b0};
			  shift_32 <= {shift_32[30:0], 1'b0};
		 end
	 end
end

assign dout = (quad) ? shift_32[31] : shift_16[15];

endmodule

