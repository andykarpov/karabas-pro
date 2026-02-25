module soft_switches(
    input wire            clk,
    input wire [15:0]     softsw_command,

    output reg [1:0]      rom_bank,
    output reg            turbofdc,
    output reg            covox_en,
    output reg [1:0]      psg_mix,
    output reg            psg_type,
    output reg            video_15khz,
    output reg [1:0]      turbo,
    output reg            swap_fdd,
    output reg [2:0]      joy_type,
    output reg            nemoide_en,
    output reg            keyboard_type,
    output reg            pause,
    output reg            nmi,
    output reg            reset
);

reg [15:0] prev_softsw_command;

always @(posedge clk) begin
    prev_softsw_command <= softsw_command;
     if (prev_softsw_command != softsw_command)
         case (softsw_command[15:8])
             8'h00:  rom_bank         <= softsw_command[1:0];
             8'h01:  turbofdc         <= softsw_command[0];
             8'h02:  covox_en         <= softsw_command[0];
             8'h03:  psg_mix          <= softsw_command[1:0];
             8'h04:  psg_type         <= softsw_command[0];
             8'h05:  video_15khz      <= softsw_command[0];
             8'h06:  turbo            <= softsw_command[1:0];
             8'h07:  swap_fdd         <= softsw_command[0];
             8'h08:  joy_type         <= softsw_command[2:0];
             8'h09:  nemoide_en       <= softsw_command[0];
             8'h0A:  keyboard_type    <= softsw_command[0];
             8'h0B:  pause            <= softsw_command[0];
             8'h0C:  nmi              <= softsw_command[0];
             8'h0D:  reset            <= softsw_command[0];              
         endcase
end

endmodule
