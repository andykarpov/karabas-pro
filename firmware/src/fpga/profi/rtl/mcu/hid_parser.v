module hid_parser (
    input wire clk,
	 input wire reset,
	 
	 input wire [7:0] kb_status,
	 input wire [7:0] kb_dat0,
	 input wire [7:0] kb_dat1,
	 input wire [7:0] kb_dat2,
	 input wire [7:0] kb_dat3,
	 input wire [7:0] kb_dat4,
	 input wire [7:0] kb_dat5,

    input wire [7:0] kb_scancode,
	 input wire kb_scancode_upt,
	 
	 input wire [2:0] joy_type_l,
	 input wire [2:0] joy_type_r,
	 input wire [12:0] joy_l,
	 input wire [12:0] joy_r,

    input wire [15:8] a,
	 input wire kb_type, // 0 - profi xt, 1 - spectrum
	
    output wire [7:0] joy_do,
	 output wire [5:0] kb_do,

	 // mapped keyboard buffer and special registers to RTC (tsconf/baseconf related logic)
	 input wire [7:0] rtc_a,
	 input wire [7:0] rtc_di,
	 input wire [7:0] rtc_do_in,
	 output wire [7:0] rtc_do_out,
	 input wire rtc_wr,
	 input wire rtc_rd
);

parameter NUM_KEYS = 2;

localparam ZX_K_CS = 0;
localparam ZX_K_A = 1;
localparam ZX_K_Q = 2;
localparam ZX_K_1 = 3; 
localparam ZX_K_0 = 4;
localparam ZX_K_P = 5;
localparam ZX_K_ENT = 6;
localparam ZX_K_SP = 7;
localparam ZX_K_Z = 8;
localparam ZX_K_S = 9;
localparam ZX_K_W = 10;
localparam ZX_K_2 = 11;
localparam ZX_K_9 = 12;
localparam ZX_K_O = 13;
localparam ZX_K_L = 14;
localparam ZX_K_SS = 15;
localparam ZX_K_X = 16;
localparam ZX_K_D = 17;
localparam ZX_K_E = 18;
localparam ZX_K_3 = 19;
localparam ZX_K_8 = 20;
localparam ZX_K_I = 21;
localparam ZX_K_K = 22;
localparam ZX_K_M = 23;
localparam ZX_K_C = 24;
localparam ZX_K_F = 25;
localparam ZX_K_R = 26;
localparam ZX_K_4 = 27;
localparam ZX_K_7 = 28;
localparam ZX_K_U = 29;
localparam ZX_K_J = 30;
localparam ZX_K_N = 31;
localparam ZX_K_V = 32;
localparam ZX_K_G = 33;
localparam ZX_K_T = 34;
localparam ZX_K_5 = 35;
localparam ZX_K_6 = 36;
localparam ZX_K_Y = 37;
localparam ZX_K_H = 38;
localparam ZX_K_B = 39;
localparam ZX_BIT5 = 40;

localparam SC_CTL_ON = 0;
localparam SC_BTN_UP = 1;
localparam SC_BTN_DOWN = 2;
localparam SC_BTN_LEFT = 3;
localparam SC_BTN_RIGHT = 4;
localparam SC_BTN_START = 5;
localparam SC_BTN_A = 6;
localparam SC_BTN_B = 7;
localparam SC_BTN_C = 8;
localparam SC_BTN_X = 9;
localparam SC_BTN_Y = 10;
localparam SC_BTN_Z = 11;
localparam SC_BTN_MODE = 12;

reg [40:0] kb_data = 41'b0;

wire [47:0] data = {kb_dat0, kb_dat1, kb_dat2, kb_dat3, kb_dat4, kb_dat5};

usb_ps2_keybuf ps2_buf(
    .clk(clk),
    .reset(reset),
    .kb_scancode(kb_scancode),
    .kb_scancode_upd(kb_scancode_upd),
    .keybuf_rd(keybuf_rd),
    .keybuf_reset(keybuf_reset),
    .keybuf_data(keybuf_data)
);

always @* begin
	kb_do[0] <=	~( (kb_data[ZX_K_CS]  && ~a[8])  || 
						(kb_data[ZX_K_A]   && ~a[9])  || 
						(kb_data[ZX_K_Q]   && ~a[10]) || 
						(kb_data[ZX_K_1]   && ~a[11]) || 
						(kb_data[ZX_K_0]   && ~a[12]) ||
						(kb_data[ZX_K_P]   && ~a[13]) ||
						(kb_data[ZX_K_ENT] && ~a[14]) ||
						(kb_data[ZX_K_SP]  && ~a[15]) );

	kb_do[1] <=	~( (kb_data[ZX_K_Z]   && ~a[8])  || 
						(kb_data[ZX_K_S]   && ~a[9])  || 
						(kb_data[ZX_K_W]   && ~a[10]) || 
						(kb_data[ZX_K_2]   && ~a[11]) || 
						(kb_data[ZX_K_9]   && ~a[12]) ||
						(kb_data[ZX_K_O]   && ~a[13]) ||
						(kb_data[ZX_K_L]   && ~a[14]) ||
						(kb_data[ZX_K_SS]  && ~a[15]) );

	kb_do[2] <=	~( (kb_data[ZX_K_X]   && ~a[8])  || 
						(kb_data[ZX_K_D]   && ~a[9])  || 
						(kb_data[ZX_K_E]   && ~a[10]) || 
						(kb_data[ZX_K_3]   && ~a[11]) || 
						(kb_data[ZX_K_8]   && ~a[12]) ||
						(kb_data[ZX_K_I]   && ~a[13]) ||
						(kb_data[ZX_K_K]   && ~a[14]) ||
						(kb_data[ZX_K_M]   && ~a[15]) );

	kb_do[3] <=	~( (kb_data[ZX_K_C]   && ~a[8])  || 
						(kb_data[ZX_K_F]   && ~a[9])  || 
						(kb_data[ZX_K_R]   && ~a[10]) || 
						(kb_data[ZX_K_4]   && ~a[11]) || 
						(kb_data[ZX_K_7]   && ~a[12]) ||
						(kb_data[ZX_K_U]   && ~a[13]) ||
						(kb_data[ZX_K_J]   && ~a[14]) ||
						(kb_data[ZX_K_N]   && ~a[15]) );

	kb_do[4] <=	~( (kb_data[ZX_K_V]   && ~a[8])  || 
						(kb_data[ZX_K_G]   && ~a[9])  || 
						(kb_data[ZX_K_T]   && ~a[10]) || 
						(kb_data[ZX_K_5]   && ~a[11]) || 
						(kb_data[ZX_K_6]   && ~a[12]) ||
						(kb_data[ZX_K_Y]   && ~a[13]) ||
						(kb_data[ZX_K_H]   && ~a[14]) ||
						(kb_data[ZX_K_B]   && ~a[15]) );

   kb_do[5] <= ~kb_data[ZX_BIT5];
end



endmodule