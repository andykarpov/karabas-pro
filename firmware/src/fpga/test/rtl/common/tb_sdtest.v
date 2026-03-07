`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   03:09:15 08/19/2016
// Design Name:   sdtest
// Module Name:   D:/Users/rodriguj/Documents/zxspectrum/zxuno/repositorio/cores/cores_para_testar_la_placa/test_produccion/tb_sdtest.v
// Project Name:  test_produccion
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: sdtest
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_sdtest;

	// Inputs
	reg clk;
	reg rst;
	reg spi_do;

	// Outputs
	wire spi_clk;
	wire spi_di;
	wire spi_cs;
	wire test_in_progress;
	wire test_result;

	// Instantiate the Unit Under Test (UUT)
	sdtest uut (
		.clk(clk), 
		.rst(rst), 
		.spi_clk(spi_clk), 
		.spi_di(spi_di), 
		.spi_do(spi_do), 
		.spi_cs(spi_cs), 
		.test_in_progress(test_in_progress), 
		.test_result(test_result)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		spi_do = 1;

		// Wait 100 ns for global reset to finish
        
		// Add stimulus here
      @(negedge test_in_progress);
      repeat (16)
         @(posedge clk);
      $finish;
	end
   
   always begin
      clk = #5 ~clk;
   end
      
endmodule

