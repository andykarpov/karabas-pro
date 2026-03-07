`default_nettype none
module vga_sync(
    input wire  clk,
    output reg hs,
    output reg vs,
    output reg de,
	 output wire [11:0] h,
	 output wire [11:0] v
);

/*
 ModeLine " 640x 480@60Hz"  25.20  640  656  752  800  480  490  492  525 -HSync -VSync
 ModeLine " 720x 480@60Hz"  27.00  720  736  798  858  480  489  495  525 -HSync -VSync

 Modeline " 800x 600@60Hz"  40.00  800  840  968 1056  600  601  605  628 +HSync +VSync
 Modeline "1024x 600@60Hz"  48.96 1024 1064 1168 1312  600  601  604  622 -HSync +Vsync
 ModeLine "1024x 768@60Hz"  65.00 1024 1048 1184 1344  768  771  777  806 -HSync -VSync
 ModeLine "1280x 720@60Hz"  74.25 1280 1390 1430 1650  720  725  730  750 +HSync +VSync
 ModeLine "1280x 768@60Hz"  80.14 1280 1344 1480 1680  768  769  772  795 +HSync +VSync
 ModeLine "1280x 800@60Hz"  83.46 1280 1344 1480 1680  800  801  804  828 +HSync +VSync
 ModeLine "1280x 960@60Hz" 108.00 1280 1376 1488 1800  960  961  964 1000 +HSync +VSync
 ModeLine "1280x1024@60Hz" 108.00 1280 1328 1440 1688 1024 1025 1028 1066 +HSync +VSync
 ModeLine "1360x 768@60Hz"  85.50 1360 1424 1536 1792  768  771  778  795 -HSync -VSync
 ModeLine "1920x1080@25Hz"  74.25 1920 2448 2492 2640 1080 1084 1089 1125 +HSync +VSync
 ModeLine "1920x1080@30Hz"  89.01 1920 2448 2492 2640 1080 1084 1089 1125 +HSync +VSync
*/

// 800x 600@60Hz (40 pixelclock)
localparam [11:0] h_size = 800-1;
localparam [11:0] h_sync_on = 840-1;
localparam [11:0] h_sync_off = 968-1;
localparam        h_sync_pol = 1'b1;
localparam [11:0] h_end = 1056-1;

localparam [11:0] v_size = 600-1;
localparam [11:0] v_sync_on = 601-1;
localparam [11:0] v_sync_off = 605-1;
localparam        v_sync_pol = 1'b1;
localparam [11:0] v_end = 628-1;

reg [11:0] hcnt;
reg [11:0] vcnt;

always @(posedge clk) begin
	// cnt
	if (hcnt == h_end) begin
		hcnt <= 0;
		if (vcnt == v_end) begin
			vcnt <= 0;
		end else begin
			vcnt <= vcnt + 1;
		end
	end else begin
		hcnt <= hcnt + 1;
	end
	
	// hs
	if (hcnt == h_sync_on)
		hs <= h_sync_pol;
	else if (hcnt == h_sync_off)
		hs <= ~h_sync_pol;
		
	// vs
	if (vcnt == v_sync_on)
		vs <= v_sync_pol;
	else if (vcnt == v_sync_off)
		vs <= ~v_sync_pol;
		
	// de
	if (hcnt <= h_size && vcnt <= v_size)
		de <= 1;
	else
		de <= 0;
		
end

assign h = hcnt;
assign v = vcnt;

endmodule
