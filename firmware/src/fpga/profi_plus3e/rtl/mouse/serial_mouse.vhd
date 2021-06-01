-------------------------------------------------------------------------------
-- Serial mouse emulation
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity serial_mouse is
port(
	 CLK			: in std_logic;
	 CLKEN 		: in std_logic;
	 N_RESET 	: in std_logic := '1';
	 
    A          : in std_logic_vector(15 downto 0);
	 DI 			: in std_logic_vector(7 downto 0);
	 WR_N 		: in std_logic := '1';
	 RD_N 		: in std_logic := '1';
	 IORQ_N 		: in std_logic := '1';
	 M1_N 		: in std_logic := '1';
	 CPM 			: in std_logic := '0';
	 DOS 			: in std_logic := '0';
	 ROM14 		: in std_logic := '0';
	 
	 MS_X 	 	: in signed(7 downto 0) := "00000000";
	 MS_Y 	 	: in signed(7 downto 0) := "00000000";
	 MS_BTNS 	: in std_logic_vector(2 downto 0) := "000";
	 MS_PRESET  : in std_logic := '0';
	 MS_EVENT 	: in std_logic := '0';
	 
	 DO			: out std_logic_vector(7 downto 0);
	 INT_N 		: out std_logic := '1';
	 OE_N 		: out std_logic := '1'
	 
);
end serial_mouse;

architecture RTL of serial_mouse is
		
	-- Microsoft mouse flavour:
	-- Bit  7  6  5  4  3  2  1  0
	--		  x  1  L  R Y7 Y6 X7 X6   Byte 0
	--		  x  0 X5 X4 X3 X2 X1 X0   Byte 1
	--		  x  0 Y5 Y4 Y3 Y2 Y1 Y0   Byte 2
	-- L = Left Button (1 when pressed)
	-- R = Right Button (1 when pressed)
	-- X0..X7 = X distance 8-bit two's complement value -128 to +127
	-- Y0..Y7 = Y distance 8-bit two's complement value -128 to +127
	
	-- https://www.sgu.ru/sites/default/files/textdocsfiles/2014/01/10/k580bb51.pdf
	-- https://www.intel.cn/content/dam/www/programmable/us/en/pdfs/literature/ds/ds8251.pdf
	-- http://www.danbigras.ru/RK86/RS232/RS232s.asm
	
	-- # регистр команд (запись)
	-- D7 - 1=Режим поиска синхросимволов (EH)
	-- D6 - 1=сброс в исходное состояние (IR)
	-- D5 - 1=передача разрешена (RTS)
	-- D4 - 1=установка ошибок в исходное состояние (ER)
	-- D3 - 1=конец передачи (SBRK), 0=нормальная работа передачи
	-- D2 - 1=разрешение приема (RxE)
	-- D1 - 1=готовность передачи (DTR)
	-- D0 - 1=разрешение передачи (TxEN)
	
	-- # регистр статуса (чтение)
	-- D7 - DSR 1=готовность передатчика терминала
	-- D6 - SYNDET синхросимвол найден
	-- D5 - FE 1=ошибка стоп-бита
	-- D4 - OE 1=переполнение буфера
	-- D3 - PE 1=ошибка четности
	-- D2 - TxE   1=конец передачи
	-- D1 - RxRDY 1=готовность приемника
	-- D0 - TxRDY 1=готовность передатчика
	
	-- инициализация чтения драйвером мыши:
	-- DTR + RxE + ER + RTS
	
	-- алгоритм приема
	-- если RxRDY = 1 - можно читать байт
	
	signal do_reg : std_logic_vector(7 downto 0) := "00000000";	
	signal ctl_reg : std_logic_vector(7 downto 0) := "00000000";
	signal status_reg : std_logic_vector(7 downto 0) := "00000101";
	
	signal rxrdt : std_logic := '0';
	signal txrdt : std_logic := '0';
	
	signal cnt_wait : unsigned(2 downto 0) := "000";
	signal cnt_byte : unsigned(1 downto 0) := "11";
	
	signal p4 : std_logic := '1';
	signal vv51_cs : std_logic := '1';
	signal vv51_cs_cmd : std_logic := '1';
	signal vv51_cs_data : std_logic := '1';
	signal vv51_read : std_logic := '0';
	signal vv51_read_after : std_logic := '0';
	
	signal is_mode : std_logic := '1';
	
	type rmachine IS(st_init, st_prepare, st_byte0, st_byte0r, st_wait0, st_byte1, st_byte1r, st_wait1, st_byte2, st_byte2r, st_wait2); --state machine datatype
	signal state 			: rmachine := st_init; --current state
	
	signal prev_event : std_logic := '0';
	signal new_data 	: std_logic := '0';
	signal ms_buf 		: std_logic_vector(17 downto 0) := (others => '0');
	
	signal hw_int_n : std_logic := '1';	
	signal hw_int_do : std_logic_vector(7 downto 0);
	signal hw_int_oe_n : std_logic := '1';
	signal hw_int_en 	: std_logic := '0';
	
