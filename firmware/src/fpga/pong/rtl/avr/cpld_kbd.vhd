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
	 
	 CFG			: in std_logic_vector(7 downto 0) := "00000000";
	 	 
	 RESET		: out std_logic := '0';
	 SCANLINES  : out std_logic := '0';
	 
	 L_PADDLE   : out std_logic_vector(2 downto 0); -- up, down, start - Q,A,S
	 R_PADDLE 	: out std_logic_vector(2 downto 0) -- up, down, start - P,L,M

	);
    end cpld_kbd;
architecture RTL of cpld_kbd is

	 -- keyboard state
	 signal kb_data : std_logic_vector(40 downto 0) := (others => '0'); -- 40 keys + bit6
	 signal rst : std_logic := '0';
	 
	 -- joy state
	 signal joy : std_logic_vector(4 downto 0) := (others => '0');

	 -- spi
	 signal spi_do_valid : std_logic := '0';
	 signal spi_do : std_logic_vector(15 downto 0);
	 
begin

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
        di_i           => x"FD" & CFG, -- AVR init command
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
				-- keyboard matrix
				when X"01" => kb_data(7 downto 0) <= spi_do (7 downto 0);
				when X"02" => kb_data(15 downto 8) <= spi_do (7 downto 0);
				when X"03" => kb_data(23 downto 16) <= spi_do (7 downto 0);
				when X"04" => kb_data(31 downto 24) <= spi_do (7 downto 0);
				when X"05" => kb_data(39 downto 32) <= spi_do (7 downto 0);
				when X"06" => kb_data(40) <= spi_do (0); 
								  rst <= spi_do(1);			-- RESET hotkey
								  SCANLINES <= spi_do(2);  -- TURBO hotkey
				-- joy data
				when X"0D" => joy(4 downto 0) <= spi_do(5 downto 2) & spi_do(0); -- right, left,  down, up, fire2, fire
				
				when others => null;
			end case;	
		end if;
	end if;
end process;		  
		  
--    
process( kb_data)
begin
	RESET <= rst or kb_data(7); -- ctrl+alt+del or space
	L_PADDLE <= kb_data(2) & kb_data(1) & kb_data(9); -- Q,A,S
	R_PADDLE <= (kb_data(5) or joy(2)) & (kb_data(14) or joy(1)) & (kb_data(23) or joy(0)); --P,L,M or joy up, joy down, joy fire
end process;

end RTL;

