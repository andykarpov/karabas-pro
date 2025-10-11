`timescale 1ns / 1ps

module dpram #(parameter DATAWIDTH=8, ADDRWIDTH=8, MEM_INIT_FILE="")
(
    input                     clock,

    input     [ADDRWIDTH-1:0] address_a,
    input     [DATAWIDTH-1:0] data_a,
    input                     wren_a,
    output reg [DATAWIDTH-1:0] q_a,

    input     [ADDRWIDTH-1:0] address_b,
    input     [DATAWIDTH-1:0] data_b,
    input                     wren_b,
    output reg [DATAWIDTH-1:0] q_b
);

   reg [DATAWIDTH-1:0] mem[0:2**ADDRWIDTH-1] /* synthesis ramstyle = "M9K" */;
   initial begin  // usa $readmemb/$readmemh dependiendo del formato del fichero que contenga la ROM
    if (MEM_INIT_FILE != "") begin
      $readmemb(MEM_INIT_FILE, mem);
    end
   end

  always @(posedge clock) 
  begin
    if (wren_a)
    begin
      mem[address_a] <= data_a;
      q_a <= data_a;
    end
    else
      q_a <= mem[address_a];
  end

  always @(posedge clock) 
  begin
    if (wren_b)
    begin
      mem[address_b] <= data_b;
      q_b <= data_b;
    end
    else
      q_b <= mem[address_b];
  end


endmodule
