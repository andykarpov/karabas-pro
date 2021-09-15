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
		PAPER_I  : in std_logic;
		BLINK 	: in std_logic;
		
		OSD_OVERLAY 	: in std_logic := '0'; -- full overlay osd
		OSD_POPUP 		: in std_logic := '0'; -- popup osd
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

    signal attr, attr2: std_logic_vector(7 downto 0);

    signal char_x: std_logic_vector(2 downto 0);
    signal char_y: std_logic_vector(2 downto 0);

    signal rom_addr: std_logic_vector(10 downto 0);
    signal row_addr: std_logic_vector(2 downto 0);
    signal bit_addr: std_logic_vector(2 downto 0);
    signal font_word: std_logic_vector(7 downto 0);
    signal font_reg : std_logic_vector(7 downto 0);	 
    signal pixel: std_logic;
    
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
	 signal paper : std_logic := '0';
	 signal paper2 : std_logic := '0';
	 
	 signal hcnt : std_logic_vector(9 downto 0) := (others => '0');
	 signal vcnt : std_logic_vector(8 downto 0) := (others => '0');
	
begin

	-- знакогенератор
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

	flash <= BLINK;
	hcnt <= '0' & hcnt_i(9 downto 1) when DS80='1' else hcnt_i;
	vcnt <= vcnt_i;
	 
    char_x <= hcnt(3 downto 1) when OSD_POPUP = '1' else hcnt(2 downto 0);
    char_y <= vcnt(3 downto 1) when OSD_POPUP = '1' else VCNT(2 downto 0);
	 paper2 <= '1' when hcnt >= 0 and hcnt < 256 and vcnt >= 0 and vcnt < 192 else '0'; 
	 paper <= '1' when hcnt >= 8 and hcnt < 264 and vcnt >= 0 and vcnt < 192 else '0'; -- активная зона со сдвигом на одно знакоместо
    video_on <= '1' when (OSD_OVERLAY = '1' or OSD_POPUP = '1') else '0';

	 -- чтение символа из видеопамяти и строчки знакоместа из шрифта
	 -- задержка на одно знакоместо
	 process (CLK, CLK2, vram_do)
	 begin
		if (rising_edge(CLK)) then 
			if (CLK2 = '0') then 
			
				if (OSD_POPUP = '1') then 
					case (hcnt(3 downto 0)) is
						when "1110" =>
							-- задаем адрес для чтения char и attr из видео памяти
							if (paper2 = '1') then
									addr_read <= VCNT(8 downto 4) & HCNT(8 downto 4);
							end if;
						when "1111" => 
							-- задаем адрес знакоместа из шрифта для чтения
							rom_addr <= vram_do(15 downto 8) & char_y;
							attr2 <= vram_do(7 downto 0);
						when "0000" => 
							-- назначаем attr для нового знакоместа 
							attr <= attr2;
							when others => null;						
					end case;
				else 
					case (char_x) is
						when "110" =>
							-- задаем адрес для чтения char и attr из видео памяти
							if (paper2 = '1') then
								addr_read <= VCNT(7 downto 3) & HCNT(7 downto 3);
							end if;
						when "111" => 
							-- задаем адрес знакоместа из шрифта для чтения
							rom_addr <= vram_do(15 downto 8) & char_y;
							attr2 <= vram_do(7 downto 0);
						when "000" => 
							-- назначаем attr для нового знакоместа 
							attr <= attr2;
							when others => null;						
					end case;
				end if;
			end if;
		end if;
	 end process;
	 
	 -- читаем строку знакоместа 
	 font_reg <= font_word;	 

    -- получение пикселя из строчки знакоместа шрифта
    bit_addr <= char_x(2 downto 0);
    pixel <= 
                font_reg(7) when bit_addr = "000" else 
                font_reg(6) when bit_addr = "001" else 
                font_reg(5) when bit_addr = "010" else 
                font_reg(4) when bit_addr = "011" else 
                font_reg(3) when bit_addr = "100" else 
                font_reg(2) when bit_addr = "101" else
                font_reg(1) when bit_addr = "110" else
                font_reg(0) when bit_addr = "111";

    -- формирование RGB
    is_flash <= '1' when attr(3 downto 0) = "0001" else '0';
    selector <= video_on & pixel & flash & is_flash;
    rgb_fg <= (attr(7) and attr(4)) & attr(7) & attr(7) & (attr(6) and attr(4)) & attr(6) & attr(6) & (attr(5) and attr(4)) & attr(5) & attr(5);
    rgb_bg <= (attr(3) and attr(0)) & attr(3) & attr(3) & (attr(2) and attr(0)) & attr(2) & attr(2) & (attr(1) and attr(0)) & attr(1) & attr(1);
    RGB_O <= 
				rgb_fg when paper = '1' and (selector="1111" or selector="1001" or selector="1100" or selector="1110") else 
            rgb_bg(8 downto 7) & RGB_I(8) & rgb_bg(5 downto 4) & RGB_I(5) & rgb_bg(2 downto 1) & RGB_I(2) when paper = '1' and (selector="1011" or selector="1101" or selector="1000" or selector="1010") else 
				"00" & RGB_I(8) & "00" & RGB_I(5) & "00" & RGB_I(2) when video_on = '1' else 
				RGB_I;

		-- заполнение видеопамяти AVR'кой по SPI
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
