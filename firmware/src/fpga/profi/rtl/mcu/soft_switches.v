module soft_switches(
    input wire 			clk,
	 input wire [15:0] 	softsw_command,

	 output reg [1:0] 	rom_bank,
	 output reg 			turbofdc,
	 output reg 			covox_en,
	 output reg [1:0] 	psg_mix,
	 output reg 			psg_type,
	 output reg 			video_15khz,
	 output reg 			video_60hz,
	 output reg [1:0] 	turbo,
	 output reg 			swap_fdd,
	 output reg [1:0] 	video_mode,
	 output reg [2:0] 	joy_type,
	 output reg 			divmmc_en,
	 output reg 			nemoide_en,
	 output reg 			keyboard_type,
	 output reg 			pause,
	 output reg 			nmi,
	 output reg 			reset
);

reg [15:0] prev_softsw_command;

always @(posedge clk) begin
    prev_softsw_command <= softsw_command;
	 if (prev_softsw_command != softsw_command)
		 case (softsw_command[15:8])
		     0:  rom_bank 		<= softsw_command[1:0];
			  1:  turbofdc 		<= softsw_command[0];
			  2:  covox_en 		<= softsw_command[0];
			  3:  psg_mix 			<= softsw_command[1:0];
			  4:  psg_type 		<= softsw_command[0];
			  5:  video_15khz 	<= softsw_command[0];
			  6:  video_60hz 		<= softsw_command[0];
			  7:  turbo 			<= softsw_command[1:0];
			  8:  swap_fdd 		<= softsw_command[0];
			  9:  joy_type 		<= softsw_command[2:0];
			  10: video_mode 		<= softsw_command[1:0];
			  11: divmmc_en 		<= softsw_command[0];
			  12: nemoide_en 		<= softsw_command[0];
			  13: keyboard_type 	<= softsw_command[0];
			  14: pause 			<= softsw_command[0];
			  15: nmi 				<= softsw_command[0];
			  16: reset 			<= softsw_command[0];			  
		 endcase
end

endmodule
