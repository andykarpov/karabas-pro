`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:00:24 07/18/2018 
// Design Name: 
// Module Name:    sdramtest 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module sdramtest (
  input wire clk,
  input wire rst,
  input wire pll_locked,
  output reg test_in_progress,
  output reg test_result,
  output wire sdram_busy,
  // interface con la SDRAM
  output wire sdram_clk,          // señales validas en flanco de suida de CK
  output wire sdram_cke,
  output wire sdram_dqmh_n,      // mascara para byte alto o bajo
  output wire sdram_dqml_n,      // durante operaciones de escritura
  output wire [12:0] sdram_addr, // pag.14. row=[12:0], col=[8:0]. A10=1 significa precharge all.
  output wire [1:0] sdram_ba,    // banco al que se accede
  output wire sdram_cs_n,
  output wire sdram_we_n,
  output wire sdram_ras_n,
  output wire sdram_cas_n,
  inout tri [15:0] sdram_dq
  );
  
  parameter
    FREQCLKSDRAM = 50,
    CL = 3'd2
    ;
  
  localparam
    FINAL_ADDRESS = 24'hFFFFFF;
    
  reg [23:0] addr_to_test = 24'h000000;
  reg [15:0] data_to_sdram = 16'h5555;
  wire [15:0] data_from_sdram;
  reg read_rq = 1'b0;
  reg write_rq = 1'b0;
  reg rfsh_rq = 1'b0;
  wire busy;
  wire clken = 1'b1;
  assign sdram_busy = busy;
  
  sdram_controller #(.FREQCLKSDRAM(FREQCLKSDRAM), .CL(CL)) controlador (
    .clk(clk),                // este reloj debe ser el doble del reloj de la SDRAM
    .clken(clken),
    .reset(~pll_locked),      // normalmente conectado a la versión negada del pin "locked" del PLL/MMCM
    // host interface
    .addr(addr_to_test),
    .read_rq(read_rq),
    .write_rq(write_rq),
    .rfsh_rq(rfsh_rq),
    .din(data_to_sdram),
    .dout(data_from_sdram),
    .busy(busy),
    // sdram interface
    .sdram_clk(sdram_clk),          // señales validas en flanco de suida de CK
    .sdram_cke(sdram_cke),
    .sdram_dqmh_n(sdram_dqmh_n),      // mascara para byte alto o bajo
    .sdram_dqml_n(sdram_dqml_n),      // durante operaciones de escritura
    .sdram_addr(sdram_addr), // pag.14. row=[12:0], col=[8:0]. A10=1 significa precharge all.
    .sdram_ba(sdram_ba),    // banco al que se accede
    .sdram_cs_n(sdram_cs_n),
    .sdram_we_n(sdram_we_n),
    .sdram_ras_n(sdram_ras_n),
    .sdram_cas_n(sdram_cas_n),
    .sdram_dq(sdram_dq)
  );
  
  reg [3:0] divclk = 4'b0001;
  wire cke = divclk[3];
  
  localparam
    RESET                = 3'd0,
    WRITE_DATA           = 3'd1,
    READ_DATA            = 3'd2,
    UPDATE_DATA          = 3'd3,
    CHK_DATA             = 3'd4,
    REFRESH_AFTER_WRITE  = 3'd5,
    REFRESH_AFTER_UPDATE = 3'd6,
    REFRESH_AFTER_CHK    = 3'd7
    ;
  
  reg [2:0] state = RESET;
  reg initial_rst = 1'b1;  // solo se usa para autoarrancar el test nada más cargar el core.
  
  always @(posedge clk) begin
    if (clken == 1'b1) begin
      divclk <= {divclk[2:0], divclk[3]};
      if (cke == 1'b1) begin  // esta FSM funciona a CLK/4
        case (state)
          RESET:
            begin
              read_rq <= 1'b0;
              write_rq <= 1'b0;
              rfsh_rq <= 1'b0;
              if (pll_locked == 1'b1 && (rst == 1'b1 || initial_rst == 1'b1) && busy == 1'b0) begin
                addr_to_test <= 24'h000000;
                data_to_sdram <= 16'h5555;
                write_rq <= 1'b1;
                state <= WRITE_DATA;
                test_result <= 1'b0;
                test_in_progress <= 1'b1;
                initial_rst <= 1'b0;
              end
            end
          WRITE_DATA:
            begin
              if (busy == 1'b0) begin
                if (addr_to_test == FINAL_ADDRESS) begin
                  state <= READ_DATA;
                  addr_to_test <= 24'h000000;
                  read_rq <= 1'b1;
                end
                else begin
                  addr_to_test <= addr_to_test + 24'd1;
                  if (addr_to_test[4:0] == 5'h10) begin
                    state <= REFRESH_AFTER_WRITE;
                    rfsh_rq <= 1'b1;
                  end
                  else begin
                    write_rq <= 1'b1;
                  end  
                end
              end
              else
                write_rq <= 1'b0;
            end
          REFRESH_AFTER_WRITE:
            begin
              rfsh_rq <= 1'b0;          
              if (busy == 1'b0) begin
                state <= WRITE_DATA;
                write_rq <= 1'b1;
              end
            end
          READ_DATA:
            begin
              if (busy == 1'b0) begin
                state <= UPDATE_DATA;
                data_to_sdram <= data_from_sdram + 16'h5555;
                write_rq <= 1'b1;
              end
              else
                read_rq <= 1'b0;
            end
          UPDATE_DATA:
            begin
              if (busy == 1'b0) begin
                if (addr_to_test == FINAL_ADDRESS) begin
                  state <= CHK_DATA;
                  addr_to_test <= 24'h000000;
                  read_rq <= 1'b1;
                end
                else begin
                  addr_to_test <= addr_to_test + 24'd1;
                  if (addr_to_test[4:0] == 5'h10) begin
                    state <= REFRESH_AFTER_UPDATE;
                    rfsh_rq <= 1'b1;
                  end
                  else begin
                    state <= READ_DATA;
                    read_rq <= 1'b1;
                  end
                end
              end
              else
                write_rq <= 1'b0;
            end
          REFRESH_AFTER_UPDATE:
            begin
              rfsh_rq <= 1'b0;          
              if (busy == 1'b0) begin
                state <= READ_DATA;
                read_rq <= 1'b1;
              end
            end
          CHK_DATA:
            begin
              if (busy == 1'b0) begin
                if (addr_to_test == FINAL_ADDRESS) begin
                  state <= RESET;
                  test_in_progress <= 1'b0;
                  test_result <= 1'b1;
                end
                else begin
                  addr_to_test <= addr_to_test + 24'd1;
                  if (addr_to_test[4:0] == 5'h10) begin
                    state <= REFRESH_AFTER_CHK;
                    rfsh_rq <= 1'b1;
                  end
                  else if (data_from_sdram != 16'hAAAA) begin
                    state <= RESET;
                    test_in_progress <= 1'b0;
                    test_result <= 1'b0;
                  end
                  else begin
                    read_rq <= 1'b1;
                  end
                end
              end
              else
                read_rq <= 1'b0;
            end
          REFRESH_AFTER_CHK:
            begin
              rfsh_rq <= 1'b0;          
              if (busy == 1'b0) begin
                state <= CHK_DATA;
                read_rq <= 1'b1;
              end
            end
        endcase
      end
    end
  end
endmodule
