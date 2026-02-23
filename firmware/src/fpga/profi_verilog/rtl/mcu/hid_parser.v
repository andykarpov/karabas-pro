`default_nettype none

/**
 * USB HID report and MD2 joystick to ZX/Profi keyboard / kempston joy mapper
 * 
 * (c) 2026 Andy Karpov <andy.karpov@gmail.com>
 */
module hid_parser (
    input wire        clk,
    input wire        reset,
    
    // usb hid report 
    input wire [7:0]  kb_status,
    input wire [7:0]  kb_dat0,
    input wire [7:0]  kb_dat1,
    input wire [7:0]  kb_dat2,
    input wire [7:0]  kb_dat3,
    input wire [7:0]  kb_dat4,
    input wire [7:0]  kb_dat5,

    // ps/2 scancode
    input wire [7:0]  kb_scancode,
    input wire        kb_scancode_upd,

    // md2 gamepads     
    input wire [2:0]  joy_type_l,
    input wire [2:0]  joy_type_r,
    input wire [12:0] joy_l,
    input wire [12:0] joy_r,

    input wire [15:8] a,     // zx cpu address
    input wire        kb_type, // 0 - profi xt, 1 - spectrum
    
    output wire [7:0] joy_do, // kempston joy port output
    output wire [5:0] kb_do,  // keyboard port output

    // mapped keyboard buffer and special registers to RTC (tsconf/baseconf related logic)
    input wire [7:0]  rtc_a,
    input wire [7:0]  rtc_di,
    input wire [7:0]  rtc_do_in,
    output wire [7:0] rtc_do_out,
    input wire        rtc_wr,
    input wire        rtc_rd
);

parameter NUM_KEYS = 5; // number of pressed keys to process

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

localparam MACRO_START = 1;
localparam MACRO_CS_ON = 2;
localparam MACRO_SS_ON = 3;
localparam MACRO_SS_OFF = 4;
localparam MACRO_KEY = 5;
localparam MACRO_CS_OFF = 6;
localparam MACRO_END = 7;

reg [40:0] kb_data = 41'b0;
wire [47:0] data = {kb_dat0, kb_dat1, kb_dat2, kb_dat3, kb_dat4, kb_dat5};

usb_ps2_keybuf ps2_buf(
    .clk            (clk),
    .reset          (reset),
    .kb_scancode    (kb_scancode),
    .kb_scancode_upd(kb_scancode_upd),
    .keybuf_rd      (keybuf_rd),
    .keybuf_reset   (keybuf_reset),
    .keybuf_data    (keybuf_data)
);

always @* begin
    kb_do[0] <=    ~( (kb_data[ZX_K_CS]  && ~a[8])  || 
                      (kb_data[ZX_K_A]   && ~a[9])  || 
                      (kb_data[ZX_K_Q]   && ~a[10]) || 
                      (kb_data[ZX_K_1]   && ~a[11]) || 
                      (kb_data[ZX_K_0]   && ~a[12]) ||
                      (kb_data[ZX_K_P]   && ~a[13]) ||
                      (kb_data[ZX_K_ENT] && ~a[14]) ||
                      (kb_data[ZX_K_SP]  && ~a[15]) );

    kb_do[1] <=    ~( (kb_data[ZX_K_Z]   && ~a[8])  || 
                      (kb_data[ZX_K_S]   && ~a[9])  || 
                      (kb_data[ZX_K_W]   && ~a[10]) || 
                      (kb_data[ZX_K_2]   && ~a[11]) || 
                      (kb_data[ZX_K_9]   && ~a[12]) ||
                      (kb_data[ZX_K_O]   && ~a[13]) ||
                      (kb_data[ZX_K_L]   && ~a[14]) ||
                      (kb_data[ZX_K_SS]  && ~a[15]) );

    kb_do[2] <=    ~( (kb_data[ZX_K_X]   && ~a[8])  || 
                      (kb_data[ZX_K_D]   && ~a[9])  || 
                      (kb_data[ZX_K_E]   && ~a[10]) || 
                      (kb_data[ZX_K_3]   && ~a[11]) || 
                      (kb_data[ZX_K_8]   && ~a[12]) ||
                      (kb_data[ZX_K_I]   && ~a[13]) ||
                      (kb_data[ZX_K_K]   && ~a[14]) ||
                      (kb_data[ZX_K_M]   && ~a[15]) );

    kb_do[3] <=    ~( (kb_data[ZX_K_C]   && ~a[8])  || 
                      (kb_data[ZX_K_F]   && ~a[9])  || 
                      (kb_data[ZX_K_R]   && ~a[10]) || 
                      (kb_data[ZX_K_4]   && ~a[11]) || 
                      (kb_data[ZX_K_7]   && ~a[12]) ||
                      (kb_data[ZX_K_U]   && ~a[13]) ||
                      (kb_data[ZX_K_J]   && ~a[14]) ||
                      (kb_data[ZX_K_N]   && ~a[15]) );

    kb_do[4] <=    ~( (kb_data[ZX_K_V]   && ~a[8])  || 
                      (kb_data[ZX_K_G]   && ~a[9])  || 
                      (kb_data[ZX_K_T]   && ~a[10]) || 
                      (kb_data[ZX_K_5]   && ~a[11]) || 
                      (kb_data[ZX_K_6]   && ~a[12]) ||
                      (kb_data[ZX_K_Y]   && ~a[13]) ||
                      (kb_data[ZX_K_H]   && ~a[14]) ||
                      (kb_data[ZX_K_B]   && ~a[15]) );

   kb_do[5] <=    ~kb_data[ZX_BIT5];
end

reg is_shift    = 0;
reg is_cs_used  = 0;
reg is_ss_used  = 0;
reg [21:0] macro_cnt = 0;
reg is_macros = 0;
reg [2:0] macros_state = MACRO_START;
reg [7:0] macro_key = 0;
always @(posedge clk, posedge reset) begin
    if (reset) begin
        kb_data <= 41'b0;
        is_shift <= 0;
        is_cs_used <= 0;
        is_ss_used <= 0;
        macro_cnt <= 0;
    end else begin
        // macro state machine
        if (is_macros) begin
            macro_cnt <= macro_cnt + 1;
            if (macro_cnt == 22'b1111111111111111111111)
            case (macros_state)
                MACRO_START:  begin kb_data <= 41'b0; macros_state <= MACRO_CS_ON; end
                MACRO_CS_ON : begin kb_data[ZX_K_CS] <= 1; macro_state <= MACRO_SS_ON; end
                MACRO_SS_ON : begin kb_data[ZX_K_SS] <= 1; macro_state <= MACRO_SS_OFF; end
                MACRO_SS_OFF: begin kb_data[ZX_K_SS] <= 0; macro_state <= MACRO_KEY; end
                MACRO_KEY:    begin kb_data[macros_key] <= 1; macro_state <= MACRO_CS_OFF; end
                MACRO_CS_OFF: begin kb_data[Zx_K_CS] <= 0; kb_data[marcos_key] <= 0; macro_state <= MACRO_END; end
                MACRO_END:    begin kb_data <= 41'b0; is_macros <= 0; macros_state <= MACRO_START; end
            endcase
        // normal keypress processing
        end else begin
            macro_cnt  <= 0;
            kb_data    <= 41'b0;
            is_shift   <= 0;
            is_cs_used <= 0;
            is_ss_used <= 0;

            // L Shift -> CS (SS for profi)
            if (kb_status[1]) begin 
                if (!kb_type) kb_data[ZX_K_SS] <= 1; else kb_data[ZX_K_CS] <= 1; 
                is_shift <= 1; 
            end

            // R Shift -> CS (SS for profi)
            if (kb_status[5]) begin 
                if (!kb_type) kb_data[ZX_K_SS] <= 1; else kb_data[ZX_K_CS] <= 1; 
                is_shift <= 1; 
            end
                        
            // L Ctrl -> SS (CS for profi)
            if (kb_status[0]) begin 
                if (!kb_type) kb_data[ZX_K_CS] <= 1; else kb_data[ZX_K_SS] <= 1; 
            end
            
            // R Ctrl -> SS (CS for profi)
            if (kb_status[4]) begin 
                if (!kb_type) kb_data[ZX_K_CS] <= 1; else kb_data[ZX_K_SS] <= 1; 
            end
                        
            // L Alt -> SS+CS (SS+Enter for profi)
            if (kb_status[2]) begin 
                if (!kb_type) kb_data[ZX_K_ENT] <= 1; else kb_data[ZX_K_CS] <= 1; 
                kb_data[ZX_K_SS] <= 1; 
                is_cs_used <= 1; 
            end

            // R Alt -> SS+CS (SS+Space for profi)
            if (kb_status[6]) begin 
                if (!kb_type) kb_data[ZX_K_SP] <= 1; else kb_data[ZX_K_CS] <= 1;  
                kb_data[ZX_K_SS] <= 1; 
                is_cs_used <= 1; 
            end
            
            // Win
            //if (kb_status[7]) begin end

            for (ii=0; ii<NUM_KEYS; ii++) begin
            case (data[(ii+1)*8-1 : ii*8])

                // DEL -> SS + C (P + BIT5 for profi)
                8'h4c: 
                    if (~is_shift) 
                        if (~kb_type) begin kb_data[ZX_K_P] <= 1; kb_data[ZX_BIT5] <= 1; end 
                        else begin kb_data[ZX_K_SS] <= 1; kb_data[ZX_K_C] <= 1; end
                    
                // INS -> SS + A (O + BIT5 for profi)
                8'h49: 
                    if (~is_shift) 
                        if (!kb_type) begin kb_data[ZX_K_O] <= 1; kb_data[ZX_BIT5] <= 1; end 
                        else begin kb_data[ZX_K_SS] <= 1; kb_data[ZX_K_A] <= 1; end
                
                // Cursor -> CS + 5,6,7,8
                8'h50: if (~is_shift) begin kb_data[ZX_K_CS] <= 1; kb_data[ZX_K_5] <= 1; is_cs_used <= 1; end 
                8'h51: if (~is_shift) begin kb_data[ZX_K_CS] <= 1; kb_Data[ZX_K_6] <= 1; is_cs_used <= 1; end 
                8'h52: if (~is_shift) begin kb_data[ZX_K_CS] <= 1; kb_data[ZX_K_7] <= 1; is_cs_used <= 1; end
                8'h4f: if (~is_shift) begin kb_data[ZX_K_CS] <= 1; kb_data[ZX_K_8] <= 1; is_cs_used <= 1; end

                // ESC -> CS + Space (CS + 1 for profi)
                8'h29: begin 
                    kb_data[ZX_K_CS] <= 1; 
                    if (!kb_type) kb_data[ZX_K_1] <= 1; else kb_data[ZX_K_SP] <= 1; 
                    is_cs_used <= 1; 
                end                        

                // Backspace -> CS + 0
                8'h2a: begin kb_data[ZX_K_CS] <= 1; kb_data[ZX_K_0] <= 1; is_cs_used <= 1; end 

                // Enter
                8'h28: kb_data[ZX_K_ENT] <= 1; // normal
                8'h58: kb_data[ZX_K_ENT] <= 1; // keypad                     
                
                // Space 
                8'h2c: kb_data[ZX_K_SP] <= 1;
                
                // Letters
                8'h04: kb_data[ZX_K_A] <= 1; // A
                8'h05: kb_data[ZX_K_B] <= 1; // B                                
                8'h06: kb_data[ZX_K_C] <= 1; // C
                8'h07: kb_data[ZX_K_D] <= 1; // D
                8'h08: kb_data[ZX_K_E] <= 1; // E
                8'h09: kb_data[ZX_K_F] <= 1; // F
                8'h0a: kb_data[ZX_K_G] <= 1; // G
                8'h0b: kb_data[ZX_K_H] <= 1; // H
                8'h0c: kb_data[ZX_K_I] <= 1; // I
                8'h0d: kb_data[ZX_K_J] <= 1; // J
                8'h0e: kb_data[ZX_K_K] <= 1; // K
                8'h0f: kb_data[ZX_K_L] <= 1; // L
                8'h10: kb_data[ZX_K_M] <= 1; // M
                8'h11: kb_data[ZX_K_N] <= 1; // N
                8'h12: kb_data[ZX_K_O] <= 1; // O
                8'h13: kb_data[ZX_K_P] <= 1; // P
                8'h14: kb_data[ZX_K_Q] <= 1; // Q
                8'h15: kb_data[ZX_K_R] <= 1; // R
                8'h16: kb_data[ZX_K_S] <= 1; // S
                8'h17: kb_data[ZX_K_T] <= 1; // T
                8'h18: kb_data[ZX_K_U] <= 1; // U
                8'h19: kb_data[ZX_K_V] <= 1; // V
                8'h1a: kb_data[ZX_K_W] <= 1; // W
                8'h1b: kb_data[ZX_K_X] <= 1; // X
                8'h1c: kb_data[ZX_K_Y] <= 1; // Y
                8'h1d: kb_data[ZX_K_Z] <= 1; // Z
                
                // Digits
                8'h1e: kb_data[ZX_K_1] <= 1; // 1
                8'h1f: kb_data[ZX_K_2] <= 1; // 2
                8'h20: kb_data[ZX_K_3] <= 1; // 3
                8'h21: kb_data[ZX_K_4] <= 1; // 4
                8'h22: kb_data[ZX_K_5] <= 1; // 5
                8'h23: kb_data[ZX_K_6] <= 1; // 6
                8'h24: kb_data[ZX_K_7] <= 1; // 7
                8'h25: kb_data[ZX_K_8] <= 1; // 8
                8'h26: kb_data[ZX_K_9] <= 1; // 9
                8'h27: kb_data[ZX_K_0] <= 1; // 0
                // Numpad digits
                8'h59: kb_data[ZX_K_1] <= 1; // 1
                8'h5A: kb_data[ZX_K_2] <= 1; // 2
                8'h5B: kb_data[ZX_K_3] <= 1; // 3
                8'h5C: kb_data[ZX_K_4] <= 1; // 4
                8'h5D: kb_data[ZX_K_5] <= 1; // 5
                8'h5E: kb_data[ZX_K_6] <= 1; // 6
                8'h5F: kb_data[ZX_K_7] <= 1; // 7
                8'h60: kb_data[ZX_K_8] <= 1; // 8
                8'h61: kb_data[ZX_K_9] <= 1; // 9
                8'h62: kb_data[ZX_K_0] <= 1; // 0
                
                // Special keys                     
                // '/" -> SS+P / SS+7
                8'h34: begin kb_data[ZX_K_SS] <= 1; if (is_shift) kb_data[ZX_K_P] <= 1; else kb_data[ZX_K_7] <= 1; is_ss_used <= is_shift;    end                
                // ,/< -> SS+N / SS+R
                8'h36: begin kb_data[ZX_K_SS] <= 1; if (is_shift) kb_data[ZX_K_R] <= 1; else kb_data[ZX_K_N] <= 1; is_ss_used <= is_shift;    end                
                // ./> -> SS+M / SS+T
                8'h37: begin kb_data[ZX_K_SS] <= 1; if (is_shift) kb_data[ZX_K_T] <= 1; else kb_data[ZX_K_M] <= 1; is_ss_used <= is_shift; end                    
                // ;/: -> SS+O / SS+Z
                8'h33: begin kb_data[ZX_K_SS] <= 1; if (is_shift) kb_data[ZX_K_Z] <= 1; else kb_data[ZX_K_O] <= 1; is_ss_used <= is_shift; end            
                
                // Macroses
                
                // [,{ -> SS+Y / SS+F (Profi SS + F / Y)
                8'h2F: 
                    if (!kb_type) begin
                        kb_data[ZX_K_SS] <= 1;
                        if (is_shift) kb_data[ZX_K_F] <= 1; else kb_data[ZX_K_Y] <= 1; 
                    end else begin
                        is_macros <= 1; if (is_shift) macros_key <= ZX_K_F; else macros_key <= ZX_K_Y; 
                    end
                
                // ],} -> SS+U / SS+G (Profi SS + U / G)
                8'h30: 
                    if (!kb_type) begin
                        kb_data[ZX_K_SS] <= 1;
                        if (is_shift) kb_data[ZX_K_G] <= 1; else kb_data[ZX_K_U] <= 1; 
                    end else begin
                        is_macros <= 1; if (is_shift) macros_key <= ZX_K_G; else macros_key <= ZX_K_U; 
                    end
                    
                // \,| -> SS+D / SS+S (Profi SS + D / S)
                8'h31: 
                    if (!kb_type) begin
                        kb_data[ZX_K_SS] <= 1;
                        if (is_shift) kb_data[ZX_K_S] <= 1; else kb_data[ZX_K_D] <= 1;
                    end else begin
                        is_macros <= 1; if (is_shift) macros_key <= ZX_K_S; else macros_key <= ZX_K_D; 
                    end
                
                // /,? -> SS+V / SS+C
                8'h38: begin kb_data[ZX_K_SS] <= 1; if (is_shift) kb_data[ZX_K_C] <= 1; else kb_data[ZX_K_V] <= 1; is_ss_used <= is_shift; end                    
                // =,+ -> SS+L / SS+K
                8'h2E: begin kb_data[ZX_K_SS] <= 1; if (is_shift) kb_data[ZX_K_K] <= 1; else kb_data[ZX_K_L] <= 1; is_ss_used <= is_shift; end                    
                // -,_ -> SS+J / SS+0
                8'h2D: begin kb_data[ZX_K_SS] <= 1; if (is_shift) kb_data[ZX_K_0] <= 1; else kb_data[ZX_K_J] <= 1; is_ss_used <= is_shift; end
                // `,~ -> SS+X / SS+A
                8'h35: begin
                    if (is_shift) begin  
                        is_macros <= 1; macros_key <= ZX_K_A; 
                    end else begin
                        kb_data[ZX_K_SS] <= 1; kb_data[ZX_K_X] <= 1; 
                    end
                    is_ss_used := 1;
                end
                // Keypad * -> SS+B
                8'h55: begin kb_data[ZX_K_SS] <= 1; kb_data[ZX_K_B] <= 1; end
                // Keypad - -> SS+J
                8'h56: begin kb_data[ZX_K_SS] <= 1; kb_data[ZX_K_J] <= 1; end
                // Keypad + -> SS+K
                8'h57: begin kb_data[ZX_K_SS] <= 1; kb_data[ZX_K_K] <= 1; end
                // Tab -> CS + I
                8'h2B: begin kb_data[ZX_K_CS] <= 1; kb_data[ZX_K_I] <= 1; is_cs_used <= 1; end
                // CapsLock -> CS + SS
                8'h39: begin kb_data[ZX_K_SS] <= 1; kb_data[ZX_K_CS] <= 1; is_cs_used <= 1; end
                
                // PgUp -> CS+3 for ZX (M+BIT5 for profi)
                8'h4B: 
                    if (!is_shift) 
                        if (!kb_type) begin
                            kb_data[ZX_K_M] <= 1;
                            kb_data[ZX_BIT5] <= 1;
                        end else begin
                            kb_data[ZX_K_CS] <= 1; 
                            kb_data[ZX_K_3] <= 1; 
                            is_cs_used <= 1; 
                        end

                // PgDown -> CS+4 for ZX (N+BIT5 for profi)
                8'h4E: 
                    if (!is_shift) 
                        if (!kb_type) begin
                            kb_data[ZX_K_N] <= 1;
                            kb_data[ZX_BIT5] <= 1;
                        end else begin
                            kb_data[ZX_K_CS] <= 1; 
                            kb_data[ZX_K_4] <= 1; 
                            is_cs_used <= 1; 
                        end
                    
                // Home -> K+BIT5 for profi
                8'h4a:    
                    if (~kb_type && ~is_shift) begin
                        kb_data[ZX_K_K] <= 1;
                        kb_data[ZX_BIT5] <= 1;
                    end
                
                // End -> L+BIT5 for profi
                8'h4d:    
                    if (~kb_type && ~is_shift) begin 
                        kb_data[ZX_K_L] <= 1;
                        kb_data[ZX_BIT5] <= 1;
                    end
                
                // Fx keys
                8'h3a: if (!kb_type) begin kb_data[ZX_K_A] <= 1; kb_data[ZX_BIT5] <= 1; end // F1
                8'h3b: if (!kb_type) begin kb_data[ZX_K_B] <= 1; kb_data[ZX_BIT5] <= 1; end // F2
                8'h3c: if (!kb_type) begin kb_data[ZX_K_C] <= 1; kb_data[ZX_BIT5] <= 1; end // F3
                8'h3d: if (!kb_type) begin kb_data[ZX_K_D] <= 1; kb_data[ZX_BIT5] <= 1; end // F4
                8'h3e: if (!kb_type) begin kb_data[ZX_K_E] <= 1; kb_data[ZX_BIT5] <= 1; end // F5
                8'h3f: if (!kb_type) begin kb_data[ZX_K_F] <= 1; kb_data[ZX_BIT5] <= 1; end // F6
                8'h40: if (!kb_type) begin kb_data[ZX_K_G] <= 1; kb_data[ZX_BIT5] <= 1; end // F7
                8'h41: if (!kb_type) begin kb_data[ZX_K_H] <= 1; kb_data[ZX_BIT5] <= 1; end // F8
                8'h42: if (!kb_type) begin kb_data[ZX_K_I] <= 1; kb_data[ZX_BIT5] <= 1; end // F9
                8'h43: if (!kb_type) begin kb_data[ZX_K_J] <= 1; kb_data[ZX_BIT5] <= 1; end // F10
                8'h44: if (!kb_type) begin kb_data[ZX_K_Q] <= 1; kb_data[ZX_K_SS] <= 1; end // F11
                8'h45: if (!kb_type) begin kb_data[ZX_K_W] <= 1; kb_data[ZX_K_SS] <= 1; end // F12
 
                // Soft-only keys
                //8'h46:    // PrtScr
                //8'h47:    // Scroll Lock
                //8'h48:    // Pause
                //8'h65:    // WinMenu
                
            endcase
            end // loop
                        
            // map joysticks to keyboard
            // sega joy:  Mode Z Y X C B A Start R L D U On
            
            // sinclair 1
            if (joy_type_l == 3'd1) begin  
                if (joy_l[SC_BTN_UP])    kb_data[ZX_K_4] <= 1; // up
                if (joy_l[SC_BTN_DOWN])  kb_data[ZX_K_3] <= 1; // down
                if (joy_l[SC_BTN_LEFT])  kb_data[ZX_K_1] <= 1; // left
                if (joy_l[SC_BTN_RIGHT]) kb_data[ZX_K_2] <= 1;  // right
                if (joy_l[SC_BTN_B])     kb_data[ZX_K_5] <= 1;  // fire
            end
            
            if (joy_type_r == 3'd1) begin 
                if (joy_r[SC_BTN_UP])    kb_data[ZX_K_4] <= 1;  // up
                if (joy_r[SC_BTN_DOWN])  kb_data[ZX_K_3] <= 1;  // down
                if (joy_r[SC_BTN_LEFT])  kb_data[ZX_K_1] <= 1;  // left
                if (joy_r[SC_BTN_RIGHT]) kb_data[ZX_K_2] <= 1;  // right
                if (joy_r[SC_BTN_B])     kb_data[ZX_K_5] <= 1;  // fire                    
            end
            
            // sinclair 2
            if (joy_type_l == 3'd2) begin  
                if (joy_l[SC_BTN_UP])    kb_data[ZX_K_9] <= 1;  // up
                if (joy_l[SC_BTN_DOWN])  kb_data[ZX_K_8] <= 1;  // down
                if (joy_l[SC_BTN_LEFT])  kb_data[ZX_K_6] <= 1;  // left
                if (joy_l[SC_BTN_RIGHT]) kb_data[ZX_K_7] <= 1;  // right
                if (joy_l[SC_BTN_B])     kb_data[ZX_K_0] <= 1;  // fire    
            end                

            if (joy_type_r == 3'd2) begin 
                if (joy_r[SC_BTN_UP])    kb_data[ZX_K_9] <= 1;  // up
                if (joy_r[SC_BTN_DOWN])  kb_data[ZX_K_8] <= 1;  // down
                if (joy_r[SC_BTN_LEFT])  kb_data[ZX_K_6] <= 1;  // left
                if (joy_r[SC_BTN_RIGHT]) kb_data[ZX_K_7] <= 1;  // right
                if (joy_r[SC_BTN_B])     kb_data[ZX_K_0] <= 1;  // fire                    
            end                
            
            // cursor
            if (joy_type_l == 3'd3) begin  
                if (joy_l[SC_BTN_UP])    kb_data[ZX_K_7] <= 1;  // up
                if (joy_l[SC_BTN_DOWN])  kb_data[ZX_K_6] <= 1;  // down
                if (joy_l[SC_BTN_LEFT])  kb_data[ZX_K_5] <= 1;  // left
                if (joy_l[SC_BTN_RIGHT]) kb_data[ZX_K_8] <= 1;  // right
                if (joy_l[SC_BTN_B])     kb_data[ZX_K_0] <= 1;  // fire    
            end                

            if (joy_type_r == 3'd3) begin 
                if (joy_r[SC_BTN_UP])    kb_data[ZX_K_7] <= 1;  // up
                if (joy_r[SC_BTN_DOWN])  kb_data[ZX_K_6] <= 1;  // down
                if (joy_r[SC_BTN_LEFT])  kb_data[ZX_K_5] <= 1;  // left
                if (joy_r[SC_BTN_RIGHT]) kb_data[ZX_K_8] <= 1;  // right
                if (joy_r[SC_BTN_B])     kb_data[ZX_K_0] <= 1;  // fire                    
            end
            
            // qaopm
            if (joy_type_l == 3'd4) begin  
                if (joy_l[SC_BTN_UP])    kb_data[ZX_K_Q] <= 1;  // up
                if (joy_l[SC_BTN_DOWN])  kb_data[ZX_K_A] <= 1;  // down
                if (joy_l[SC_BTN_LEFT])  kb_data[ZX_K_O] <= 1;  // left
                if (joy_l[SC_BTN_RIGHT]) kb_data[ZX_K_P] <= 1;  // right
                if (joy_l[SC_BTN_B])     kb_data[ZX_K_M] <= 1;  // fire    
            end                

            if (joy_type_r == 3'd4) begin 
                if (joy_r[SC_BTN_UP])    kb_data[ZX_K_Q] <= 1;  // up
                if (joy_r[SC_BTN_DOWN])  kb_data[ZX_K_A] <= 1;  // down
                if (joy_r[SC_BTN_LEFT])  kb_data[ZX_K_O] <= 1;  // left
                if (joy_r[SC_BTN_RIGHT]) kb_data[ZX_K_P] <= 1;  // right
                if (joy_r[SC_BTN_B])     kb_data[ZX_K_M] <= 1;  // fire                    
            end

            // quaps
            if (joy_type_l == 3'd5) begin  
                if (joy_l[SC_BTN_UP])    kb_data[ZX_K_Q] <= 1;  // up
                if (joy_l[SC_BTN_DOWN])  kb_data[ZX_K_A] <= 1;  // down
                if (joy_l[SC_BTN_LEFT])  kb_data[ZX_K_O] <= 1;  // left
                if (joy_l[SC_BTN_RIGHT]) kb_data[ZX_K_P] <= 1;  // right
                if (joy_l[SC_BTN_B])     kb_data[ZX_K_SP] <= 1;  // fire    
            end                

            if (joy_type_r == 3'd5) begin 
                if (joy_r[SC_BTN_UP])    kb_data[ZX_K_Q] <= 1;  // up
                if (joy_r[SC_BTN_DOWN])  kb_data[ZX_K_A] <= 1;  // down
                if (joy_r[SC_BTN_LEFT])  kb_data[ZX_K_O] <= 1;  // left
                if (joy_r[SC_BTN_RIGHT]) kb_data[ZX_K_P] <= 1;  // right
                if (joy_r[SC_BTN_B])     kb_data[ZX_K_SP] <= 1;  // fire                    
            end
            
            // cleanup CS key when SS is marked
            if (is_ss_used && ~is_cs_used)  
                kb_data[ZX_K_CS] <= 0;
                
        end
    end
end

// map L/R joysticks to kempston joy bus 
always (posedge clk, posedge reset) begin
    if (reset) 
        joy_do <= 8'b0;
    else 
        if (joy_type_l == 3'd0) begin 
            joy_do[0] <= joy_l[SC_BTN_RIGHT];
            joy_do[1] <= joy_l[SC_BTN_LEFT];
            joy_do[2] <= joy_l[SC_BTN_DOWN];
            joy_do[3] <= joy_l[SC_BTN_UP];
            joy_do[4] <= joy_l[SC_BTN_B];
            joy_do[5] <= joy_l[SC_BTN_A];
            joy_do[6] <= joy_l[SC_BTN_X];
            joy_do[7] <= joy_l[SC_BTN_Y];
        
        end else if (joy_type_r == 3'd0) begin
            joy_do[0] <= joy_r[SC_BTN_RIGHT];
            joy_do[1] <= joy_r[SC_BTN_LEFT];
            joy_do[2] <= joy_r[SC_BTN_DOWN];
            joy_do[3] <= joy_r[SC_BTN_UP];
            joy_do[4] <= joy_r[SC_BTN_B];
            joy_do[5] <= joy_r[SC_BTN_A];
            joy_do[6] <= joy_r[SC_BTN_X];
            joy_do[7] <= joy_r[SC_BTN_Y];
        end
        else
            joy_do <= 8'b0;
end

// map ps/2 keyboard to RTC + special registers
reg allow_eeprom = 1;
reg prev_rtc_rd = 0;
reg keybuf_rd = 0;
reg keybuf_reset = 0;
wire [7:0] keybuf_data;
always @(posedge clk, posedge reset) begin
    if (reset)
        allow_eeprom <= 1;
    else begin
        prev_rtc_rd <= rtc_rd;
        keybuf_rd <= 0;
        keybuf_reset <= 0;
        
        // write control register 0C
        if (rtc_wr) 
            case (rtc_a)
                8'h0C: begin 
                    keybuf_reset <= RTC_DI[0];
                    allow_eeprom <= RTC_DI[7];
                end
            endcase
        // read RTC special registers + keyboard buffer
        else if (rtc_rd && prev_rtc_rd != rtc_rd) begin
            rtc_do_out <= rtc_do_in;
            case (rtc_a)
                8'h0A: rtc_do_out <= 8'h00;
                8'h0B: rtc_do_out <= 8'h02;
                8'h0C: rtc_do_out <= 8'h00;
                8'h0D: rtc_do_out <= {2'b10, kb_status[5], kb_status[1], kb_status[6], kb_status[2], kb_status[4], kb_status[0]}; // 1 f12 rshift lshift ralt lalt rctrl lctrl  
                8'hF0, 8'hF1, 8'hF2, 8'hF3, 8'hF4, 8'hF5, 8'hF6, 8'hF7, 
                8'hF8, 8'hF9, 8'hFA, 8'hFB, 8'hFC, 8'hFD, 8'hFE, 8'hFF:
                    if (!allow_eeprom) begin
                        rtc_do_out <= keybuf_data;
                        keybuf_rd <= 1;
                    end else 
            endcase
        end
    end
end

endmodule
