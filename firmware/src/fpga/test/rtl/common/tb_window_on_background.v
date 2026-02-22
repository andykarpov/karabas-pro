`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:19:25 08/16/2016
// Design Name:   window_on_background
// Module Name:   D:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/cores/cores_para_testar_la_placa/test_produccion/tb_window_on_background.v
// Project Name:  test_produccion
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: window_on_background
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_window_on_background;

	// Inputs
	reg clk;
	reg mode;

	// Outputs
	wire [2:0] r;
	wire [2:0] g;
	wire [2:0] b;
	wire hsync;
	wire vsync;
	wire csync;

	// Instantiate the Unit Under Test (UUT)
	window_on_background uut (
		.clk(clk), 
		.mode(mode), 
		.r(r), 
		.g(g), 
		.b(b), 
		.hsync(hsync), 
		.vsync(vsync), 
		.csync(csync)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		mode = 0;

      @(negedge vsync);
      $finish;
	end
   
   always begin
      clk = #5 ~clk;
   end
      
endmodule

