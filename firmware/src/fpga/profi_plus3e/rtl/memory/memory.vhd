-------------------------------------------------------------------------------
-- Memory controller
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity memory is
generic (
		enable_bus_n_romcs : boolean := true
);
port (
	CLK2X 		: in std_logic;
	CLKX	   	: in std_logic;
	CLK_CPU 		: in std_logic;

	A           : in std_logic_vector(15 downto 0); -- address bus
	D 				: in std_logic_vector(7 downto 0);
	N_MREQ		: in std_logic;
	N_IORQ 		: in std_logic;
	N_WR 			: in std_logic;
	N_RD 			: in std_logic;
	N_M1 			: in std_logic;
	
	loader_act 	: in std_logic := '0';
	loader_ram_a: in std_logic_vector(20 downto 0);
	loader_ram_do: in std_logic_vector(7 downto 0);
	loader_ram_wr: in std_logic := '0';
	
	DO 			: out std_logic_vector(7 downto 0);
	N_OE 			: out std_logic;
	
	MA 			: out std_logic_vector(20 downto 0);
	MD 			: inout std_logic_vector(7 downto 0);
	N_MRD 		: out std_logic;
	N_MWR 		: out std_logic;
	
	RAM_BANK		: in std_logic_vector(2 downto 0);
	RAM_EXT 		: in std_logic_vector(2 downto 0);
	P3_MEM_MODE	: in std_logic := '0'; -- 0 - Normal, 1 - Special
	P3_RAM_MODE	: in std_logic_vector(1 downto 0) := "00"; -- Special 4 modes
	
	VA				: in std_logic_vector(13 downto 0);
	VID_PAGE 	: in std_logic := '0';
	DS80			: in std_logic := '0';
	CPM 			: in std_logic := '0';
	SCO			: in std_logic := '0';
	SCR 			: in std_logic := '0';
	WOROM 		: in std_logic := '0';
	
	VBUS_MODE_O : out std_logic;
	VID_RD_O : out std_logic;
	
	ROM_BANK : in std_logic_vector(1 downto 0) := "00";
	EXT_ROM_BANK : in std_logic_vector(1 downto 0) := "00"
);
end memory;

architecture RTL of memory is

	signal buf_md		: std_logic_vector(7 downto 0) := "11111111";
	signal is_buf_wr	: std_logic := '0';	
	
	signal is_rom : std_logic := '0';
	signal is_ram : std_logic := '0';
	
	signal rom_page : std_logic_vector(1 downto 0) := "00";
	signal ram_page : std_logic_vector(6 downto 0) := "0000000";

	signal vbus_req	: std_logic := '1';
	signal vbus_mode	: std_logic := '1';	
	signal vbus_rdy	: std_logic := '1';
	signal vbus_ack 	: std_logic := '1';
	signal vid_rd : std_logic;
	
	signal mux : std_logic_vector(1 downto 0);

