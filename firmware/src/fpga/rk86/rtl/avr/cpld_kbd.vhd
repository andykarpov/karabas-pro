library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity cpld_kbd is
	port
	(
	 CLK			 : in std_logic;
	 N_RESET 	 : in std_logic := '1';

    AVR_MOSI    : in std_logic;
    AVR_MISO    : out std_logic;
    AVR_SCK     : in std_logic;
	 AVR_SS 		 : in std_logic;
	 	 
	 CFG 			 : in std_logic_vector(7 downto 0) := "00000000";
		 
	 RESET		 : out std_logic := '0';
	 
	 I_ADDR		 : in std_logic_vector(7 downto 0);
	 O_DATA		 : out std_logic_vector(7 downto 0);
	 O_SHIFT		 : out std_logic_vector(2 downto 0)
	 
	);
    end cpld_kbd;
architecture RTL of cpld_kbd is

	 -- keyboard state
	 signal rst : std_logic := '0';

	 type key_matrix is array (7 downto 0) of std_logic_vector(7 downto 0);	-- multi-dimensional array of key matrix 
	 signal keymatrix	: key_matrix;
	 signal shifts		: std_logic_vector(2 downto 0);
	 signal row0, row1, row2, row3, row4, row5, row6, row7 : std_logic_vector(7 downto 0);
	 
	 -- temp scancode rx buffers
	 signal is_up : std_logic := '1';
	 signal rxsc : std_logic_vector(7 downto 0);
	 
	 -- scancode
	 signal scancode : std_logic_vector(15 downto 0);
	 signal scancode_ready : std_logic := '0';

	 -- spi
	 signal spi_do_valid : std_logic := '0';
	 signal spi_do : std_logic_vector(15 downto 0);
	 
