-------------------------------------------------------------------------------
-- SRAM controller
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity sram is
port (
	CLK 			: in std_logic;

	-- phy interface
	MA 			: out std_logic_vector(20 downto 0);
	MD 			: inout std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
	N_MRD 		: out std_logic_vector(1 downto 0);
	N_MWR 		: out std_logic_vector(1 downto 0);

	-- cpu-ram interface
	RAM_A 		: in std_logic_vector(21 downto 0);
	RAM_DI 		: in std_logic_vector(7 downto 0);
	RAM_DO 		: out std_logic_vector(7 downto 0);
	RAM_WR		: in std_logic;
	RAM_RD		: in std_logic;
	
	-- vram interface
	VRAM_A 		: in std_logic_vector(21 downto 0);
	VRAM_DO		: out std_logic_vector(7 downto 0);
	VRAM_RD 		: in std_logic;

	-- loader interface
	LOADER_ACR  : in std_logic;
	LOADER_A    : in std_logic_vector(31 downto 0);
	LOADER_DI	: in std_logic_vector(7 downto 0);
	LOADER_WR   : in std_logic;
	
	-- mem busy signal
	BUSY : out std_logic
);
end sram;

architecture RTL of sram is

type qmachine IS(idle, rd_req, rd_done, vid_rd_req, vid_rd_done, wr_req, wr_done);
signal qstate : qmachine := idle;

signal wr_addr : std_logic_vector(21 downto 0);
signal wr_data : std_logic_vector(7 downto 0);

signal rd_addr : std_logic_vector(21 downto 0);
signal rd_data : std_logic_vector(7 downto 0);

signal vid_rd_addr : std_logic_vector(21 downto 0);
signal vid_rd_data : std_logic_vector(7 downto 0);

begin

process(CLK) 
begin 

	if rising_edge(CLK) then 
		case qstate is 

			when idle => 
				if LOADER_ACT = '1' and LOADER_WR = '1' then 
					BUSY <= '1';
					wr_addr <= LOADER_A;
					wr_data <= LOADER_DI;
					qstate <= wr_req;
				elsif RAM_WR = '1' then 
					BUSY <= '1';				
					wr_addr <= RAM_A;
					wr_data <= RAM_DI;
					qstate <= wr_req;
				elsif RAM_RD = '1' then 
					BUSY <= '1';
					rd_addr <= RAM_A;
					qstate <= rd_req;
				elsif VID_RD = '1' then 
					BUSY <= '1';
					rd_addr <= VRAM_A;
					qstate <= vid_rd_req;
				else 
					BUSY <= '0';				
					qstate <= idle;
					N_MRD <= "11";
					N_MWR <= "11";
					MD <= (others => 'Z');
				end if;
			
			when rd_req => 
				if rd_addr(21) = '1' then 
					N_MRD <= "01";
				else 
					N_MRD <= "10";
				end if;
				qstate <= rd_done;
			
			when rd_done => 
				N_MRD <= "11";
				if rd_addr(21) = '1' then 
					RAM_DO <= MD(15 downto 8);
				else 
					RAM_DO <= MD(7 downto 0);
				end if;
				qstate <= idle;
			
			when vid_rd_req => 
				N_MRD <= "10";
				qstate <= vid_rd_done;
			
			when vid_rd_done =>
				N_MRD <= "11";
				VID_DO <= MD(7 downto 0);
				qstate <= idle;
			
			when wr_req => 
				MA <= RAM_A(20 downto 0);
				if (wr_addr(21) = '1') then 
					N_MWR <= "01";	
					MD(15 downto 8) <= RAM_DI;
				else 
					N_MWR <= "10";
					MD(7 downto 0) <= RAM_DI;
				end if;
				qstate <= wr_done;
			
			when wr_done =>
				N_MWR <= "11";
				MD <= (others => 'Z');
				qstate <= idle;
			
		end case;
	end if;

end process;   

			
end RTL;

