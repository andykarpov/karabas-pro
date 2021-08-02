library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity overlay is
	port (
		CLK		: in std_logic;
		CLK2 		: in std_logic;
		RGB_I 	: in std_logic_vector(8 downto 0);
		RGB_O 	: out std_logic_vector(8 downto 0);
		DS80		: in std_logic;
		HCNT_I	: in std_logic_vector(9 downto 0);
		VCNT_I	: in std_logic_vector(8 downto 0);
		BLINK 	: in std_logic;
		
		OSD_OVERLAY 	: in std_logic := '0';
		OSD_COMMAND 	: in std_logic_vector(15 downto 0)
	);
end entity;

architecture rtl of overlay is

	 component rom_font2
    port (
        address : in std_logic_vector(10 downto 0);
        clock   : in std_logic;
        q       : out std_logic_vector(7 downto 0)
    );
    end component;

    component screen2
    port (
        data    	: in std_logic_vector(15 downto 0);
        rdaddress : in std_logic_vector(9 downto 0);
        rdclock  	: in std_logic;
        wraddress : in std_logic_vector(9 downto 0);
        wrclock   : in std_logic;
        wren      : in std_logic;
        q         : out std_logic_vector(15 downto 0)
    );
    end component;

    signal video_on : std_logic;

    signal char: std_logic_vector(7 downto 0);
    signal attr, last_attr, cur_attr: std_logic_vector(7 downto 0);

    signal char_x: std_logic_vector(2 downto 0);
    signal char_y: std_logic_vector(2 downto 0);

    signal rom_addr: std_logic_vector(10 downto 0);
    signal row_addr: std_logic_vector(2 downto 0);
    signal bit_addr: std_logic_vector(2 downto 0);
    signal font_word: std_logic_vector(7 downto 0);
    signal font_reg : std_logic_vector(7 downto 0);	 
    signal font_bit: std_logic;
    
    signal addr_read: std_logic_vector(9 downto 0);
    signal addr_write: std_logic_vector(9 downto 0);
    signal vram_di: std_logic_vector(15 downto 0);
    signal vram_do: std_logic_vector(15 downto 0);
    signal vram_wr: std_logic := '0';

    signal flash : std_logic;
    signal is_flash : std_logic;
    signal rgb_fg : std_logic_vector(8 downto 0);
    signal rgb_bg : std_logic_vector(8 downto 0);

    signal selector : std_logic_vector(3 downto 0);
	 signal last_osd_command : std_logic_vector(15 downto 0);
	 signal char_buf : std_logic_vector(7 downto 0);
	
begin

	 U_FONT: rom_font2
    port map (
        address => rom_addr,
        clock   => CLK2,
        q       => font_word
    );

    U_VRAM: screen2 
    port map (
        data    => vram_di,
        rdaddress => addr_read,
        rdclock   => CLK2,
        wraddress => addr_write,
        wrclock   => CLK,
        wren      => vram_wr,
        q         => vram_do
    );

	 video_on <= '1' when (OSD_OVERLAY = '1') else '0';
	 flash <= BLINK;

    char_x <= HCNT_I(2 downto 0); -- TODO: DS80
    char_y <= VCNT_I(2 downto 0);

    addr_read <= VCNT_I(7 downto 3) & HCNT_I(7 downto 3);
    char <= vram_do(15 downto 8); 
    cur_attr <= vram_do(7 downto 0); 
    rom_addr <= char & char_y;
    font_reg <= font_word;

    process(CLK, CLK2, bit_addr)
    begin
        if rising_edge(CLK) then
			   if (CLK2 = '1') then 
					if (bit_addr = "010") then
						 last_attr <= cur_attr;
					end if;
				end if;
        end if;
    end process;

    attr <= last_attr when bit_addr <= 1 else cur_attr;

    -- getting font pixel of the current char line
    bit_addr <= char_x(2 downto 0);
    font_bit <=
                font_reg(0) when bit_addr = "000" else 
                font_reg(7) when bit_addr = "001" else 
                font_reg(6) when bit_addr = "010" else 
                font_reg(5) when bit_addr = "011" else 
                font_reg(4) when bit_addr = "100" else 
                font_reg(3) when bit_addr = "101" else
                font_reg(2) when bit_addr = "110" else
                font_reg(1) when bit_addr = "111";

    -- rgb multiplexing
    is_flash <= '1' when attr(3 downto 0) = "0001" else '0';
    selector <= video_on & font_bit & flash & is_flash;
    rgb_fg <= (attr(7) and attr(4)) & attr(7) & attr(7) & (attr(6) and attr(4)) & attr(6) & attr(6) & (attr(5) and attr(4)) & attr(5) & attr(5);
    rgb_bg <= (attr(3) and attr(0)) & attr(3) & attr(3) & (attr(2) and attr(0)) & attr(2) & attr(2) & (attr(1) and attr(0)) & attr(1) & attr(1);
    RGB_O <= rgb_fg when (selector="1111" or selector="1001" or selector="1100" or selector="1110") else 
             rgb_bg when (selector="1011" or selector="1101" or selector="1000" or selector="1010") else 
             RGB_I;

		process(CLK, osd_command, last_osd_command)
		begin
			  if rising_edge(CLK) then
					 vram_wr <= '0';
					 if (osd_command /= last_osd_command) then 
						last_osd_command <= osd_command;
						case osd_command(15 downto 8) is 
						  when X"10"  => vram_wr <= '0'; addr_write(4 downto 0) <= osd_command(4 downto 0); -- x: 0...32
						  when X"11" => vram_wr <= '0'; addr_write(9 downto 5) <= osd_command(4 downto 0); -- y: 0...32
						  when X"12"  => vram_wr <= '0'; char_buf <= osd_command(7 downto 0); -- char
						  when X"13"  => vram_wr <= '1'; vram_di <= char_buf & osd_command(7 downto 0); -- attrs
						  when others => vram_wr <= '0';
						end case;
					 end if;
			  end if;
		end process;

end architecture;