begin

		-- Output addressed row to ULA
	row0	<= keymatrix(0) when I_ADDR(0) = '0' else (others => '1');
	row1	<= keymatrix(1) when I_ADDR(1) = '0' else (others => '1');
	row2	<= keymatrix(2) when I_ADDR(2) = '0' else (others => '1');
	row3	<= keymatrix(3) when I_ADDR(3) = '0' else (others => '1');
	row4	<= keymatrix(4) when I_ADDR(4) = '0' else (others => '1');
	row5	<= keymatrix(5) when I_ADDR(5) = '0' else (others => '1');
	row6	<= keymatrix(6) when I_ADDR(6) = '0' else (others => '1');
	row7	<= keymatrix(7) when I_ADDR(7) = '0' else (others => '1');

	-- Keyboard
	O_SHIFT 	<= shifts;
	RESET 	<= rst;
	O_DATA 		<= row0 and row1 and row2 and row3 and row4 and row5 and row6 and row7;

	U_SPI: entity work.spi_slave
    generic map(
        N              => 16 -- 2 bytes (cmd + data)       
    )
    port map(
        clk_i          => CLK,
        spi_sck_i      => AVR_SCK,
        spi_ssel_i     => AVR_SS,
        spi_mosi_i     => AVR_MOSI,
        spi_miso_o     => AVR_MISO,

        di_req_o       => open,
        di_i           => x"FD" & CFG, -- INIT
        wren_i         => '1',
        do_valid_o     => spi_do_valid,
        do_o           => spi_do,

        do_transfer_o  => open,
        wren_o         => open,
        wren_ack_o     => open,
        rx_bit_reg_o   => open,
        state_dbg_o    => open
   );
		  
	process (CLK, spi_do_valid, spi_do)
	begin
		if (rising_edge(CLK)) then

			if spi_do_valid = '1' then
				case spi_do(15 downto 8) is 
					-- keyboard scancode and button state + reset signal
					when X"06" => 
									  scancode_ready <= '0';
									  -- bit6 <= spi_do(0) 
									  rst <= spi_do(1);
									  --trb <= spi_do(2);
									  -- magik <= spi_do(3)
									  is_up <= spi_do(4);
					when X"07" => rxsc(7 downto 0) <= spi_do(7 downto 0);
					when X"08" => 
										SCANCODE_READY <= '1';
										SCANCODE <= "0000000" & spi_do(0) & rxsc(7 downto 0);
					when others => null;
				end case;	
			end if;
		end if;
	end process;		  

	process (N_RESET, CLK, scancode, scancode_ready)
	begin
		if N_RESET = '0' then
			keymatrix(0) <= (others => '1');
			keymatrix(1) <= (others => '1');
			keymatrix(2) <= (others => '1');
			keymatrix(3) <= (others => '1');
			keymatrix(4) <= (others => '1');
			keymatrix(5) <= (others => '1');
			keymatrix(6) <= (others => '1');
			keymatrix(7) <= (others => '1');
			shifts <= (others => '1');
		elsif CLK'event and CLK = '1' and scancode_ready = '1' then

			case scancode(15 downto 0) is
				when X"001A" =>	keymatrix(7)(2) <= is_up;	-- Z
				when X"0022" =>	keymatrix(7)(0) <= is_up;	-- X
				when X"0021" =>	keymatrix(4)(3) <= is_up;	-- C
				when X"002A" =>	keymatrix(6)(6) <= is_up;	-- V

				when X"001C" =>	keymatrix(4)(1) <= is_up;	-- A
				when X"001B" =>	keymatrix(6)(3) <= is_up;	-- S
				when X"0023" =>	keymatrix(4)(4) <= is_up;	-- D
				when X"002B" =>	keymatrix(4)(6) <= is_up;	-- F
				when X"0034" =>	keymatrix(4)(7) <= is_up;	-- G

				when X"0015" =>	keymatrix(6)(1) <= is_up;	-- Q
				when X"001D" =>	keymatrix(6)(7) <= is_up;	-- W
				when X"0024" =>	keymatrix(4)(5) <= is_up;	-- E
				when X"002D" =>	keymatrix(6)(2) <= is_up;	-- R
				when X"002C" =>	keymatrix(6)(4) <= is_up;	-- T

				when X"0016" =>	keymatrix(2)(1) <= is_up;	-- 1
				when X"001E" =>	keymatrix(2)(2) <= is_up;	-- 2
				when X"0026" =>	keymatrix(2)(3) <= is_up;	-- 3
				when X"0025" =>	keymatrix(2)(4) <= is_up;	-- 4
				when X"002E" =>	keymatrix(2)(5) <= is_up;	-- 5

				when X"0045" =>	keymatrix(2)(0) <= is_up;	-- 0
				when X"0046" =>	keymatrix(3)(1) <= is_up;	-- 9
				when X"003E" =>	keymatrix(3)(0) <= is_up;	-- 8
				when X"003D" =>	keymatrix(2)(7) <= is_up;	-- 7
				when X"0036" =>	keymatrix(2)(6) <= is_up;	-- 6

				when X"004D" =>	keymatrix(6)(0) <= is_up;	-- P
				when X"0044" =>	keymatrix(5)(7) <= is_up;	-- O
				when X"0043" =>	keymatrix(5)(1) <= is_up;	-- I
				when X"003C" =>	keymatrix(6)(5) <= is_up;	-- U
				when X"0035" =>	keymatrix(7)(1) <= is_up;	-- Y

				when X"005A" =>	keymatrix(1)(2) <= is_up;	-- ENTER (ВК)
				when X"004B" =>	keymatrix(5)(4) <= is_up;	-- L
				when X"0042" =>	keymatrix(5)(3) <= is_up;	-- K
				when X"003B" =>	keymatrix(5)(2) <= is_up;	-- J
				when X"0033" =>	keymatrix(5)(0) <= is_up;	-- H

				when X"0029" =>	keymatrix(7)(7) <= is_up;	-- SPACE
				when X"003A" =>	keymatrix(5)(5) <= is_up;	-- M
				when X"0031" =>	keymatrix(5)(6) <= is_up;	-- N
				when X"0032" =>	keymatrix(4)(2) <= is_up;	-- B

				-- Cursor keys
				when X"016B" =>	keymatrix(1)(4) <= is_up;	-- Left
				when X"0172" =>	keymatrix(1)(7) <= is_up;	-- Down
				when X"0175" =>	keymatrix(1)(5) <= is_up;	-- Up
				when X"0174" =>	keymatrix(1)(6) <= is_up;	-- Right

				-- Other special keys sent to the ULA as key combinations
				when X"0066" =>	keymatrix(1)(3) <= is_up;	-- Backspace (ЗБ)
				--when X"39" =>	keymatrix(7)(2) <= is_up; -- Caps lock
				when X"000D" =>	keymatrix(1)(0) <= is_up;	-- Tab (ТАБ)
				when X"0049" =>	keymatrix(3)(6) <= is_up;	-- .
				when X"004E" =>	keymatrix(3)(5) <= is_up;	-- -
				when X"000E" =>	keymatrix(7)(6) <= is_up;	-- `
				when X"0041" =>	keymatrix(3)(4) <= is_up;	-- ,
--								when X"33" =>	keymatrix(5)(1) <= '0';	-- ;
--								when X"34" =>	keymatrix(5)(0) <= '0';	-- "
--								when X"31" =>	keymatrix(0)(1) <= '0';	-- :
				when X"0055" =>	keymatrix(3)(2) <= is_up;	-- =
--								when X"2f" =>	keymatrix(4)(2) <= '0';	-- (
--								when X"30" =>	keymatrix(4)(1) <= '0';	-- )
--								when X"38" =>	keymatrix(0)(3) <= '0';	-- ?
						
				-- Num keys
				--when X"5e" =>	keymatrix(1)(6) <= is_up;	-- [6] (Right)
				--when X"5c" =>	keymatrix(1)(4) <= is_up;	-- [4] (Left)
				--when X"5a" =>	keymatrix(1)(7) <= is_up;	-- [2] (Down)
				--when X"60" =>	keymatrix(1)(5) <= is_up;	-- [8] (Up)
--								when X"62" =>	keymatrix(7)(4) <= '0';	-- [0]

				-- Fx keys
				when X"0005" =>	keymatrix(0)(3) <= is_up;	-- F1
				when X"0006" =>	keymatrix(0)(4) <= is_up;	-- F2
				when X"0004" =>	keymatrix(0)(5) <= is_up;	-- F3
				when X"000C" =>	keymatrix(0)(6) <= is_up;	-- F4
				when X"0003" =>	keymatrix(0)(7) <= is_up;	-- F5
--								when X"3f" =>	keymatrix(7)(1) <= '0';	-- F6
--								when X"40" =>	keymatrix(7)(1) <= '0';	-- F7
--								when X"41" =>	keymatrix(7)(1) <= '0';	-- F8
--								when X"42" =>	keymatrix(7)(1) <= '0';	-- F9
--								when X"43" =>	keymatrix(7)(1) <= '0';	-- F10
--								when X"44" =>	keymatrix(7)(1) <= '0';	-- F11
				--when X"0007" =>	rst <= not is_up;		-- F12 (Reset)
 
				-- Soft keys
--								when X"46" =>	keymatrix(7)(2) <= '0';	-- PrtScr
				when X"007E" =>	keymatrix(1)(1) <= is_up;	-- Scroll Lock (ПС)
--								when X"48" =>	keymatrix(7)(4) <= '0';	-- Pause
--								when X"65" =>	keymatrix(7)(1) <= '0';	-- WinMenu
				when X"0076" =>	keymatrix(0)(2) <= is_up;	-- Esc (АР2)
--								when X"49" =>	keymatrix(7)(1) <= '0';	-- Insert
				when X"016C" =>	keymatrix(0)(0) <= is_up;	-- Home (Курсор в начало экрана)
--								when X"4b" =>	keymatrix(7)(1) <= '0';	-- Page Up
				when X"0171" =>	keymatrix(0)(1) <= is_up;	-- Delete (СТР)
--								when X"4d" =>	keymatrix(7)(1) <= '0';	-- End
--								when X"4e" =>	keymatrix(7)(1) <= '0';	-- Page Down

				when X"0012" => shifts(2) <= is_up; -- left shift 
				when X"0059" => shifts(2) <= is_up; -- right shift
				when X"0014" => shifts(1) <= is_up; -- left ctrl
				when X"0114" => shifts(1) <= is_up; -- rigt ctrl 
				when X"0011" => shifts(0) <= is_up; -- left alt 
				when X"0111" => shifts(0) <= is_up; -- right alt

				when others => null;
			end case;
		end if;
	end process;

end RTL;

