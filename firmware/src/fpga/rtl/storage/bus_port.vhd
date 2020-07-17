library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity bus_port is
	port (

	-- global clocks
	CLK : in std_logic;
	CLK2: in std_logic;
	RESET : in std_logic;
	 
	-- physical interface with CPLD
	SD : inout std_logic_vector(15 downto 0);
	SA : out std_logic_vector(1 downto 0);
	SDIR : out std_logic;
	CPLD_CLK : out std_logic;
	CPLD_CLK2 : out std_logic;
	NRESET : out std_logic;

	-- zx bus signals to rx/tx from/to the CPLD controller
	BUS_A : in std_logic_vector(15 downto 0);
	BUS_DI : in std_logic_vector(7 downto 0);
	BUS_DO : out std_logic_vector(7 downto 0);
	OE_N : out std_logic;
	BUS_RD_N : in std_logic;
	BUS_WR_N : in std_logic;
	BUS_MREQ_N : in std_logic;
	BUS_IORQ_N : in std_logic;
	BUS_M1_N : in std_logic;
	BUS_CPM : in std_logic;
	BUS_DOS : in std_logic;
	BUS_ROM14 : in std_logic
);
    end bus_port;
architecture RTL of bus_port is

type machine IS(rx1, rx2, tx1, tx2); --state machine datatype
signal state 			: machine := rx1; 	--current state

begin
	
	CPLD_CLK <= CLK;
	CPLD_CLK2 <= CLK2;
	NRESET <= not reset;

	process (CLK)
	begin
		if CLK'event and CLK='0' then
			case state is
				when rx1 => -- set rx mode, address
					SDIR <= '1'; SA <= "00";
					SD <= (others => 'Z');
					state <= rx2;
				when rx2 => 
					BUS_DO <= SD(15 downto 8); -- receiving data from slave
					OE_N <= SD(7);
					state <= tx1;
				when tx1 =>
					SDIR <= '0'; SA <= "00"; -- tx cpu adress
					SD <= BUS_A;
					state <= tx2;
				when tx2 => 
					SDIR <= '0'; SA <= "01"; -- tx cpu signals
					SD(15 downto 8) <= BUS_DI;
					SD(7) <= BUS_RD_N;
					SD(6) <= BUS_WR_N;
					SD(5) <= BUS_MREQ_N;
					SD(4) <= BUS_IORQ_N;
					SD(3) <= BUS_M1_N;
					SD(2) <=	BUS_CPM;
					SD(1) <= BUS_DOS;
					SD(0) <= BUS_ROM14;
					state <= rx1;
			end case;
		end if;
	end process;

end RTL;

