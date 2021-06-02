-------------------------------------------------------------------[04.12.2016]
-- TurboSound
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity turbosound is
	port ( 
		I_CLK		   : in std_logic;
		I_ENA		   : in std_logic;
		I_ADDR		: in std_logic_vector(15 downto 0);
		I_DATA		: in std_logic_vector(7 downto 0);
		I_WR_N		: in std_logic;
		I_IORQ_N	   : in std_logic;
		I_M1_N		: in std_logic;
		I_RESET_N	: in std_logic;
		I_BDIR      : in std_logic;
		I_BC1       : in std_logic;
		O_SEL		   : out std_logic;
		I_MODE 	   : in std_logic;
		-- ssg0
		O_SSG0_DA	: out std_logic_vector(7 downto 0);
		O_SSG0_AUDIO_A	: out std_logic_vector(7 downto 0);
		O_SSG0_AUDIO_B	: out std_logic_vector(7 downto 0);
		O_SSG0_AUDIO_C	: out std_logic_vector(7 downto 0);
		-- ssg1
		O_SSG1_DA	: out std_logic_vector(7 downto 0);
		O_SSG1_AUDIO_A	: out std_logic_vector(7 downto 0);
		O_SSG1_AUDIO_B	: out std_logic_vector(7 downto 0);
		O_SSG1_AUDIO_C	: out std_logic_vector(7 downto 0)
	);
end turbosound;
 
architecture rtl of turbosound is
	signal bc1	: std_logic;
	signal bdir	: std_logic;
	signal ssg	: std_logic;
	
component ym2149 is
port (
	CLK		: in std_logic;				-- Global clock
	CE		: in std_logic;				-- PSG Clock enable
	RESET		: in std_logic;				-- Chip RESET (set all Registers to '0', active hi)
	BDIR		: in std_logic;				-- Bus Direction (0 - read , 1 - write)
	BC		: in std_logic;				-- Bus control
	DI		: in std_logic_vector(7 downto 0);	-- Data In
	DO		: out std_logic_vector(7 downto 0);	-- Data Out
	CHANNEL_A	: out std_logic_vector(7 downto 0);	-- PSG Output channel A
	CHANNEL_B	: out std_logic_vector(7 downto 0);	-- PSG Output channel B
	CHANNEL_C	: out std_logic_vector(7 downto 0);	-- PSG Output channel C
	SEL		: in std_logic;
	MODE		: in std_logic;
	ACTIVE		: out std_logic_vector(5 downto 0);
	A8			: in std_logic;
	IOA_in	: in std_logic_vector(7 downto 0);
	IOA_out : out std_logic_vector(7 downto 0);
	IOB_in :  in std_logic_vector(7 downto 0);
	IOB_out : out std_logic_vector(7 downto 0)
);
end component;
	
	
begin

bdir	<= '1' when (I_M1_N = '1' and I_IORQ_N = '0' and I_WR_N = '0' and I_ADDR(15) = '1' and I_ADDR(1) = '0') else '0';
bc1	<= '1' when (I_M1_N = '1' and I_IORQ_N = '0' and I_ADDR(15) = '1' and I_ADDR(14) = '1' and I_ADDR(1) = '0') else '0';
--	bdir <= I_BDIR;
--	bc1 <= I_BC1;
	
	O_SEL	<= ssg;
	
	process(I_CLK, I_RESET_N)
	begin
		if (I_RESET_N = '0') then
			ssg <= '0';
		elsif (I_CLK'event and I_CLK = '1') then
			if (I_DATA(7 downto 1) = "1111111" and bdir = '1' and bc1 = '1') then
				ssg <= I_DATA(0);
			end if;
		end if;
	end process;

ssg0: ym2149
port map (
	CLK		=> I_CLK,	
	CE		=> I_ENA,
	RESET		=> not I_RESET_N,
	BDIR		=> bdir,
	BC		=> bc1,
	DI		=> I_DATA,
	DO		=> O_SSG0_DA,
	CHANNEL_A	=> O_SSG0_AUDIO_A,
	CHANNEL_B	=> O_SSG0_AUDIO_B,
	CHANNEL_C	=> O_SSG0_AUDIO_C,
	ACTIVE		=> open,
	SEL		=> '0',
	A8		=> not ssg,
	MODE		=> I_MODE,
	IOA_in => (others => '0'),
	IOA_out => open,
	IOB_in => (others => '0'),
	IOB_out => open
);
	
ssg1: ym2149
port map (
	CLK		=> I_CLK,	
	CE		=> I_ENA,
	RESET		=> not I_RESET_N,
	BDIR		=> bdir,
	BC		=> bc1,
	DI		=> I_DATA,
	DO		=> O_SSG1_DA,
	CHANNEL_A	=> O_SSG1_AUDIO_A,
	CHANNEL_B	=> O_SSG1_AUDIO_B,
	CHANNEL_C	=> O_SSG1_AUDIO_C,
	ACTIVE		=> open,
	SEL		=> '0',
	A8		=> ssg,
	MODE		=> I_MODE,
	IOA_in => (others => '0'),
	IOA_out => open,
	IOB_in => (others => '0'),
	IOB_out => open	
);	

end rtl;	