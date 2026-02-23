`default_nettype none

module video(
    input wire clk, // system bus clock
    input wire ena, // pixel ena 7 / 12 MHz
    input wire reset,
    input wire ds80, // 1 - profi screen, 0 - pentagon screen

    output wire [15:0] a, // video address (64kb address space)
    input wire [7:0] di, // video data from memory
    input wire vbus_mode, // 1 = video, 0 = cpu
    input wire vid_rd, // video mem read mode: 1 = attr, 0 = bitmap

    input wire [7:0] border, // border color (port #FE)
    input wire cs7e, // palette port write #7E
    input wire [15:8] bus_a, // upper cpu address bus
    input wire bus_wr_n, // cpu write signal
    output wire gx0, // gx0 component for palette detection

    input wire turbo, // turbo mode
    input wire inta, // interrupt request (in turbo mode)
    output wire [7:0] attr_o, // attribute output
    output wire pff_cs, // port #FF select

    output wire [2:0] vid_col,
    
    output wire [8:0] rgb, // rgb 3:3:3
    output reg hs, // hsync
    output reg vs, // vsync
    output wire cs, // composite sync
    output wire int // video interrupt
);

reg [2:0] chr_col_cnt = 0;
reg [2:0] chr_row_cnt = 0;
reg [6:0] hor_cnt = 0;
reg [5:0] ver_cnt = 0;
reg [4:0] invert = 0;
reg int_sig = 0;
reg bl_int = 0;
assign vid_col = chr_col_cnt;

always @(posedge clk) begin
    if (!ds80 && ena) begin // pentagon screen

        // h/v counters        
        if (chr_col_cnt == 7) begin
            hor_cnt <= (hor_cnt == 55) ? 0 : hor_cnt + 1;
            if (hor_cnt == 39) begin
                if (chr_row_cnt == 7) begin
                    if (ver_cnt == 39) begin
                        ver_cnt <= 0;
                        invert <= invert + 1;
                    end else begin
                        ver_cnt <= ver_cnt + 1;
                    end
                end
                chr_row_cnt <= chr_row_cnt + 1;
            end
        end
        chr_col_cnt <= chr_col_cnt + 1;

        // h/v sync
        if (chr_col_cnt == 7) begin
            hs <= (hor_cnt[5:2] == 4'b1010) ? 0 : 1;
            if (ver_cnt != 31)
                vs <= 1;
            else if ((chr_row_cnt == 3) || (chr_row_cnt == 4) || ((chr_row_cnt == 5) && ((hor_cnt >= 40) || (hor_cnt < 12))))
                vs <= 0;
            else
                vs <= 1;
        end

        // int
        if (~turbo) // turbo int
            if ((chr_col_cnt == 6) && (hor_cnt[1:0] == 2'b11))
                if ((ver_cnt == 29) && (chr_row_cnt == 7) && (hor_cnt[5:2] == 4'b1001))
                    int_sig <= 0;
                else
                    int_sig <= 1;
        else // normal pentagon int
            if ((chr_col_cnt == 6) && (hor_cnt[2:0] == 3'b111))
                if ((ver_cnt == 29) && (chr_row_cnt == 7) && (hor_cnt [5:3] == 3'b100))
                    int_sig <= 0;
                else
                    int_sig <= 1;
    
    end else if (ds80 && ena) begin // profi screen

        // h/v counters        
        if (chr_col_cnt == 7) begin
            hor_cnt <= (hor_cnt == 95) ? 0 : hor_cnt + 1;
            if (hor_cnt == 71) begin
                if (chr_row_cnt == 7) begin
                    if (ver_cnt == 38) begin
                        ver_cnt <= 0;
                        invert <= invert + 1;
                    end else begin
                        ver_cnt <= ver_cnt + 1;
                    end
                end
                chr_row_cnt <= chr_row_cnt + 1;
            end
        end
        chr_col_cnt <= chr_col_cnt + 1;

        // h/v sync
        if (chr_col_cnt == 7) begin
            hs <= (hor_cnt[6:3] == 4'b1001) ? 0 : 1;
            if (ver_cnt != 31)
                vs <= 1;
            else if ((chr_row_cnt == 3) || (chr_row_cnt == 4) || ((chr_row_cnt == 5) && ((hor_cnt >= 40) || (hor_cnt < 12))))
                vs <= 0;
            else
                vs <= 1;
        end

        // int
        if (~turbo) // turbo int
            if ((chr_col_cnt == 6) && (hor_cnt[1:0] == 2'b10))
                if ((ver_cnt == 32) && (chr_row_cnt == 7) && (hor_cnt[6:2] == 5'b10010))
                    int_sig <= 0;
                else
                    int_sig <= 1;
        else // normal profi 5 int
            if ((chr_col_cnt == 6) && (hor_cnt[2:0] == 3'b010))
                if ((ver_cnt == 32) && (chr_row_cnt == 7) && (hor_cnt [6:3] == 4'b1010))
                    int_sig <= 0;
                else
                    int_sig <= 1;
    end

    // bl int
    if (!inta)
        bl_int <= 1;
    else if (hor_cnt[1])
        bl_int <= ~int_sig;

end

wire i78 = (ds80) ? attr_r[7] : attr_r[6];
reg [3:0] irgb = 0;

// irgb
always @(posedge clk) begin
    if (!paper_r)
        if (shift_r[7] ^ (attr_r[7] && (invert[4] && ~ds80)))
            irgb <= {attr_r[6], attr_r[1], attr_r[2], attr_r[0]};
        else
            irgb <= {i78, attr_r[4], attr_r[5], attr_r[3]};
    else
        if (~blank_r) 
            irgb <= 4'b0000;
        else
            if (!ds80)
                irgb <= {1'b0, border[1], border[2], border[0]};
            else
                irgb <= {~border[3] & bl_int, ~border[1], ~border[2], ~border[0]};
end

// paper / blank
reg paper_r = 0;
reg blank_r = 0;
always @(posedge clk) begin
    if (ena)
        if (~ds80) // pentagon
            if (chr_col_cnt == 7) begin
                if (((hor_cnt[5:0] > 38) && (hor_cnt[5:0] < 48)) || (ver_cnt[5:1] == 15)) // 256x192
                    blank_r <= 0;
                else
                    blank_r <= 1;
                paper_r <= paper;
            end
        else // profi
            if (chr_col_cnt == 7) begin
                if (((hor_cnt[6:0] > 67) && (hor_cnt[6:0] < 92)) || ((ver_cnt[5:0] > 31) && (ver_cnt[5:0] < 37))) // 512x240
                    blank_r <= 0;
                else
                    blank_r <= 1;
                paper_r <= paper;
            end
end

// bitmap shift registers
reg [7:0] shift_r = 0;
reg [7:0] attr_r = 0;
always @(posedge clk) begin
    if (ena)
        if (chr_col_cnt == 7) begin
            attr_r <= attr;
            shift_r <= bitmap;
        end else begin
            shift_r <= {shift_r[6:0], 1'b0};
        end
end

// video mem read cycle
reg [7:0] bitmap;
reg [7:0] attr;
always @(posedge clk) begin
    if (~ds80 && chr_col_cnt[0] && vbus_mode && ~ena)
        if (~vid_rd)
            bitmap <= di;
        else
            attr <= di;
    else if (ds80 && (chr_col_cnt < 7) && vbus_mode && ~ena)
        if (~vid_rd)
            bitmap <= di;
        else
            attr <= di;
end

wire paper = ((~hor_cnt[5] && (ver_cnt[5:0] < 24) && ~ds80) || 
              (~hor_cnt[6] && (ver_cnt[5:0] < 30) &&  ds80)) ? 0 : 1;

assign a =  (~ds80 && vbus_mode && ~vid_rd) ? {1'b0, ver_cnt[4:3], chr_row_cnt, ver_cnt[2:0], hor_cnt[4:0]} : // pent pix
            (~ds80 && vbus_mode && vid_rd) ? {4'b0110, ver_cnt[4:0], hor_cnt[4:0]} : // pent attr
            (ds80 && vbus_mode) ? {~hor_cnt[0], ver_cnt[4:3], chr_row_cnt, ver_cnt[2:0], hor_cnt[5:1]} : // profi pix / attr
            14'b0;

assign attr_o = attr_r;
assign int = int_sig;
assign pff_cs = paper;
assign cs = ~(vs ^ hs);

// Karabas Profi palette:

// 1) Karabas Profi palette is a memory of 16 elements. Each cell is a 9 bit value of color (GGGRRRBBB)
// 2) Palette data written as inverted cpu address bus [15:8] + border[7] by address defined in the port #FE (also inverted value)
// 3) Write strobe is produced by accessing the palette port #7E in the DS80 mode
// 4) While reading palette the address is a color code (YGBR) from the video controller

// palette write
reg [8:0] palette [0:15];
always @(posedge clk, posedge reset) begin
    if (reset) begin
        // default palette (spectrum colors)
        palette[0] <= 9'b000000000;
        palette[1] <= 9'b000000100;
        palette[2] <= 9'b000100000;
        palette[3] <= 9'b000100100;
        palette[4] <= 9'b100000000;
        palette[5] <= 9'b100000100;
        palette[6] <= 9'b100100000;
        palette[7] <= 9'b100100100;
        palette[8] <= 9'b000000000;
        palette[9] <= 9'b000000110;
        palette[10] <= 9'b000110000;
        palette[11] <= 9'b000110110;
        palette[12] <= 9'b110000000;
        palette[13] <= 9'b110000110;
        palette[14] <= 9'b110110000;
        palette[15] <= 9'b110110110;
    end
    else if (palette_wr) begin
        // write the value
        palette[border[3:0] ^ 8'hF] <= {~bus_a, border[7]};
    end
end

wire [3:0] palette_a = {irgb[3], irgb[1], irgb[2], irgb[0]}; // palette read address
wire palette_wr = (cs7e && ~bus_wr_n && ds80 && ~reset) ? 1 : 0; // palette write signal

// palette value on read
wire [8:0] palette_grb = palette[palette_a];

// gx0 is the lower green bit of palette value, this value is transferred into the top-level for palette detection
assign gx0 = (ds80) ? palette_grb[6] ^ palette_grb[0] : 1;

// blank for profi ds80 screen mode (after palette)
reg [8:0] palette_grb_reg;
always @(posedge clk) begin
    if (~blank_r && ds80)
        palette_grb_reg <= 9'b0;
    else
        palette_grb_reg <= palette_grb;
end

// output rgb
assign rgb = {palette_grb_reg[5:3], palette_grb_reg[8:6], palette_grb_reg[2:0]};

endmodule

