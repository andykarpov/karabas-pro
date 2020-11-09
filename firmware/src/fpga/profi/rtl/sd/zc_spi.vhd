library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity zc_spi is
port(
--INPUTS
DI      : in std_logic_vector(7 downto 0);
CLC     : in std_logic;
START   : in std_logic;
MISO    : in std_logic;
WR_EN   : in std_logic;
--OUTPUTS
DO      : out std_logic_vector(7 downto 0);
SCK     : out std_logic;
MOSI    : out std_logic
);
end;

architecture spi_rtl of zc_spi is

signal COUNTER      : std_logic_vector(3 downto 0) := "0000";
signal SHIFT_IN     : std_logic_vector(7 downto 0) := "00000000";
signal SHIFT_OUT    : std_logic_vector(7 downto 0) := "11111111";
signal COUNTER_EN   : std_logic;
signal START_SYNC   : std_logic;

begin        
        SCK             <= CLC and not COUNTER(3);
        DO              <= SHIFT_IN;
        MOSI            <= SHIFT_OUT(7);
        COUNTER_EN      <= not COUNTER(3) or COUNTER(2) or COUNTER(1) or COUNTER(0);

        process(CLC)
        begin
            if CLC'event and CLC = '1' then
                START_SYNC <= START;
            end if;
        end process;
        
        process(CLC,COUNTER(3))
        begin
            if CLC'event and CLC = '1' then
                if COUNTER(3) = '0' then
                    SHIFT_IN <= SHIFT_IN(6 downto 0)&MISO;
                end if;
            end if;
        end process;
        
        process(CLC,WR_EN,COUNTER(3))
        begin
            if CLC'event and CLC = '0' then
                if WR_EN = '1' then
                    SHIFT_OUT <= DI;
                else
                    if COUNTER(3) = '0' then
                        SHIFT_OUT(7 downto 0) <= SHIFT_OUT(6 downto 0)&'1';
                    end if;
                end if;
            end if;
        end process;

        process(CLC,START_SYNC,COUNTER_EN)
        begin
            if START_SYNC = '1' then
                COUNTER <= "1110";
            else
                if CLC'event and CLC = '0' then
                    if COUNTER_EN = '1' then
                        COUNTER <= COUNTER+"0001";
                    end if;
                end if;
            end if;
        end process;

end spi_rtl;