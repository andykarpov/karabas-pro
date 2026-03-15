module audio_mixer (
	input wire clk,
	
	input wire mute,
	input wire [1:0] mode,
	
	input wire speaker,
	input wire tape_in,
	
	input wire [7:0] ssg0_a,
	input wire [7:0] ssg0_b,
	input wire [7:0] ssg0_c,
	
	input wire [7:0] ssg1_a,
	input wire [7:0] ssg1_b,
	input wire [7:0] ssg1_c,
	
	input wire [7:0] covox_a,
	input wire [7:0] covox_b,
	input wire [7:0] covox_c,
	input wire [7:0] covox_d,
	input wire [7:0] covox_fb,	
	
	input wire [7:0] saa_l,
	input wire [7:0] saa_r,
	
	input wire [14:0] gs_l,
	input wire [14:0] gs_r,
	
	input wire [15:0] fm_l,
	input wire [15:0] fm_r,

`ifdef HW_ID2
	input wire [15:0] adc_l,
	input wire [15:0] adc_r,
`endif
	
	input wire fm_ena,
	
	output wire signed [15:0] audio_l,
	output wire signed [15:0] audio_r
);

reg signed [11:0] psg_l, psg_r, opn_s;
reg signed [11:0] tsfm_l, tsfm_r;
reg signed [11:0] covox_l, covox_r;

always @(posedge clk) begin

	psg_l <= (mode == 2'b00 || mode== 2'b10) ? 
		$signed({3'b000, ssg0_a, 1'd0}) + $signed({3'b000, ssg1_a, 1'd0}) + $signed({4'b0000, ssg0_b}) + $signed({4'b0000, ssg1_b}) : 
		$signed({3'b000, ssg0_a, 1'd0}) + $signed({3'b000, ssg1_a, 1'd0}) + $signed({4'b0000, ssg0_c}) + $signed({4'b0000, ssg1_c});
	psg_r <= (mode == 2'b00 || mode== 2'b10) ? 
		$signed({3'b000, ssg0_c, 1'd0}) + $signed({3'b000, ssg1_c, 1'd0}) + $signed({4'b0000, ssg0_b}) + $signed({4'b0000, ssg1_b}) : 
		$signed({3'b000, ssg0_b, 1'd0}) + $signed({3'b000, ssg1_b, 1'd0}) + $signed({4'b0000, ssg0_c}) + $signed({4'b0000, ssg1_c});	
	opn_s <= {{2{fm_l[15]}}, fm_l[15:6]} + {{2{fm_r[15]}}, fm_r[15:6]};

	tsfm_l <= fm_ena ? $signed(opn_s) + $signed(psg_l) : $signed(psg_l);
	tsfm_r <= fm_ena ? $signed(opn_s) + $signed(psg_r) : $signed(psg_r);

	covox_l <= $signed({2'b00, covox_a, 2'b00}) + $signed({2'b00, covox_b, 2'b00}) + $signed({3'b000, covox_fb, 1'b0});
	covox_r <= $signed({2'b00, covox_c, 2'b00}) + $signed({2'b00, covox_d, 2'b00}) + $signed({3'b000, covox_fb, 1'b0});
end

wire signed [15:0] mix_l = 	$signed({tsfm_l[11:0], 4'b0000}) + 
										$signed({gs_l[14],gs_l[14:0]}) + 
`ifdef HW_ID2
										$signed(adc_l[15:0]) +
`endif
										$signed({2'b00, saa_l, 6'b000000}) +
										$signed({covox_l[11:0], 4'b0000}) + 
										$signed({2'b00, speaker, 7'b0000000, 6'b0000});

wire signed [15:0] mix_r = 	$signed({tsfm_r[11:0], 4'b0000}) + 
										$signed({gs_r[14], gs_r[14:0]}) + 
`ifdef HW_ID2
										$signed(adc_r[15:0]) +
`endif							
										$signed({2'b00, saa_r, 6'b000000}) +										
										$signed({covox_r[11:0], 4'b0000}) + 
										$signed({2'b00, speaker, 7'b0000000, 6'b000000});

assign audio_l = mix_l;
assign audio_r = mix_r;

endmodule
