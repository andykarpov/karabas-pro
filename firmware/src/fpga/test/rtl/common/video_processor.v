`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:31:14 10/18/2012 
// Design Name: 
// Module Name:    dummy_ula 
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

module background (
    input wire clk,
    input wire mode,
    output reg [5:0] r,
    output reg [5:0] g,
    output reg [5:0] b,
    output wire [8:0] hc,
    output wire [8:0] vc,
    output wire hsync,
    output wire vsync,
    output wire csync    
    );

    wire blank;

    sync_generator_pal_ntsc sincronismos (
    .clk(clk),   // 7 MHz
    .in_mode(mode),  // 0: PAL, 1: NTSC
    .csync_n(csync),
    .hsync_n(hsync),
    .vsync_n(vsync),
    .hc(hc),
    .vc(vc),
    .blank(blank)
    );
    
    always @* begin
      if (blank == 1'b1) begin
        {r,g,b} = 18'b000000_000000_000000;
      end
      else begin
        if (vc >= 9'd90*0 && vc < 9'd90*1) begin
          if (hc >= 9'd57*0 && hc < 9'd57*1)
            {r,g,b} = 18'b100000_000000_000000;
          else if (hc >= 9'd57*1 && hc < 9'd57*2)
            {r,g,b} = 18'b010000_000000_000000;
          else if (hc >= 9'd57*2 && hc < 9'd57*3)
            {r,g,b} = 18'b001000_000000_000000;
          else if (hc >= 9'd57*3 && hc < 9'd57*4)
            {r,g,b} = 18'b000100_000000_000000;
          else if (hc >= 9'd57*4 && hc < 9'd57*5)
            {r,g,b} = 18'b000010_000000_000000;
          else
            {r,g,b} = 18'b000001_000000_000000;
        end
        else if (vc >= 9'd90*1 && vc < 9'd90*2) begin
          if (hc >= 9'd57*0 && hc < 9'd57*1)
            {r,g,b} = 18'b000000_100000_000000;
          else if (hc >= 9'd57*1 && hc < 9'd57*2)
            {r,g,b} = 18'b000000_010000_000000;
          else if (hc >= 9'd57*2 && hc < 9'd57*3)
            {r,g,b} = 18'b000000_001000_000000;
          else if (hc >= 9'd57*3 && hc < 9'd57*4)
            {r,g,b} = 18'b000000_000100_000000;
          else if (hc >= 9'd57*4 && hc < 9'd57*5)
            {r,g,b} = 18'b000000_000010_000000;
          else
            {r,g,b} = 18'b000000_000001_000000;
        end
        else begin
          if (hc >= 9'd57*0 && hc < 9'd57*1)
            {r,g,b} = 18'b000000_000000_100000;
          else if (hc >= 9'd57*1 && hc < 9'd57*2)
            {r,g,b} = 18'b000000_000000_010000;
          else if (hc >= 9'd57*2 && hc < 9'd57*3)
            {r,g,b} = 18'b000000_000000_001000;
          else if (hc >= 9'd57*3 && hc < 9'd57*4)
            {r,g,b} = 18'b000000_000000_000100;
          else if (hc >= 9'd57*4 && hc < 9'd57*5)
            {r,g,b} = 18'b000000_000000_000010;
          else
            {r,g,b} = 18'b000000_000000_000001;
        end
      end
    end        
endmodule

module window_on_background (
    input wire clk,
    input wire mode,
    input wire [9:0] addr,
    input wire [7:0] data,
    input wire we,
    input wire hidetextwindow,
    output reg [5:0] r,
    output reg [5:0] g,
    output reg [5:0] b,
    output wire hsync,
    output wire vsync,
    output wire csync
    );
   
    parameter
      BEGINX = 8 * 5,          // X = 5  posicion horizontal esquina arriba izquierda
      BEGINY = 8 * 7,          // Y = 7  posicion vertical esquina arriba izquierda
      ENDX = BEGINX + 8 * 32,  // 32 columnas de texto por linea
      ENDY = BEGINY + 8 * 19;  // 19 lineas de texto

    wire [5:0] rb,gb,bb;
    wire [8:0] hc,vc;
   
    background bg (
    .clk(clk),
    .mode(mode),
    .r(rb),
    .g(gb),
    .b(bb),
    .hc(hc),
    .vc(vc),
    .hsync(hsync),
    .vsync(vsync),
    .csync(csync)
    );
    
    reg [7:0] charrom[0:2047];
    initial begin
      $readmemh ("CP437.hex", charrom);
    end
    
    wire in_text_window = (hc >= BEGINX && hc < ENDX && vc >= BEGINY && vc < ENDY);
    wire showing_text_window = (~hidetextwindow && hc >= (BEGINX+9'd8) && hc < (ENDX+9'd8) && vc >= BEGINY && vc < ENDY);
    
    reg [7:0] chc = 8'h00;
    reg [7:0] cvc = 8'h00;
    reg [7:0] shiftreg;
    reg [7:0] character;
    wire [7:0] dout;
    reg [9:0] charaddr = 10'd0;

   screenfb buffer_pantalla (
      .clk(clk),
      .addr_read(charaddr),
      .addr_write(addr),
      .we(we),
      .din(data),
      .dout(dout)
   );

   always @(posedge clk) begin
      // H and C counters for text window
      if (hc == (BEGINX-9'd1)) begin  // empezamos a contar 8 pixeles antes, para tener ya el shiftreg cargado cuando comencemos de verdad
         chc <= 8'd0;
         if (vc == BEGINY)
            cvc <= 8'd0;
         else
            cvc <= cvc + 8'd1;
      end
      else begin
         chc <= chc + 8'd1;
      end

      // char generator
      if (in_text_window) begin
         if (chc[2:0] == 3'b010) begin
            charaddr <= {cvc[7:3],5'b00000} + {2'b00,chc[7:3]};
         end
         if (chc[2:0] == 3'b100) begin         
            character <= dout; // lee el caracter siguiente
         end
         if (chc[2:0] == 3'b111) begin
            shiftreg <= charrom[{character,cvc[2:0]}];
         end
      end
      if (showing_text_window && chc[2:0] != 3'b111) begin
         shiftreg <= {shiftreg[6:0],1'b0};
      end
    end
    
    always @* begin
      {r,g,b} = {rb,gb,bb};
      if (showing_text_window)  // ventana de 32x16 caracteres de 8x8
         {r,g,b} = {18{shiftreg[7]}};  // texto blanco sobre fondo negro
    end
endmodule

module screenfb (
   input wire clk,
   input wire [9:0] addr_read,
   input wire [9:0] addr_write,
   input wire we,
   input wire [7:0] din,
   output reg [7:0] dout
   );
   
   reg [7:0] screenrom[0:607];  // ventana de 32 x 19 caracteres
   initial begin
     $readmemh ("texto_inicial.hex", screenrom);
   end
    
   always @(posedge clk) begin
      dout <= screenrom[addr_read];
      if (we)
         screenrom[addr_write] <= din;
   end
endmodule

module teletype (
   input wire clk,
   input wire mode,
   input wire [7:0] chr,
   input wire we,
   output reg busy,
   input wire hidetextwindow,
   output wire [5:0] r,
   output wire [5:0] g,
   output wire [5:0] b,
   output wire hsync,
   output wire vsync,
   output wire csync
   );

   reg [9:0] addr = 10'd0;
   reg [7:0] data = 8'h00, dscreen = 8'h00;
   reg wescreen = 1'b0;
   initial busy = 1'b0;
    
   window_on_background screen (
    .clk(clk),
    .mode(mode),
    .addr(addr),
    .data(dscreen),
    .we(wescreen),
    .hidetextwindow(hidetextwindow),
    .r(r),
    .g(g),
    .b(b),
    .hsync(hsync),
    .vsync(vsync),
    .csync(csync)
    );
    
   parameter
      IDLE = 4'd0,
      PCOMMAND = 4'd1,
      ATR = 4'd3,
      ATC = 4'd4,
      CLS = 4'd5,
      PUTCHAR = 4'd6      
      ;
      
   parameter
      AT = 8'd22,
      CR = 8'd13,
      HOME = 8'd12
      ;
            
   reg [2:0] estado = IDLE;
   reg [4:0] row = 5'd0;
    
   always @(posedge clk) begin
      case (estado)
         IDLE,ATR,ATC: 
            begin
               if (we) begin
                  data <= chr;
                  if (estado == ATR) begin
                     row <= chr[4:0];
                     estado <= ATC;
                  end
                  else if (estado == ATC) begin
                     addr <= {row,chr[4:0]};
                     estado <= IDLE;
                  end
                  else begin
                     busy <= 1'b1;
                     estado <= PCOMMAND;
                  end                  
               end
            end
         PCOMMAND:
            begin
               if (data == AT) begin
                  busy <= 1'b0;
                  estado <= ATR;               
               end
               else if (data == HOME) begin
                  addr <= 9'd0;
                  wescreen <= 1'b1;
                  dscreen <= 8'h20;
                  estado <= CLS;
               end
               else if (data == CR) begin
                  addr <= {(addr[8:5] + 4'd1),5'b0000};
                  busy <= 1'b0;
                  estado <= IDLE;
               end
               else begin
                  dscreen <= data;
                  wescreen <= 1'b1;
                  estado <= PUTCHAR;
               end
            end
         CLS:
            begin
               if (addr == 10'd544) begin
                  busy <= 1'b0;
                  estado <= IDLE;
                  wescreen <= 1'b0;
                  addr <= 10'd0;
               end
               else
                  addr <= addr + 10'd1;
            end
         PUTCHAR:
            begin
               wescreen <= 1'b0;
               busy <= 1'b0;
               addr <= addr + 10'd1;
               estado <= IDLE;
            end
      endcase
   end
endmodule    

module updater (
   input wire clk,
   input wire mode,
   //--------------------------
   input wire vga,
   input wire [56:0] dna,
   input wire memtest_progress,
   input wire memtest_result,
   input wire [7:0] joystick1,
   input wire [7:0] joystick2,
   input wire [7:0] earcode,
   input wire sdtest_progress,
   input wire sdtest_result,
   input wire flashtest_progress,
   input wire flashtest_result,
   input wire sdramtest_progress,
   input wire sdramtest_result,
   input wire [15:0] flash_vendor_id,
   input wire [2:0] mousebutton,
   input wire hidetextwindow,
   //--------------------------
   output wire [5:0] r,
   output wire [5:0] g,
   output wire [5:0] b,
   output wire hsync,
   output wire vsync,
   output wire csync
   );
      
   reg [7:0] chr = 8'd0;
   reg we = 1'b0;
   wire busy;
   
   teletype teletipo (
     .clk(clk),
     .mode(mode),
     .chr(chr),
     .we(we),
     .busy(busy),
     .hidetextwindow(hidetextwindow),
     .r(r),
     .g(g),
     .b(b),
     .hsync(hsync),
     .vsync(vsync),
     .csync(csync)
     );
   
   reg [59:0] regdna = 60'h000000000000000;
   reg [3:0] cntdigitsdna = 4'd0;
   reg [7:0] hexvalues[0:15];
   reg [7:0] stringlist[0:2047];
   integer i;
   initial begin
      for (i=0;i<10;i=i+1) begin
         hexvalues[i] = "0" + i;
      end
      for (i=10;i<16;i=i+1) begin
         hexvalues[i] = "A" - 10 + i;
      end
      for (i=0;i<2048;i=i+1) begin
         stringlist[i] = 8'hFF;
      end
      stringlist[0] = 8'd22;  // ADDRVGA
      stringlist[1] = 8'd3;
      stringlist[2] = 8'd10;
      stringlist[3] = "V";
      stringlist[4] = "G";
      stringlist[5] = "A";
      stringlist[6] = " ";
      stringlist[7] = 8'hFF;
      
      stringlist[8] = 8'd22;  // ADDRNTSC
      stringlist[9] = 8'd3;
      stringlist[10] = 8'd10;
      stringlist[11] = "N";
      stringlist[12] = "T";
      stringlist[13] = "S";
      stringlist[14] = "C";
      stringlist[15] = 8'hFF;

      stringlist[16] = 8'd22;  // ADDRPAL
      stringlist[17] = 8'd3;
      stringlist[18] = 8'd10;
      stringlist[19] = "P";
      stringlist[20] = "A";
      stringlist[21] = "L";
      stringlist[22] = " ";
      stringlist[23] = 8'hFF;
      
      stringlist[24] = 8'd22;  // ADDRATDNA
      stringlist[25] = 8'd4;
      stringlist[26] = 8'd10;
      stringlist[27] = 8'hFF;
      
      stringlist[28] = 8'd22;  // ADDRATMEM
      stringlist[29] = 8'd6;
      stringlist[30] = 8'd21;
      stringlist[31] = 8'hFF;
      
      stringlist[32] = "O";  // ADDROK
      stringlist[33] = "K";
      stringlist[34] = " ";
      stringlist[35] = " ";
      stringlist[36] = " ";
      stringlist[37] = 8'hFF;
      
      stringlist[38] = "E";  // ADDRERROR
      stringlist[39] = "R";
      stringlist[40] = "R";
      stringlist[41] = "O";
      stringlist[42] = "R";
      stringlist[43] = 8'hFF;
      
      stringlist[44] = "w";  // ADDRWAIT
      stringlist[45] = "a";
      stringlist[46] = "i";
      stringlist[47] = "t";
      stringlist[48] = " ";
      stringlist[49] = 8'hFF;
      
      stringlist[50] = 8'd22;  // ADDRATJOY1
      stringlist[51] = 8'd7;
      stringlist[52] = 8'd21;
      stringlist[53] = "U";
      stringlist[54] = "D";
      stringlist[55] = "L";
      stringlist[56] = "R";
      stringlist[57] = "1";
      stringlist[58] = "2";
      stringlist[59] = "3";
      stringlist[60] = "S";
      stringlist[61] = 8'hFF;

      stringlist[62] = 8'd22;  // ADDRATJOY2
      stringlist[63] = 8'd8;
      stringlist[64] = 8'd21;
      stringlist[65] = "U";
      stringlist[66] = "D";
      stringlist[67] = "L";
      stringlist[68] = "R";
      stringlist[69] = "1";
      stringlist[70] = "2";
      stringlist[71] = "3";
      stringlist[72] = "S";
      stringlist[73] = 8'hFF;

      stringlist[74] = 8'd22;  // ADDRATEAR
      stringlist[75] = 8'd10;
      stringlist[76] = 8'd21;
      stringlist[77] = 8'hFF;

      stringlist[78] = 8'd22;  // ADDRATMOUSE
      stringlist[79] = 8'd14;
      stringlist[80] = 8'd21;
      stringlist[81] = " ";
      stringlist[82] = " ";
      stringlist[83] = " ";
      stringlist[84] = 8'hFF;

      stringlist[85] = 8'd22;  // ADDRATSD
      stringlist[86] = 8'd12;
      stringlist[87] = 8'd21;
      stringlist[88] = 8'hFF;

      stringlist[89] = 8'd22;  // ADDRATFLASH
      stringlist[90] = 8'd13;
      stringlist[91] = 8'd21;
      stringlist[92] = 8'hFF;
      
      stringlist[93] = "O";  // ADDROKFLASH
      stringlist[94] = "K";
      stringlist[95] = "-";
      stringlist[96] = " ";
      stringlist[97] = " ";
      stringlist[98] = 8'hFF;
      
      stringlist[99] = 8'd22;  // ADDRATSDRAM
      stringlist[100] = 8'd11;
      stringlist[101] = 8'd21;
      stringlist[102] = 8'hFF;
   end
   
   reg [10:0] addrstr = 11'd0;

   parameter
      ADDRVGA = 11'd0,
      ADDRNTSC = 11'd8,
      ADDRPAL = 11'd16,
      ADDRATDNA = 11'd24,
      ADDRATMEM = 11'd28,
      ADDROK = 11'd32,
      ADDRERROR = 11'd38,
      ADDRINPROGRESS = 11'd44,
      ADDRJOYSTATE1 = 11'd50,
      ADDRJOYSTATE2 = 11'd62,
      ADDREAR = 11'd74,
      ADDRMOUSE = 11'd78,
      ADDRATSD = 11'd85,
      ADDRATFLASH = 11'd89,
      ADDROKFLASH = 11'd93,
      ADDRATSDRAM = 11'd99
      ;

   parameter
      PUTVIDEO = 5'd0,
      PUTDNA = 5'd1,
      PUTDNA1 = 5'd2,
      PUTRAMTEST = 5'd3,
      PUTRAMTEST1 = 5'd4,
      PUTJOYTEST1 = 5'd5,
      PUTJOYTEST2 = 5'd6,
      PUTEARTEST = 5'd7,
      PUTSDTEST = 5'd8,
      PUTSDTEST1 = 5'd9,
      PUTFLASHTEST = 5'd10,
      PUTFLASHTEST1 = 5'd11,
      PUTEARTEST1 = 5'd12,
      PUTMOUSETEST = 5'd13,
      PUTSDRAMTEST = 5'd14,
      PUTSDRAMTEST1 = 5'd15,
      SENDCHAR = 5'd28,
      SENDCHAR1 = 5'd29,
      SENDSTR = 5'd30,
      SENDSTR1 = 5'd31
      ;
   
   reg [4:0] estado = PUTVIDEO, 
             retorno_de_sendchar = PUTVIDEO, 
             retorno_de_sendstr = PUTVIDEO;
      
   always @(posedge clk) begin
      case (estado)
         PUTVIDEO:
            begin
               if (vga == 1'b1)
                  addrstr <= ADDRVGA;
               else if (mode == 1'b0)
                  addrstr <= ADDRPAL;
               else
                  addrstr <= ADDRNTSC;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTDNA;
            end
            
         PUTDNA:
            begin
               addrstr <= ADDRATDNA;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTDNA1;
               regdna <= {3'b000,dna};
               cntdigitsdna <= 4'd0;
            end
         PUTDNA1:
            begin
               if (cntdigitsdna == 4'd15)
                  estado <= PUTRAMTEST;
               else begin
                  cntdigitsdna <= cntdigitsdna + 4'd1;
                  chr <= hexvalues[regdna[59:56]];
                  regdna <= {regdna[55:0],4'b0000};
                  retorno_de_sendchar <= PUTDNA1;
                  estado <= SENDCHAR;
               end
            end
            
         PUTRAMTEST:
            begin
               addrstr <= ADDRATMEM;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTRAMTEST1;
            end
         PUTRAMTEST1:
            begin
               if (memtest_progress == 1'b1)
                  addrstr <= ADDRINPROGRESS;
               else if (memtest_result == 1'b1)
                  addrstr <= ADDROK;
               else
                  addrstr <= ADDRERROR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTJOYTEST1;
            end
            
         PUTJOYTEST1:
            begin
               stringlist[ADDRJOYSTATE1+3]  <= (joystick1[7] == 1'b1)? "U" : " ";
               stringlist[ADDRJOYSTATE1+4]  <= (joystick1[6] == 1'b1)? "D" : " ";
               stringlist[ADDRJOYSTATE1+5]  <= (joystick1[5] == 1'b1)? "L" : " ";
               stringlist[ADDRJOYSTATE1+6]  <= (joystick1[4] == 1'b1)? "R" : " ";
               stringlist[ADDRJOYSTATE1+7]  <= (joystick1[3] == 1'b1)? "1" : " ";
               stringlist[ADDRJOYSTATE1+8]  <= (joystick1[2] == 1'b1)? "2" : " ";
               stringlist[ADDRJOYSTATE1+9]  <= (joystick1[1] == 1'b1)? "3" : " ";
               stringlist[ADDRJOYSTATE1+10] <= (joystick1[0] == 1'b1)? "S" : " ";
               addrstr <= ADDRJOYSTATE1;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTJOYTEST2;
            end
            
         PUTJOYTEST2:
           begin
              stringlist[ADDRJOYSTATE2+3]  <= (joystick2[7] == 1'b1)? "U" : " ";
              stringlist[ADDRJOYSTATE2+4]  <= (joystick2[6] == 1'b1)? "D" : " ";
              stringlist[ADDRJOYSTATE2+5]  <= (joystick2[5] == 1'b1)? "L" : " ";
              stringlist[ADDRJOYSTATE2+6]  <= (joystick2[4] == 1'b1)? "R" : " ";
              stringlist[ADDRJOYSTATE2+7]  <= (joystick2[3] == 1'b1)? "1" : " ";
              stringlist[ADDRJOYSTATE2+8]  <= (joystick2[2] == 1'b1)? "2" : " ";
              stringlist[ADDRJOYSTATE2+9]  <= (joystick2[1] == 1'b1)? "3" : " ";
              stringlist[ADDRJOYSTATE2+10] <= (joystick2[0] == 1'b1)? "S" : " ";
              addrstr <= ADDRJOYSTATE2;
              estado <= SENDSTR;
              retorno_de_sendstr <= PUTEARTEST;
           end
           
         PUTEARTEST:
            begin
               addrstr <= ADDREAR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTEARTEST1;
            end
         PUTEARTEST1:
            begin
               chr <= earcode;
               estado <= SENDCHAR;
               retorno_de_sendchar <= PUTSDTEST;
            end

         PUTSDTEST:
            begin
               addrstr <= ADDRATSD;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSDTEST1;
            end
         PUTSDTEST1:
            begin
               if (sdtest_progress == 1'b1)
                  addrstr <= ADDRINPROGRESS;
               else if (sdtest_result == 1'b1)
                  addrstr <= ADDROK;
               else
                  addrstr <= ADDRERROR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTFLASHTEST;
            end
            
         PUTFLASHTEST:
            begin
               addrstr <= ADDRATFLASH;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTFLASHTEST1;
            end
         PUTFLASHTEST1:
            begin
               if (flashtest_progress == 1'b1)
                  addrstr <= ADDRINPROGRESS;
               else if (flashtest_result == 1'b1) begin
                  addrstr <= ADDROKFLASH;
                  stringlist[ADDROKFLASH+3] <= flash_vendor_id[15:8];
                  stringlist[ADDROKFLASH+4] <= flash_vendor_id[7:0];
               end
               else
                  addrstr <= ADDRERROR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTMOUSETEST;
            end
            
         PUTMOUSETEST:
            begin
               stringlist[ADDRMOUSE+3] <= (mousebutton[0]==1'b1)? "L" : " ";
               stringlist[ADDRMOUSE+4] <= (mousebutton[2]==1'b1)? "M" : " ";
               stringlist[ADDRMOUSE+5] <= (mousebutton[1]==1'b1)? "R" : " ";
               addrstr <= ADDRMOUSE;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSDRAMTEST;
            end
               
         PUTSDRAMTEST:
            begin
               addrstr <= ADDRATSDRAM;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTSDRAMTEST1;
            end
         PUTSDRAMTEST1:
            begin
               if (sdramtest_progress == 1'b1)
                  addrstr <= ADDRINPROGRESS;
               else if (sdramtest_result == 1'b1)
                  addrstr <= ADDROK;
               else
                  addrstr <= ADDRERROR;
               estado <= SENDSTR;
               retorno_de_sendstr <= PUTVIDEO;
            end
            
         SENDSTR:
            begin
               chr <= stringlist[addrstr];
               addrstr <= addrstr + 11'd1;
               estado <= SENDSTR1;
            end
         SENDSTR1:
            begin
               if (chr == 8'hFF)
                  estado <= retorno_de_sendstr;
               else begin
                  estado <= SENDCHAR;
                  retorno_de_sendchar <= SENDSTR;
               end
            end
         
         SENDCHAR:
            begin
               if (busy == 1'b0) begin
                  we <= 1'b1;
                  estado <= SENDCHAR1;
               end
            end
         SENDCHAR1:
            begin
               we <= 1'b0;
               estado <= retorno_de_sendchar;
            end
      endcase
   end
endmodule

