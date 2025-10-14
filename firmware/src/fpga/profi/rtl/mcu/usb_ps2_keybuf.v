module usb_ps2_keybuf
    (input wire clk,
	 input wire reset,
	 input wire [7:0] kb_scancode,
	 input wire kb_scancode_upd,
	 input wire keybuf_rd,
    input wire keybuf_reset,
	 output wire [7:0] keybuf_data);

reg [7:0] keybuf_di = 0;
wire [7:0] keybuf_do;
reg prev_kb_scancode_upd = 0;
reg keybuf_wr=0;
reg keybuf_full=0;
wire [10:0] keybuf_data_count;

integer keybuf_size = 0;
reg [127:0] keybuf = 0;
reg keybuf_rd_req = 0;
reg keybuf_wr_req = 0;

always @(posedge clk) begin

	if (keybuf_rd == 1) keybuf_rd_req <= 1;
	if (keybuf_wr == 1) keybuf_wr_req <= 1;
	
	// reset
	if (keybuf_reset == 1) begin
		keybuf <= 0;
		keybuf_size <= 0;
		keybuf_full <= 0;
	end
	// write
	else if (keybuf_wr_req == 1) begin
		keybuf_wr_req <= 0;
		if (keybuf_size < 16) begin 
			keybuf[keybuf_size*8 +:8] <= keybuf_di;
			keybuf_size <= keybuf_size + 1;
			keybuf_full <= 0;
		end
		else begin
			keybuf_full <= 1;
		end
	end
	// read
	else if (keybuf_rd_req == 1) begin
		keybuf_rd_req <= 0;
		keybuf <= {8'h00, keybuf[127:8]};
		if (keybuf_size > 0) keybuf_size <= keybuf_size - 1;
	end
end

assign keybuf_do = keybuf[7:0];
assign keybuf_data = (keybuf_full) ? 8'hFF : keybuf_do;

always @(posedge clk)begin
	keybuf_wr <= 0;
	keybuf_di <= 0;
	if (kb_scancode_upd != prev_kb_scancode_upd) begin
		keybuf_wr <= 1;
		keybuf_di <= kb_scancode;
		prev_kb_scancode_upd <= kb_scancode_upd;
	end
end

endmodule

