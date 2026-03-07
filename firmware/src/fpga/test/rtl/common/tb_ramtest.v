`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:30:53 08/18/2016
// Design Name:   ramtest
// Module Name:   D:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/cores/cores_para_testar_la_placa/test_produccion/tb_ramtest.v
// Project Name:  test_produccion
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ramtest
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_ramtest;

	// Inputs
	reg clk;
	reg rst;

	// Outputs
	wire [20:0] sram_a;
	wire sram_we_n;
	wire test_in_progress;
	wire test_result;

	// Bidirs
	wire [7:0] sram_d;

	// Instantiate the Unit Under Test (UUT)
	ramtest uut (
		.clk(clk), 
		.rst(rst), 
		.sram_a(sram_a), 
		.sram_d(sram_d), 
		.sram_we_n(sram_we_n), 
		.test_in_progress(test_in_progress), 
		.test_result(test_result)
	);

   ram512kb la_ram (
      .a(sram_a),
      .d(sram_d),
      .we_n(sram_we_n)
      );      

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;

      @(negedge test_in_progress);
      @(posedge clk);
      $finish;
	end
   
   always begin
      clk = #70 ~clk;
   end
      
endmodule

module ram512kb (
   input wire [20:0] a,
   inout wire [7:0] d,
   input wire we_n
   );
   
   reg [7:0] ram[0:524287];
   assign #15 d = (we_n == 1'b1)? ram[a[18:0]] : 8'hZZ;
   always @* begin
      if (we_n == 1'b0)
         ram[a[18:0]] = #15 d;
   end
endmodule

      
