//------------------------------------------------------------------------------
//          PCM5102 2 Channel DAC
//------------------------------------------------------------------------------
// http://www.ti.com/product/PCM5101A-Q1/datasheet/specifications#slase121473
module PCM5102(clk,reset,left,right,din,bck,lrck);
	input 			clk;			// 12.288 MHz
	input 			reset; 		// reset
	input [15:0]	left,right;	// left and right 16bit samples Uint16
	output 			din;			// pin on pcm5102 data
	output 			bck;			// pin on pcm5102 bit clock
	output 			lrck;			// pin on pcm5102 l/r clock can be used outside of this module to create new samples
	
	parameter DAC_CLK_DIV_BITS = 1; // 28 MHz / 4 / 32 = 218 kHz samplerate (7 MHz bck)

	reg [DAC_CLK_DIV_BITS:0]	i2s_clk;
	
	// clock divider counter
	always @(negedge clk) begin
		if (reset == 1'b1) 
			i2s_clk <= 0;
		else
			i2s_clk 	<= i2s_clk + 1;
	end
	wire ce = i2s_clk == 0; // pulse ce only when counter is 0

	reg [15:0] l2c, r2c;
	reg lrck, din, bck;

	// load shift registers with new data at the end if i2sword counter and disabled ce
	always @(posedge clk) begin
		if (ce == 1'b0 && i2sword == 6'b111111) begin
			l2c <= left;
			r2c <= right;
		end
	end	

	reg [5:0]   i2sword = 0;		// 6 bit = 16 steps for left + right
	
	// shift data
	always @(posedge clk) begin
		if (ce == 1'b1) begin
			lrck	 	<= i2sword[5];
			bck		<= i2sword[0];
			din 		<= lrck ? r2c[16 - i2sword[4:1]] : l2c[16 - i2sword[4:1]];	// blit data bits
			i2sword	<= i2sword + 1;
		end
	end	
endmodule