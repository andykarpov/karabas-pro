`timescale 1ns / 1ps
`default_nettype none

// Modeline " 800x 600@60Hz"  40.00  800  840  968 1056  600  601  605  628 +HSync +VSync
module sync_generator_vga (
    input wire clk,   // 40 MHz
    output reg hsync,
    output reg vsync,
    output reg blank,
    output wire [11:0] hc,
    output wire [11:0] vc
    );
    
    reg [11:0] h = 10'd0;
    reg [11:0] v = 10'd0;
    assign hc = h;
    assign vc = v;
    
    always @(posedge clk) begin
		if (h == 1056-1) begin
			 h <= 0;
			 if (v == 628-1) begin
				  v <= 0;
			 end
			 else
				  v <= v + 1;
		end
		else
			 h <= h + 1;
    end
    
    reg vblank, hblank;
    always @* begin
        vblank = 1'b0;
        hblank = 1'b0;
        vsync = 1'b0;
        hsync = 1'b0;
			if (v >= 600) begin
				 vblank = 1'b1;
				 if (v >= 601 && v < 605) begin
					  vsync = 1'b1;
				 end
			end
			if (h >= 800) begin
				 hblank = 1'b1;
				 if (h >= 840 && h < 968) begin
					  hsync = 1'b1;
				 end
			end
        blank = hblank | vblank;
    end
endmodule
