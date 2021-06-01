-------------------------------------------------------------------------------
-- AY3-8910 UART on portA
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity ay_uart is
   port(
      CLK_I   	 : in  std_logic;                   	-- System Clock
      EN_I   	 : in  std_logic;                    	-- PSG Clock
      RESET_I 	 : in  std_logic;                    	-- Chip RESET_I (set all Registers to '0', active hi)
      BDIR_I  	 : in  std_logic;                    	-- Bus Direction (0 - read , 1 - write)
      CS_I    	 : in  std_logic;                    	-- Chip Select (active hi)
      BC_I    	 : in  std_logic;                    	-- Bus control

      DATA_I    : in  std_logic_vector(7 downto 0); 	-- Data In
      DATA_O    : out std_logic_vector(7 downto 0); 	-- Data Out
		OE_N 		 : out std_logic := '1';

		UART_TX 	 : out std_logic;
		UART_RX 	 : in  std_logic;
		UART_RTS  : out std_logic
   );
end ay_uart;
 
architecture rtl of ay_uart is
 
-- AY Registers
   signal pa     	: std_logic_vector (3 downto 2);	-- I/O Port A Data Store (R16)
	signal pa_dir 	: std_logic; 							-- bit 6 from mixer register R7
   signal address : std_logic_vector (3 downto 0);	-- Selected Register Address
 
begin
 
process (RESET_I , CLK_I)
begin
   if RESET_I = '1' then
      address   <= "0000";
      pa    	 <= (others => '0');
		pa_dir 	 <= '0';
   elsif rising_edge(CLK_I) then
      if CS_I = '1' and BDIR_I = '1' then
         if BC_I = '1' then
            address <= DATA_I (3 downto 0);				-- Latch Address
         else
            case Address is									-- Latch Registers
               when x"E" => pa(3 downto 2)      <= DATA_I(3 downto 2);
					when x"7" => pa_dir 					<= DATA_I(6);
               when others => null;
            end case;
         end if;
      end if;
   end if;
end process;

-- Port A out
UART_TX <= pa(3) when pa_dir = '1' else '1';
UART_RTS <= pa(2) when pa_dir = '1' else '1';

-- Read from AY
OE_N <= '0' when address = x"E" and CS_I = '1' and BDIR_I = '0' and BC_I = '1' else '1';
DATA_O	<=	UART_RX & "000" & pa(3 downto 2) & "00";
 
end rtl;
