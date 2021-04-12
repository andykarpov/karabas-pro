-- ****
-- T80a wrapper
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.T80_Pack.all;

entity T80aw is
	port(
		RESET_n         : in  std_logic;
		CLK_n           : in  std_logic;
		ENA             : in  std_logic;
		WAIT_n          : in  std_logic;
		INT_n           : in  std_logic;
		NMI_n           : in  std_logic;
		BUSRQ_n         : in  std_logic;
		M1_n            : out std_logic;
		MREQ_n          : buffer std_logic;
		IORQ_n          : buffer std_logic;
		RD_n            : buffer std_logic;
		WR_n            : buffer std_logic;
		RFSH_n          : out std_logic;
		HALT_n          : out std_logic;
		BUSAK_n         : out std_logic;
		A               : out std_logic_vector(15 downto 0);
		DI              : in  std_logic_vector(7 downto 0);
		DO              : out std_logic_vector(7 downto 0)
	);
end T80aw;

architecture rtl of T80aw is

signal d : std_logic_vector(7 downto 0);

begin

	u0 : entity work.T80a
		port map(
			RESET_n    => RESET_n,
			CLK_n      => not ENA,
			WAIT_n     => Wait_n,
			INT_n      => INT_n,
			NMI_n      => NMI_n,
			BUSRQ_n    => BUSRQ_n,
			M1_n       => M1_n,
            MREQ_n     => MREQ_n,
            IORQ_n     => IORQ_n,
            RD_n       => RD_n,
            WR_n       => WR_n,
			RFSH_n     => RFSH_n,
			HALT_n     => HALT_n,
			BUSAK_n    => BUSAK_n,
			A          => A,
			D          => d,

            SavePC     => open,
            SaveINT    => open,
            RestorePC  => (others => '0'),
            RestoreInt => (others => '0'),
            RestorePC_n => '1'
    );

    DO <= d;
    d <= DI when WR_n = '1' and (MREQ_n = '0' or IORQ_n = '0') else 
        "ZZZZZZZZ" when WR_n = '0' and (MREQ_n = '0' or IORQ_n = '0') else 
        "11111111";

end;