begin

	is_rom <= '1' when N_MREQ = '0' and A(15 downto 14)  = "00" and WOROM = '0' and P3_MEM_MODE = '0' else '0';
	is_ram <= '1' when N_MREQ = '0' and is_rom = '0' else '0';
	
	-- 00 - bank 0, CPM
	-- 01 - bank 1, TRDOS
	-- 10 - bank 2, Basic-128
	-- 11 - bank 3, Basic-48
	rom_page <= ROM_BANK;
		
	vbus_req <= '0' when ( N_MREQ = '0' or N_IORQ = '0' ) and ( N_WR = '0' or N_RD = '0' ) else '1';
	vbus_rdy <= '0' when (CLKX = '0' or CLK_CPU = '0')  else '1';

	VBUS_MODE_O <= vbus_mode;
	VID_RD_O <= vid_rd;
	
	N_MRD <= '1' when loader_act = '1' else 
				'0' when (is_rom = '1' and N_RD = '0') or
							(vbus_mode = '1' and vbus_rdy = '0') or 
							(vbus_mode = '0' and N_RD = '0' and N_MREQ = '0') 
				else '1';

	N_MWR <= not loader_ram_wr when loader_act = '1' else 
				'0' when vbus_mode = '0' and is_ram = '1' and N_WR = '0' and CLK_CPU = '0' 
				else '1';

	is_buf_wr <= '1' when vbus_mode = '0' and CLK_CPU = '0' else '0';
	
	DO <= buf_md;
	
	N_OE <= '0' when (is_ram = '1' or is_rom = '1') and N_RD = '0' else '1';
		
	mux <= A(15 downto 14);
		
	process (mux, RAM_EXT, RAM_BANK, SCR, SCO, P3_MEM_MODE, P3_RAM_MODE)
	begin
		case mux is
			when "00" => if P3_MEM_MODE='1' then
								case P3_RAM_MODE is
									when "00" => ram_page <= "0000000";
									when "01" => ram_page <= "0000100";
									when "10" => ram_page <= "0000100";
									when "11" => ram_page <= "0000100";
								end case;
							 else
								ram_page <= "0000000";                 -- Seg0 ROM 0000-3FFF or Seg0 RAM 0000-3FFF	
							 end if;
			when "01" => if P3_MEM_MODE='1' then
								case P3_RAM_MODE is
									when "00" => ram_page <= "0000001";
									when "01" => ram_page <= "0000101";
									when "10" => ram_page <= "0000101";
									when "11" => ram_page <= "0000111";
								end case;
							 elsif SCO='0' then 
								ram_page <= "0000101";
							 else 
								ram_page <= "0" & RAM_EXT(2 downto 0) & RAM_BANK(2 downto 0); 
							 end if;	                               -- Seg1 RAM 4000-7FFF	
			when "10" => if P3_MEM_MODE='1' then
								case P3_RAM_MODE is
									when "00" => ram_page <= "0000010";
									when "01" => ram_page <= "0000110";
									when "10" => ram_page <= "0000110";
									when "11" => ram_page <= "0000110";
								end case;
							 elsif SCR='0' then 
								ram_page <= "0000010"; 	
							 else 
								ram_page <= "0000110"; 
							 end if;                                -- Seg2 RAM 8000-BFFF
			when "11" => if P3_MEM_MODE='1' then
								case P3_RAM_MODE is
									when "00" => ram_page <= "0000011";
									when "01" => ram_page <= "0000111";
									when "10" => ram_page <= "0000011";
									when "11" => ram_page <= "0000011";
								end case;
							 elsif SCO='0' then 
								ram_page <= "0" & RAM_EXT(2 downto 0) & RAM_BANK(2 downto 0);	
							 else 
								ram_page <= "0000111";               -- Seg3 RAM C000-FFFF	
							 end if;
			when others => null;
		end case;
	end process;
		
	MA(13 downto 0) <= 
		loader_ram_a(13 downto 0) when loader_act = '1' else -- loader ram
		A(13 downto 0) when vbus_mode = '0' else -- spectrum ram 
		VA; -- video ram (read by video controller)

	MA(20 downto 14) <= 
		loader_ram_a(20 downto 14) when loader_act = '1' else -- loader ram
		"100" & EXT_ROM_BANK(1 downto 0) & rom_page(1 downto 0) when is_rom = '1' and vbus_mode = '0' else -- rom from sram high bank 
		ram_page(6 downto 0) when vbus_mode = '0' else 
		"00001" & VID_PAGE & '1' when vbus_mode = '1' and DS80 = '0' else -- spectrum screen
		"00001" & VID_PAGE & '0' when vbus_mode = '1' and DS80 = '1' and vid_rd = '0' else -- profi bitmap 
		"01110" & VID_PAGE & '0' when vbus_mode = '1' and DS80 = '1' and vid_rd = '1' else -- profi attributes
		"0000000";
	
	MD(7 downto 0) <= 
		loader_ram_do when loader_act = '1' else -- loader DO
		D(7 downto 0) when vbus_mode = '0' and ((is_ram = '1' or (N_IORQ = '0' and N_M1 = '1')) and N_WR = '0') else 
		(others => 'Z');
		
	-- fill memory buf
	process(is_buf_wr)
	begin 
		if (is_buf_wr'event and is_buf_wr = '0') then  -- high to low transition to lattch the MD into BUF
			buf_md(7 downto 0) <= MD(7 downto 0);
		end if;
	end process;	
	
	process( CLK2X, CLKX, vbus_mode, vbus_req, vbus_ack )
	begin
		-- lower edge of 14 mhz clock
		if CLK2X'event and CLK2X = '1' then 
			if (CLKX = '0') then
				if vbus_req = '0' and vbus_ack = '1' then
					vbus_mode <= '0';
				else
					vbus_mode <= '1';
					vid_rd <= not vid_rd;
				end if;	
				vbus_ack <= vbus_req;
			end if;		
		end if;		
	end process;
			
end RTL;

