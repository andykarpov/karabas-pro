`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:25:20 08/09/2018 
// Design Name: 
// Module Name:    sdram_controller 
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

`default_nettype none

module sdram_controller (
  input wire clk,                // este reloj debe ser el doble del reloj de la SDRAM
  input wire clken,              // enable para el reloj, para poder ir más lento si hiciera falta
  input wire reset,              // normalmente conectado a la versión negada del pin "locked" del PLL/MMCM
  // host interface
  input wire [23:0] addr,
  input wire write_rq,
  input wire read_rq,
  input wire rfsh_rq,
  input wire [15:0] din,
  output reg [15:0] dout,
  output reg busy,
  // sdram interface
  output reg sdram_clk,          // señales validas en flanco de suida de CK
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
    FREQCLKSDRAM = 64,    // frecuencia en MHz a la que irá la SDRAM
    CL           = 3'd3;  // 3'd2 si es -7E, 3'd3 si es -75

  localparam   // comandos a la SDRAM. RAS,CAS,WE (pag. 32)
    NO_OP = 3'b111,  // no operation
    ACTIV = 3'b011,  // select bank and activate row. addr=fila, ba=banco
    READ  = 3'b101,  // select bank and column, and start READ burst. addr[8:0]=columna. ba=banco. A10=1 para precharge después de read
    WRIT  = 3'b100,  // select bank and column, and start WRITE burst. Mismas cosas que en READ. El dato debe estar ya presente en DQ
    BTER  = 3'b110,  // burst terminate
    PREC  = 3'b010,  // precarga. A10=1, precarga todos los bancos. A10=0, BA determina qué banco se precarga.
    ASRF  = 3'b001,  // autorefresh si CKE=1, self refresh si CKE=0
    LMRG  = 3'b000  // load mode register. Modo en addr[11:0]
    ;

  reg [2:0] comando;
  reg cke;
  reg [1:0] ba;
  reg dqmh_n, dqml_n;
  reg [12:0] saddr;
  assign sdram_addr = saddr;
  assign sdram_ras_n = comando[2];
  assign sdram_cas_n = comando[1];
  assign sdram_we_n  = comando[0];
  assign sdram_cke = cke;
  assign sdram_ba = ba;
  assign sdram_dqmh_n = dqmh_n;
  assign sdram_dqml_n = dqml_n;
  assign sdram_cs_n = 1'b0;    // siempre activa!

  localparam
    WAIT100US  = 100*FREQCLKSDRAM,
    TRP        = (20*FREQCLKSDRAM/1000)+1,
    TRFC       = (66*FREQCLKSDRAM/1000)+1,
    TRCD       = (20*FREQCLKSDRAM/1000)+1
    ;

  localparam
    RESET             = 5'd0,    // CKE a 0 durante este periodo. Esperar 100us (MAXCONT100)
    INIT_PRECHARGEALL = 5'd1,    // tras los 100us, se hace un precharge all. Hay que esperar tRP = 20ns (dos ciclos)
    INIT_AUTOREFRESH1 = 5'd2,    // tras esperar, se hace un autorefresh y se esperan tRFC = 66 ns (5 clks)
    INIT_AUTOREFRESH2 = 5'd3,    // tras esperar, se hace otro autorefresh y se esperan tRFC = 66 ns (5 clks)
    INIT_LOAD_MODE    = 5'd4,    // cargar el registro de modo y esperar tMRD = 2 clks
    IDLE              = 5'd5,    // espera a por un comando
    ACTIVE_ROW_READ   = 5'd6,    // activa una fila
    ISSUE_READ        = 5'd7,    // activa una columna y manda leer
    GET_DATA          = 5'd8,    // recoge el dato leido
    ACTIVE_ROW_WRITE  = 5'd9,
    ISSUE_WRITE       = 5'd10,
    DO_AUTOREFRESH    = 5'd11,
    WAIT_STATES       = 5'd31;   // subFSM para esperar N estados de reloj

  localparam
    modo_operacion_sdram = {6'b000_1_00,CL,4'b0_000};   // pag. 47. El valor de CL depende de si es -75 o -7E

  reg load_wsreg;
  reg [13:0] cont_wstates = 14'd0;
  reg [13:0] wait_states;

  reg [4:0] state = RESET;  
  reg [4:0] next_state;
  reg load_rtstate;
  reg [4:0] reg_return_state = RESET;
  reg [4:0] return_state;  
  
  reg load_dout;

  always @* begin
    cke = 1'b1;  // valores por defecto
    ba = 2'b00;
    dqmh_n = 1'b0;
    dqml_n = 1'b0;
    load_wsreg = 1'b0;
    wait_states = 14'd0;
    comando = NO_OP;
    load_rtstate = 1'b0;
    return_state = RESET;
    next_state = RESET;
    busy = 1'b1;
    saddr = 13'h0000;
    load_dout = 1'b0;
    case (state)
      RESET: 
        begin
          cke = 1'b0;
          wait_states = WAIT100US;
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = INIT_PRECHARGEALL;
        end
      INIT_PRECHARGEALL:
        begin
          comando = PREC;       // tras este comando hay que esperar tRP = 20 ns (2 CLK @64 MHz)
          wait_states = TRP-1;  
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = INIT_AUTOREFRESH1;
        end
      INIT_AUTOREFRESH1:
        begin
          comando = ASRF;       // tras este comando hay que esperar tRFC = 66 ns (5 CLKs @64 MHz)
          wait_states = TRFC-1;
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = INIT_AUTOREFRESH2;
        end          
      INIT_AUTOREFRESH2:
        begin
          comando = ASRF;       // tras este comando hay que esperar tRFC = 66 ns (5 CLKs @64 MHz)
          wait_states = TRFC-1;  
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = INIT_LOAD_MODE;
        end    
      INIT_LOAD_MODE:
        begin
          comando = LMRG;       // tras este comando hay que esperar 2 CLKs
          saddr = modo_operacion_sdram;
          wait_states = 14'd1;  // 1 CLKs
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = IDLE;
        end        
      IDLE:
        begin
          busy = 1'b0;
          casex ({rfsh_rq,read_rq,write_rq})
            3'b1xx:  next_state = DO_AUTOREFRESH;
            3'b01x:  next_state = ACTIVE_ROW_READ; 
            3'b001:  next_state = ACTIVE_ROW_WRITE;
            default: next_state = IDLE;
          endcase
        end
      ACTIVE_ROW_READ:
        begin
          comando = ACTIV;      // tras este comando, hay que esperar tRCD (20 ns, o sea 2 CLK @64 MHz)
          saddr = addr[23:11];  // fila que queremos abrir (parte más alta de la dirección)
          ba = addr[1:0];       // el banco lo establecen los dos bits más bajos de la dirección
          wait_states = TRCD-1; // 1 CLKs para esperar ACTIV
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = ISSUE_READ;
        end
      ISSUE_READ:
        begin
          comando = READ;
          saddr = {4'b0010,addr[10:2]};   // columna. auto-precharge (20ns) al final del read
          ba = addr[1:0];
          wait_states = CL-1;  // 2 o 3 ws
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = GET_DATA;
        end
      GET_DATA:
        begin
          load_dout = 1'b1;
          wait_states = TRP-1;  // 1 CLKs para esperar el autoprecharge
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = IDLE;
        end
      ACTIVE_ROW_WRITE:
        begin
          comando = ACTIV;      // tras este comando, hay que esperar tRCD (20 ns, o sea 2 CLK @64 MHz)
          saddr = addr[23:11];  // fila que queremos abrir (parte más alta de la dirección)
          ba = addr[1:0];       // el banco lo establecen los dos bits más bajos de la dirección
          wait_states = TRCD-1; // 1 CLKs para esperar ACTIV
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = ISSUE_WRITE;
        end
      ISSUE_WRITE:
        begin
          comando = WRIT;
          saddr = {4'b0010,addr[10:2]};   // columna. auto-precharge (20ns) al final del read
          ba = addr[1:0];
          wait_states = TRP;   // después de WRITE, esperar (NOP+autoprecharge)
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = IDLE;
        end
      DO_AUTOREFRESH:
        begin
          comando = ASRF;       // tras este comando hay que esperar 66 ns (5 CLKs @64 MHz)
          wait_states = TRFC-1;
          load_wsreg = 1'b1;
          next_state = WAIT_STATES;
          load_rtstate = 1'b1;
          return_state = IDLE;
        end    
          
      WAIT_STATES:
        begin
          comando = NO_OP;
          if (cont_wstates == 14'd1)
            next_state = reg_return_state;
          else
            next_state = WAIT_STATES;
        end
    endcase
  end

  initial sdram_clk = 1'b0;
  always @(posedge clk) begin
    if (clken == 1'b1) begin
      sdram_clk <= ~sdram_clk;
      if (reset == 1'b1) begin
        state <= RESET;
      end
      else begin
        if (sdram_clk == 1'b1) begin
          state <= next_state;
          if (load_rtstate == 1'b1)
            reg_return_state <= return_state;
        end
      end
    end
  end

  always @(posedge clk) begin
    if (clken == 1'b1) begin
      if (sdram_clk == 1'b1) begin
        if (load_wsreg == 1'b1)
          cont_wstates <= wait_states;
        else if (cont_wstates != 14'd0)
          cont_wstates <= cont_wstates + 14'h3FFF;  // sumar -1
        else
          cont_wstates <= 14'd0;
      end
    end
  end
  
  always @(posedge clk) begin
    if (clken == 1'b1) begin
      if (load_dout == 1'b1)
        dout <= sdram_dq;
    end
  end

  assign sdram_dq = (state == ISSUE_WRITE)? din : 16'hZZZZ;

endmodule

`default_nettype wire