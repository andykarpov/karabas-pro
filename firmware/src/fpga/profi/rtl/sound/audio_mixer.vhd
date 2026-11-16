-------------------------------------------------------------------------------
-- Audio mixer
--
-- Mixes the beeper, TurboSound (2 x AY), covox / Soundrive and SAA1099 into
-- 16-bit two's complement samples for the DAC (tda1543), stereo ACB / ABC or
-- mono.
--
-- All terms are signed and summed with headroom (17 bits), then halved:
--   AY, SAA and the beeper are unipolar levels (0 = silence): positive terms;
--   covox channels are 8-bit PCM with 0x80 = silence: centred (x - 128).
-- With these weights the sum is within +48928 / -12288 (stereo) and
-- +44848 / -10240 (mono), so after the halving it always fits 16 bits, and no
-- bit is lost (every term is shifted left by at least 4). Silence is 0.
--
-- The result is registered: the DAC loads it on the falling edge of CLK, and
-- the wide adder gets a full clock period.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity audio_mixer is
	port (
		CLK      : in  std_logic;
		MUTE     : in  std_logic;                     -- output 0
		MONO     : in  std_logic;                     -- all sources to both channels
		ABC      : in  std_logic;                     -- 0 = ACB stereo, 1 = ABC stereo
		SPEAKER  : in  std_logic;
		SSG0_A   : in  std_logic_vector(7 downto 0);
		SSG0_B   : in  std_logic_vector(7 downto 0);
		SSG0_C   : in  std_logic_vector(7 downto 0);
		SSG1_A   : in  std_logic_vector(7 downto 0);
		SSG1_B   : in  std_logic_vector(7 downto 0);
		SSG1_C   : in  std_logic_vector(7 downto 0);
		COVOX_A  : in  std_logic_vector(7 downto 0);
		COVOX_B  : in  std_logic_vector(7 downto 0);
		COVOX_C  : in  std_logic_vector(7 downto 0);
		COVOX_D  : in  std_logic_vector(7 downto 0);
		COVOX_FB : in  std_logic_vector(7 downto 0);
		SAA_L    : in  std_logic_vector(7 downto 0);
		SAA_R    : in  std_logic_vector(7 downto 0);
		AUDIO_L  : out std_logic_vector(15 downto 0) := (others => '0');
		AUDIO_R  : out std_logic_vector(15 downto 0) := (others => '0')
	);
end entity;

architecture rtl of audio_mixer is

	-- unipolar level
	function u_term(x : std_logic_vector(7 downto 0); sh : natural) return signed is
	begin
		return shift_left(resize(signed('0' & x), 17), sh);
	end function;

	-- 8-bit PCM, 0x80 = 0
	function c_term(x : std_logic_vector(7 downto 0); sh : natural) return signed is
	begin
		return shift_left(resize(signed((not x(7)) & x(6 downto 0)), 17), sh);
	end function;

	-- 1-bit level
	function bit_term(b : std_logic; sh : natural) return signed is
	begin
		if b = '1' then
			return shift_left(to_signed(1, 17), sh);
		end if;
		return to_signed(0, 17);
	end function;

	-- halve into a 16-bit sample
	function to_sample(x : signed(16 downto 0)) return std_logic_vector is
	begin
		return std_logic_vector(resize(shift_right(x, 1), 16));
	end function;

	signal mono_sum : signed(16 downto 0);
	signal l_sum    : signed(16 downto 0);
	signal r_sum    : signed(16 downto 0);

	-- AY channels after the ACB / ABC choice: full-weight for L and R, half-weight
	signal l0, l1, r0, r1, h0, h1 : std_logic_vector(7 downto 0);

begin

	mono_sum <=
		bit_term(SPEAKER, 11) +
		u_term(SSG0_A, 4) + u_term(SSG0_B, 4) + u_term(SSG0_C, 4) +
		u_term(SSG1_A, 4) + u_term(SSG1_B, 4) + u_term(SSG1_C, 4) +
		c_term(COVOX_A, 4) + c_term(COVOX_B, 4) + c_term(COVOX_C, 4) + c_term(COVOX_D, 4) + c_term(COVOX_FB, 4) +
		u_term(SAA_L, 4) + u_term(SAA_R, 4);

	-- ACB: L = A + C/2, R = B + C/2; ABC: L = A + B/2, R = C + B/2.
	-- The channels are chosen before the adders, so there is one adder tree per side.
	l0 <= SSG0_A;
	l1 <= SSG1_A;
	r0 <= SSG0_C when ABC = '1' else SSG0_B;
	r1 <= SSG1_C when ABC = '1' else SSG1_B;
	h0 <= SSG0_B when ABC = '1' else SSG0_C;
	h1 <= SSG1_B when ABC = '1' else SSG1_C;

	l_sum <=
		bit_term(SPEAKER, 12) +
		u_term(l0, 5) + u_term(l1, 5) + u_term(h0, 4) + u_term(h1, 4) +
		c_term(COVOX_A, 5) + c_term(COVOX_B, 5) + c_term(COVOX_FB, 5) +
		u_term(SAA_L, 5);

	r_sum <=
		bit_term(SPEAKER, 12) +
		u_term(r0, 5) + u_term(r1, 5) + u_term(h0, 4) + u_term(h1, 4) +
		c_term(COVOX_C, 5) + c_term(COVOX_D, 5) + c_term(COVOX_FB, 5) +
		u_term(SAA_R, 5);

	process (CLK)
	begin
		if rising_edge(CLK) then
			if MUTE = '1' then
				AUDIO_L <= (others => '0');
				AUDIO_R <= (others => '0');
			elsif MONO = '1' then
				AUDIO_L <= to_sample(mono_sum);
				AUDIO_R <= to_sample(mono_sum);
			else
				AUDIO_L <= to_sample(l_sum);
				AUDIO_R <= to_sample(r_sum);
			end if;
		end if;
	end process;

end architecture;
