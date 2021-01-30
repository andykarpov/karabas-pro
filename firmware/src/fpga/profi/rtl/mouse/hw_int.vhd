library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity hw_int is
port(
	 CLK			: in std_logic;
	 N_RESET 	: in std_logic := '1';
	 
    A          : in std_logic_vector(15 downto 0);
	 DI 			: in std_logic_vector(7 downto 0);
	 WR_N 		: in std_logic := '1';
	 RD_N 		: in std_logic := '1';
	 IORQ_N 		: in std_logic := '1';
	 M1_N 		: in std_logic := '1';
	 CPM 			: in std_logic := '0';
	 DOS 			: in std_logic := '0';
	 ROM14 		: in std_logic := '0';
	 
	 RXRDT 		: in std_logic := '0';
	 TXRDT 		: in std_logic := '0';
	 
	 DO			: out std_logic_vector(7 downto 0);
	 INT_N 		: out std_logic := '1';
	 INT_EN 		: out std_logic := '0';
	 OE_N 		: out std_logic := '1'
	 
);
end hw_int;

architecture RTL of hw_int is
	
	-- В компьютере  PROFI 2+ в связи с добавлением новой аппаратуры система прерываний была расширена: 
	-- в режиме  IM0, IM2 программист должен учитывать следущие особенности: 
   -- кроме прерывания от кадровой синхронизации (50 Герц) должна осуществляться обработка прерываний от коммуникационного порта 
	-- (RST20H - прием, RST28H - передача) и от аппаратных часов (RST30H), в системе обработка этих пррываний осуществляется 
	-- драйверами коммуникационного порта и аппаратных часов;

	signal int : std_logic := '0';
	signal int_rq : std_logic := '0';
	signal fi : std_logic := '0';
	signal port93_b0 : std_logic := '0';
	signal p4i : std_logic := '1';
		
begin

	p4i <= '0' when ((A(7 downto 0) = x"B3" or A(7 downto 0) = x"93") and IORQ_N='0') and ((cpm='1' and rom14='1') or (dos='1' and rom14='0')) else '1';	
	int_rq <= rxrdt or txrdt;
	int <= '0' when int_rq='1' and CPM='1' and port93_b0='1' else '1';
	fi <= '0' when M1_N='0' and IORQ_N = '0' and int = '0' else '1';
	
	-- port #93 / #B3
	process (N_RESET, CLK, WR_N, DI, p4i)
	begin
		if N_RESET = '0' then
			port93_b0 <= '0';			
		elsif CLK'event and CLK = '1' then
			-- int reg
			if (p4i = '0' and WR_N = '0') then
				port93_b0 <= DI(0); -- 1 = enable int
			end if;
		end if;
	end process;
			
	-- output data to CPU
	OE_N <= '0' when (fi='0' and int_rq = '1') else '1';
	DO <= 
			"11100111" when fi='0' and rxrdt = '1' else -- RST20h
			"11101111" when fi='0' and txrdt = '1' else -- RST28h	
			(others => '1');
	INT_N <= int;
	INT_EN <= port93_b0;
	
end RTL;