begin

-- Serial

--vi53_cs <= '0' when (adress(7)='1' and adress(4 downto 0)="01111" and iorq='0' and dos='0' and rom14='0') or			-- ROM14=0 BAS=0 ПЗУ SYS
--							(adress(7)='1' and adress(4 downto 0)="01111" and iorq='0' and CPM='0' and rom14='1') else '1';	-- CPM=1 & ROM14=1 ПЗУ DOS/ SOS
--ladr5 <= adress(5);
--ladr6 <= adress(6);
--P4 <= '0' when (adress(7)='1' and adress(4 downto 0)="10011" and iorq='0' and dos='0' and rom14='0') or			-- ROM14=0 BAS=0 ПЗУ SYS
--					  (adress(7)='1' and adress(4 downto 0)="10011" and iorq='0' and CPM='0' and rom14='1') else '1';	-- CPM=1 & ROM14=1 ПЗУ DOS/ SOS
--vv51_cs <= not adress(6) or P4;
--P4I <= adress(6) or P4;

	--p4 <= '0' when A(7)='1' and A(4 downto 0)="10011" and cpm='1' and dos='0' and rom14='1' and IORQ_N='0' else '1';
	p4 <= '0' when (A(7)='1' and A(4 downto 0)="10011" and IORQ_N='0') and ((cpm='1' and rom14='1') or (dos='1' and rom14='0')) else '1';
	vv51_cs      <= not A(6) or p4;
	vv51_cs_cmd  <= '0' when vv51_cs='0' and A(5) = '1' else '1';
	vv51_cs_data <= '0' when vv51_cs='0' and A(5) = '0' else '1';
	vv51_read <= '0' when vv51_cs_data = '0' and RD_N = '0' else '1';
	
	rxrdt <= '1' when status_reg(1) = '1' and ctl_reg(2) = '1' else '0'; -- RxRDY + RxEn
	txrdt <= '1' when status_reg(0) = '1' and status_reg(2) = '0' and ctl_reg(0) = '1' else '0'; -- TxRDY + !TxEmpty + TxEn
	
	-- vv51 ports #F3, #D3	
	process (N_RESET, CLK, WR_N, DI, vv51_cs_data, vv51_cs_cmd)
	begin
		if N_RESET = '0' then		
			ctl_reg <= "00000000";			
		elsif CLK'event and CLK = '1' then
			-- control reg
			if (vv51_cs_cmd = '0' and wr_n = '0') then 
				ctl_reg <= DI;
			end if;
		end if;
	end process;
	
	-- vv51 data / status register logic
	process (N_RESET, CLK, CLKEN, MS_EVENT, prev_event, state, new_data, status_reg, ctl_reg, MS_X, MS_Y, MS_BTNS, vv51_read, cnt_wait)
	begin
		if N_RESET = '0' then
			status_reg <= "00000101"; -- 5 = TxRdy + TxEmpty
			state <= st_init;
			new_data <= '0';
			cnt_byte <= "00";

		elsif CLKEN'event and CLKEN = '1' then 

			vv51_read_after <= vv51_read;
		
			if ctl_reg(2) = '1' then -- RxE
			
				if (MS_EVENT /= prev_event) then 
					new_data <= '1';
					prev_event <= MS_EVENT;
				end if;
			
				case state is 

					-- pause after reset
					when st_init => 
						cnt_byte <= "00";
						status_reg(1) <= '0';
						state <= st_prepare;

					-- capture mouse buffer
					when st_prepare =>
						status_reg(1) <= '0';
						if (new_data = '1' and ms_buf /= MS_BTNS(0) & MS_BTNS(1) & std_logic_vector(MS_Y(7 downto 6)) & std_logic_vector(MS_X(7 downto 6)) & std_logic_vector(MS_X(5 downto 0)) & std_logic_vector(MS_Y(5 downto 0))) then 
							ms_buf <= MS_BTNS(0) & MS_BTNS(1) & std_logic_vector(MS_Y(7 downto 6)) & std_logic_vector(MS_X(7 downto 6)) & std_logic_vector(MS_X(5 downto 0)) & std_logic_vector(MS_Y(5 downto 0));
							state <= st_byte0;
							new_data <= '0';
						else 
							state <= st_prepare;
						end if;
						
					-- preparing the first mouse byte in a packet
					when st_byte0 => 
						cnt_byte <= "00";
						cnt_wait <= "000";
						status_reg(1) <= '0';
						state <= st_byte0r;
						
					-- waiting for read by the CPU
					when st_byte0r => 
						if (vv51_read_after = '0') then
							status_reg(1) <= '0';	
							state <= st_wait0;
						else 
							status_reg(1) <= '1';
							state <= st_byte0r;
						end if;

					-- waiting 8 tacts in inactive state after the first mouse byte
					when st_wait0 => 	
						status_reg(1) <= '0';
						if (cnt_wait < 7) then 
							cnt_wait <= cnt_wait + 1;
							state <= st_wait0;
						else
							state <= st_byte1;
						end if;

					-- preparing the second mouse byte in a packet
					when st_byte1 => 
						cnt_wait <= "000";
						cnt_byte <= "01";
						status_reg(1) <= '0';
						state <= st_byte1r;
						
					-- waiting for read by CPU 
					when st_byte1r => 
						if (vv51_read_after = '0') then 
							status_reg(1) <= '0';
							state <= st_wait1;
						else 
							status_reg(1) <= '1';
							state <= st_byte1r;
						end if;

					-- waiting 8 tacts in inactive state after the second mouse byte
					when st_wait1 => 
						status_reg(1) <= '0';
						if (cnt_wait < 7) then 
							cnt_wait <= cnt_wait + 1;
							state <= st_wait1;
						else
							state <= st_byte2;
						end if;

					-- preparing the third mouse byte in a packet
					when st_byte2 => 
						cnt_wait <= "000";
						cnt_byte <= "10";
						status_reg(1) <= '0';
						state <= st_byte2r;
						
					-- waiting for read by CPU 
					when st_byte2r => 
						if (vv51_read_after = '0') then 
							status_reg(1) <= '0';
							state <= st_wait2;
						else 
							status_reg(1) <= '1';
							state <= st_byte2r;
						end if;

					-- waiting 8 tacts in inactive state after the second mouse byte
					when st_wait2 => 
						status_reg(1) <= '0';
						if (cnt_wait < 7) then 
							cnt_wait <= cnt_wait + 1;
							state <= st_wait2;
						else
							state <= st_prepare;
						end if;
						
					when others => state <= st_prepare;
				end case;
			end if;
		end if;
	end process;
			
	-- data buffer mux
	U_MUX: entity work.mmux
	port map(
		data0x => "01" & ms_buf(17 downto 12),
		data1x => "00" & ms_buf(11 downto 6),
		data2x => "00" & ms_buf(5 downto 0),
		data3x => "00000000",
		sel => std_logic_vector(cnt_byte),
		result => do_reg 
	);
	
	-- hardware int
	U_INT: entity work.hw_int 
	port map(
		 CLK		=> CLK,
		 N_RESET => N_RESET,		 
		 A 		=> A,
		 DI 		=> DI,
		 WR_N 	=> WR_N,
		 RD_N		=> RD_N,
		 IORQ_N  => IORQ_N,
		 M1_N 	=> M1_N,
		 CPM 		=> CPM,
		 DOS 		=> DOS,
		 ROM14 	=> ROM14,		 
		 RXRDT 	=> rxrdt,
		 TXRDT 	=> txrdt,		 
		 DO		=> hw_int_do,
		 INT_N 	=> hw_int_n,
		 INT_EN  => hw_int_en,
		 OE_N 	=> hw_int_oe_n
	);
			
	-- output data to CPU
	OE_N <= '0' when (vv51_cs = '0' AND RD_N = '0') or hw_int_oe_n = '0' else '1';
	DO <= 
			hw_int_do when hw_int_oe_n = '0' else
			do_reg when vv51_cs_data = '0' and RD_N = '0' else 
			status_reg when vv51_cs_cmd = '0' and RD_N = '0' else	
			(others => '1');
	INT_N <= hw_int_n;

end RTL;

