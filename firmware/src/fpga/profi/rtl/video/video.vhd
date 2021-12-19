-------------------------------------------------------------------------------
-- VIDEO Controller
-------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity video is
	generic (
			enable_2port_vram  : boolean := true
	);
	port (
		CLK2X 	: in std_logic; -- 28 MHz
		CLK		: in std_logic; -- 14 MHz
		ENA		: in std_logic; -- 7 MHz 
		RESET 	: in std_logic := '0';

		BORDER	: in std_logic_vector(7 downto 0);	-- bordr color (port #xxFE)
		DI			: in std_logic_vector(7 downto 0);	-- video data from memory
		TURBO 	: in std_logic_vector := "00"; -- 01 = turbo 2x mode, 10 - turbo 4x mode, 11 - turbo 8x mode, 00 = normal mode
		INTA		: in std_logic := '0'; -- int request for turbo mode
		MODE60	: in std_logic := '0'; -- 
		INT		: out std_logic; -- int output
		ATTR_O	: out std_logic_vector(7 downto 0); -- attribute register output
		pFF_CS	: out std_logic; -- port FF select
		A			: out std_logic_vector(13 downto 0); -- video address

		VIDEO_R	: out std_logic_vector(2 downto 0);
		VIDEO_G	: out std_logic_vector(2 downto 0);
		VIDEO_B	: out std_logic_vector(2 downto 0);
		
		HSYNC		: out std_logic;
		VSYNC		: out std_logic;
		
		DS80		: in std_logic; -- 1 = Profi CP/M mode. 0 = standard mode
		CS7E 		: in std_logic := '0';
		BUS_A 	: in std_logic_vector(15 downto 8);
		BUS_D 	: in std_logic_vector(7 downto 0);
		BUS_WR_N : in std_logic;
		GX0 		: out std_logic;
		
		SCREEN_MODE : in std_logic_vector(1 downto 0);
		COUNT_BLOCK : out std_logic;
		
		HCNT : out std_logic_vector(9 downto 0);
		VCNT : out std_logic_vector(8 downto 0);
		ISPAPER : out std_logic;
		BLINK : out std_logic;
		
		-- sram vram
		VBUS_MODE : in std_logic := '0'; -- 1 = video bus, 2 = cpu bus
		VID_RD : in std_logic; -- 1 = read attribute, 0 = read pixel data

		-- 2port vram
		VID_RD2 	: out std_logic -- 1 = read attribute, 0 = read pixel
	);
end entity;

architecture rtl of video is

	signal rgb 	 		: std_logic_vector(2 downto 0);
	signal i 			: std_logic;
	signal o_rgb 		: std_logic_vector(8 downto 0);
	
	type t_palette is array (0 to 15) of std_logic_vector(8 downto 0);
	signal palette		: t_palette := (
		0 => "000000000", 1 => "000000100", 2 =>  "000100000", 3 =>  "000100100", 4 =>  "100000000", 5 =>  "100000100", 6 =>  "100100000", 7 =>  "100100100",
		8 => "000000000", 9 => "000000110", 10 => "000110000", 11 => "000110110", 12 => "110000000", 13 => "110000110", 14 => "110110000", 15 => "110110110"
	);
	signal palette_a 	: std_logic_vector(3 downto 0);
	signal palette_wr_a 	: std_logic_vector(3 downto 0);
	signal palette_wr_data 	: std_logic_vector(7 downto 0);
	signal palette_wr : std_logic := '0';
	signal palette_need_wr : std_logic := '0';
	signal palette_grb: std_logic_vector(8 downto 0);
	signal palette_grb_reg: std_logic_vector(8 downto 0);
	signal palette_prev : std_logic_vector(15 downto 8);
	
	-- profi videocontroller signals
	signal vid_a_profi : std_logic_vector(13 downto 0);
	signal int_profi : std_logic;
	signal rgb_profi : std_logic_vector(2 downto 0);
	signal i_profi : std_logic;
	signal hsync_profi : std_logic;
	signal vsync_profi : std_logic;
	signal blank_profi : std_logic;
	signal pFF_CS_profi : std_logic;
	signal attr_o_profi : std_logic_vector(7 downto 0);
	
	signal hcnt_profi : std_logic_vector(9 downto 0);
	signal vcnt_profi : std_logic_vector(8 downto 0);
	signal ispaper_profi : std_logic;
	signal vidrd_profi : std_logic;

	-- spectrum videocontroller signals
	signal vid_a_spec : std_logic_vector(13 downto 0);
	signal int_spec : std_logic;
	signal rgb_spec : std_logic_vector(2 downto 0);
	signal i_spec : std_logic;
	signal hsync_spec : std_logic;
	signal vsync_spec : std_logic;
	signal pFF_CS_spec : std_logic;
	signal attr_o_spec : std_logic_vector(7 downto 0);

	signal hcnt_spec : std_logic_vector(9 downto 0);
	signal vcnt_spec : std_logic_vector(8 downto 0);
	signal ispaper_spec : std_logic;

begin

	U_PENT: entity work.pentagon_video 
	generic map (
		enable_2port_vram => enable_2port_vram
	)	
	port map (
		CLK => CLK, -- 14
		CLK2x => CLK2x, -- 28
		ENA => ENA, -- 7
		BORDER => BORDER(2 downto 0),
		DI => DI,
		TURBO => TURBO,
		INTA => INTA,
		INT => int_spec,
		MODE60 => MODE60,
		pFF_CS => pFF_CS_spec,
		ATTR_O => attr_o_spec, 
		A => vid_a_spec,

		RGB => rgb_spec,
		I 	 => i_spec,
		
		HSYNC => hsync_spec,
		VSYNC => vsync_spec,

		HCNT => hcnt_spec,
		VCNT => vcnt_spec,
		ISPAPER => ispaper_spec,
		BLINK => BLINK,
		
		SCREEN_MODE => SCREEN_MODE,
		
		VBUS_MODE => VBUS_MODE,
		VID_RD => VID_RD,
		
		COUNT_BLOCK => COUNT_BLOCK
	);

	U_PROFI: entity work.profi_video 
	generic map (
		enable_2port_vram => enable_2port_vram
	)	
	port map (
		CLK => CLK, -- 14
		CLK2x => CLK2x, -- 28
		ENA => ENA, -- 7
		TURBO => TURBO,
		BORDER => BORDER(3 downto 0),
		DI => DI,
		INTA => INTA,
		INT => int_profi,
		MODE60 => MODE60,
		pFF_CS => pFF_CS_profi,
		ATTR_O => attr_o_profi,
		A => vid_a_profi,
		DS80 => DS80,

		RGB => rgb_profi,
		I 	 => i_profi,
		BLANK => blank_profi,
		
		HSYNC => hsync_profi,
		VSYNC => vsync_profi,

		HCNT => hcnt_profi,
		VCNT => vcnt_profi,
		ISPAPER => ispaper_profi,
		
		VBUS_MODE => VBUS_MODE,
		VID_RD => VID_RD,		
		
		VID_RD2 => vidrd_profi
	);

	A <= vid_a_profi when ds80 = '1' else vid_a_spec;

	INT <= int_profi when ds80 = '1' else int_spec;

	rgb <= rgb_profi when ds80 = '1' else rgb_spec;
	i <= i_profi when ds80 = '1' else i_spec;

	HSYNC <= hsync_profi when ds80 = '1' else hsync_spec;
	VSYNC <= vsync_profi when ds80 = '1' else vsync_spec;	
	
	HCNT <= hcnt_profi when ds80 = '1' else hcnt_spec;
	VCNT <= vcnt_profi when ds80 = '1' else vcnt_spec;
	ISPAPER <= ispaper_profi when ds80 = '1' else ispaper_spec;
	
	VID_RD2 <= vidrd_profi when ds80 = '1' else '0';
	
	ATTR_O <= attr_o_profi when ds80 = '1' else attr_o_spec;
	pFF_CS <= pFF_CS_profi when ds80 = '1' else pFF_CS_spec;
	
	-- Палитра profi:

	-- 1) палитра - это память на 16 ячеек. каждая ячейка - 8-битное значение цвета в виде GGGRRRBB
	-- 2) в палитру пишется инвертированное значение старшей половины адреса ША по адресу, заданному в порту #FE (тоже инвертированное значение)
	-- 3) строб записи по схеме формируется при обращении к порту палитры #7E в режиме DS80
	-- 4) при чтении адресом выступает код цвета от видеоконтроллера - YGRB
			
	-- запись палитры
	process(CLK2x, CLK, reset, palette_wr, palette_a, palette_wr_data, palette)
	begin
		if reset = '1' then 
			-- set default palette on reset
			palette <= (
				0 => "000000000", 1 => "000000100", 2 =>  "000100000", 3 =>  "000100100", 4 =>  "100000000", 5 =>  "100000100", 6 =>  "100100000", 7 =>  "100100100",
				8 => "000000000", 9 => "000000110", 10 => "000110000", 11 => "000110110", 12 => "110000000", 13 => "110000110", 14 => "110110000", 15 => "110110110"
			);
		elsif rising_edge(CLK2x) then 
			if CLK = '1' and palette_wr = '1' then
					palette(to_integer(unsigned(BORDER(3 downto 0) xor X"F"))) <= (not BUS_A) & BORDER(7);
			end if;
		end if;
	end process;
	
	palette_a <= i & rgb(1) & rgb(2) & rgb(0);
   palette_wr <= '1' when CS7E = '1' and BUS_WR_N = '0' and ds80 = '1' and reset = '0' else '0';

	-- чтение из палитры
	palette_grb <= palette(to_integer(unsigned(palette_a)));
	
	-- возвращаем наверх (top level) значение младшего разряда зеленого компонента палитры, это служит для отпределения наличия палитры в системе
	GX0 <= palette_grb(6) xor palette_grb(0) when ds80 = '1' else '1';
	
	-- применяем blank для профи, ибо в видеоконтроллере он после палитры
	process(CLK2x, CLK, blank_profi, palette_grb, ds80) 
	begin 
		if (blank_profi = '1' and ds80='1') then
			palette_grb_reg <= (others => '0');
		else
			palette_grb_reg <= palette_grb;
		end if;
	end process;
	
	VIDEO_R <= palette_grb_reg(5 downto 3);
	VIDEO_G <= palette_grb_reg(8 downto 6);
	VIDEO_B <= palette_grb_reg(2 downto 0);

end architecture;