--------------------------------------------------------------------------------
-- TS ZiFi (ESP8266) API v1 + TS RS232 (USB UART via MCU) + EVO RS232 (USB UART via MCU)
-- https://github.com/HackerVBI/ZiFi/blob/master/_esp/upd1/README!!__eRS232.txt
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- Ukraine, 2023, 2024
--------------------------------------------------------------------------------
library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity zifi is
port(
    CLK         : in std_logic;
    RESET       : in std_logic;
	 DS80        : in std_logic;

    A           : in std_logic_vector(15 downto 0);
    DI          : in std_logic_vector(7 downto 0);
    DO          : out std_logic_vector(7 downto 0);
    IORQ_N      : in std_logic;
    RD_N        : in std_logic;
    WR_N        : in std_logic;

    ZIFI_OE_N   : out std_logic;
	 
	 ENABLED     : out std_logic;
	 
	 -- usb uart (mcu interface)
	 USB_UART_RX_DATA : in std_logic_vector(7 downto 0);
	 USB_UART_RX_IDX  : in std_logic_vector(7 downto 0);
	 USB_UART_TX_DATA : out std_logic_vector(7 downto 0);
	 USB_UART_TX_WR : out std_logic := '0';
	 USB_UART_TX_MODE : out std_logic := '0';
	 USB_UART_DLL : out std_logic_vector(7 downto 0);
	 USB_UART_DLM : out std_logic_vector(7 downto 0);
	 USB_UART_DLL_WR : out std_logic;
	 USB_UART_DLM_WR : out std_logic;

	 -- esp 8266
    UART_RX     : in std_logic;
    UART_TX     : out std_logic;
    UART_CTS    : out std_logic        
);
end zifi;

architecture rtl of zifi is

component uart 
port ( 
    clk_bus     : in std_logic;
	 ds80        : in std_logic;
    txdata      : in std_logic_vector(7 downto 0);
    txbegin     : in std_logic;
    txbusy      : out std_logic;
    rxdata      : out std_logic_vector(7 downto 0);
    rxrecv      : out std_logic;
    data_read   : in std_logic;
    rx          : in std_logic;
    tx          : out std_logic;
    rts         : out std_logic);
end component;

-- ts zifi/rs232 ports
constant command_port  : std_logic_vector(15 downto 0) := x"C7EF"; -- 51183
constant error_port    : std_logic_vector(15 downto 0) := x"C7EF"; -- 51183
constant data_port     : std_logic_vector(15 downto 0) := x"BFEF"; -- 49135

constant zifi_in_fifo_port  : std_logic_vector(15 downto 0) := x"C0EF"; -- 49391
constant zifi_out_fifo_port : std_logic_vector(15 downto 0) := x"C1EF"; -- 49647
constant zifi_fifo_size     : std_logic_vector(7 downto 0) := x"FF";

constant rs232_in_fifo_port  : std_logic_vector(15 downto 0) := x"C2EF"; -- 49903
constant rs232_out_fifo_port : std_logic_vector(15 downto 0) := x"C3EF"; -- 50159
constant rs232_fifo_size     : std_logic_vector(7 downto 0) := x"FF";

-- evo rs232 ports
constant evo_data_port      : std_logic_vector(15 downto 0) := x"F8EF"; -- data port / dll port (when lcr7=1)
constant evo_ier_port       : std_logic_vector(15 downto 0) := x"F9EF"; -- interrupt enable port / dll port (when lcr7=1)
constant evo_fcr_port       : std_logic_vector(15 downto 0) := x"FAEF"; -- fifo control register / read isr status
constant evo_lcr_port       : std_logic_vector(15 downto 0) := x"FBEF"; -- line control register
constant evo_mcr_port       : std_logic_vector(15 downto 0) := x"FCEF"; -- modem control register
constant evo_lsr_port       : std_logic_vector(15 downto 0) := x"FDEF"; -- line status register
constant evo_msr_port       : std_logic_vector(15 downto 0) := x"FEEF"; -- modem status register
constant evo_spr_port       : std_logic_vector(15 downto 0) := x"FFEF"; -- user register

signal is_rs232				 : std_logic := '0'; -- 1 if accessed to ts rs232 / evo rs232
signal is_evo_rs232			 : std_logic := '0'; -- 1 if acccessed to evo rs232

signal evo_ier_reg          : std_logic_vector(7 downto 0); 
signal evo_dl_reg           : std_logic_vector(15 downto 0); 
signal evo_lcr_reg          : std_logic_vector(7 downto 0);
signal evo_mcr_reg          : std_logic_vector(7 downto 0);
signal evo_lsr_reg          : std_logic_vector(7 downto 0);
signal evo_msr_reg          : std_logic_vector(7 downto 0);
signal evo_spr_reg          : std_logic_vector(7 downto 0);

signal command_reg          : std_logic_vector(7 downto 0);
signal err_reg              : std_logic_vector(7 downto 0);
signal di_reg               : std_logic_vector(7 downto 0);
signal do_reg               : std_logic_vector(7 downto 0);
signal api_enabled          : std_logic := '1';

signal zifi_fifo_tx_di           : std_logic_vector(7 downto 0);
signal zifi_fifo_tx_do           : std_logic_vector(7 downto 0);
signal zifi_fifo_tx_rd_req       : std_logic := '0';
signal zifi_fifo_tx_wr_req       : std_logic := '0';
signal zifi_fifo_tx_clr_req      : std_logic := '0';
signal zifi_fifo_tx_used         : std_logic_vector(7 downto 0) := (others => '0');
signal zifi_fifo_tx_full 			 : std_logic;
signal zifi_fifo_tx_empty 		 : std_logic;

signal rs232_fifo_tx_di           : std_logic_vector(7 downto 0);
signal rs232_fifo_tx_do           : std_logic_vector(7 downto 0);
signal rs232_fifo_tx_rd_req       : std_logic := '0';
signal rs232_fifo_tx_wr_req       : std_logic := '0';
signal rs232_fifo_tx_clr_req      : std_logic := '0';
signal rs232_fifo_tx_used         : std_logic_vector(7 downto 0) := (others => '0');
signal rs232_fifo_tx_full 			 : std_logic;
signal rs232_fifo_tx_empty 		 : std_logic;

signal zifi_fifo_rx_di          : std_logic_vector(7 downto 0);
signal zifi_fifo_rx_do          : std_logic_vector(7 downto 0);
signal zifi_fifo_rx_rd_req      : std_logic := '0';
signal zifi_fifo_rx_wr_req      : std_logic := '0';
signal zifi_fifo_rx_clr_req     : std_logic := '0';
signal zifi_fifo_rx_used        : std_logic_vector(10 downto 0) := (others => '0');
signal zifi_fifo_rx_full 			: std_logic;
signal zifi_fifo_rx_empty       : std_logic;

signal rs232_fifo_rx_di          : std_logic_vector(7 downto 0);
signal rs232_fifo_rx_do          : std_logic_vector(7 downto 0);
signal rs232_fifo_rx_rd_req      : std_logic := '0';
signal rs232_fifo_rx_wr_req      : std_logic := '0';
signal rs232_fifo_rx_clr_req     : std_logic := '0';
signal rs232_fifo_rx_used        : std_logic_vector(10 downto 0) := (others => '0');
signal rs232_fifo_rx_full 			: std_logic;
signal rs232_fifo_rx_empty       : std_logic;

signal zifi_fifo_rx_free        : std_logic_vector(7 downto 0) := (others => '1');
signal zifi_fifo_tx_free         : std_logic_vector(7 downto 0) := (others => '1');

signal rs232_fifo_rx_free        : std_logic_vector(7 downto 0) := (others => '1');
signal rs232_fifo_tx_free         : std_logic_vector(7 downto 0) := (others => '1');

signal zifi_tx_begin_req         : std_logic := '0';
signal zifi_txbusy               : std_logic := '0';
signal zifi_txdone 				    : std_logic := '0';

signal rs232_tx_begin_req         : std_logic := '0';
signal rs232_txbusy               : std_logic := '0';
signal rs232_txdone 			  : std_logic := '1'; -- todo - implement ack on mcu side

signal zifi_wr_allow : std_logic := '1';
signal zifi_rd_allow : std_logic := '1';

signal rs232_wr_allow : std_logic := '1';
signal rs232_rd_allow : std_logic := '1';

signal new_command : std_logic := '0';

type txmachine IS (idle, pull_tx_fifo, end_pull_tx_fifo, req_uart_tx, end_req_uart_tx);
type rxmachine IS (idle, push_rx_fifo, end_push_rx_fifo, ack_uart_read);

signal zifi_txstate : txmachine := idle; 
signal zifi_rxstate : rxmachine := idle;
signal rs232_txstate : txmachine := idle; 
signal rs232_rxstate : rxmachine := idle;

signal prev_usb_uart_rx_idx : std_logic_vector(7 downto 0) := (others => '0');

signal zifi_fifo_rx_busy : std_logic := '0';
signal rs232_fifo_rx_busy : std_logic := '0';
signal zifi_fifo_busy_cnt : std_logic_vector(19 downto 0) := (others => '0');
signal rs232_fifo_busy_cnt : std_logic_vector(19 downto 0) := (others => '0');

begin

-- zifi

ZIFI_FIFO_IN: entity work.fifo
generic map(
	ADDR_WIDTH => 8, -- 256 bytes
	DATA_WIDTH => 8
)
port map(
    clk => CLK,
	 reset => zifi_fifo_tx_clr_req,
	 rd => zifi_fifo_tx_rd_req,
	 wr => zifi_fifo_tx_wr_req,
	 din => zifi_fifo_tx_di,
	 dout => zifi_fifo_tx_do,
	 full => zifi_fifo_tx_full,
	 empty => zifi_fifo_tx_empty,
	 data_count => zifi_fifo_tx_used
);

ZIFI_FIFO_OUT: entity work.fifo
generic map(
	ADDR_WIDTH => 11, -- 2 kbytes
	DATA_WIDTH => 8
)
port map(
    clk => CLK,
    reset  => zifi_fifo_rx_clr_req,
    rd => zifi_fifo_rx_rd_req,
    wr => zifi_fifo_rx_wr_req,
    din  => zifi_fifo_rx_di,
    dout     => zifi_fifo_rx_do,
	 full => zifi_fifo_rx_full,
	 empty => zifi_fifo_rx_empty,
    data_count => zifi_fifo_rx_used	 
);

-- rs232

RS232_FIFO_IN: entity work.fifo
generic map(
	ADDR_WIDTH => 8, -- 256 bytes
	DATA_WIDTH => 8
)
port map(
    clk => CLK,
    reset  => rs232_fifo_tx_clr_req,
    rd => rs232_fifo_tx_rd_req,
    wr => rs232_fifo_tx_wr_req,
    din  => rs232_fifo_tx_di,
    dout     => rs232_fifo_tx_do,
	 full => rs232_fifo_tx_full,
	 empty => rs232_fifo_tx_empty,
    data_count => rs232_fifo_tx_used	 
);

RS232_FIFO_OUT: entity work.fifo
generic map(
	ADDR_WIDTH => 11, -- 2 kbytes
	DATA_WIDTH => 8
)
port map(
    clk => CLK,
    reset  => rs232_fifo_rx_clr_req,
    rd => rs232_fifo_rx_rd_req,
    wr => rs232_fifo_rx_wr_req,
    din  => rs232_fifo_rx_di,
    dout     => rs232_fifo_rx_do,
	 full => rs232_fifo_rx_full,
	 empty => rs232_fifo_rx_empty,
    data_count => rs232_fifo_rx_used	 
);

-- esp8266 uart

UART_receiver: entity work.uart_rx
port map(
	i_Clk => CLK,
	i_RX_Serial => UART_RX,
	o_RX_DV => zifi_fifo_rx_wr_req,
	o_RX_Byte => zifi_fifo_rx_di
);

UART_transmitter: entity work.uart_tx
port map(
	i_Clk => CLK,
	i_TX_DV => zifi_tx_begin_req,
	i_TX_Byte => zifi_fifo_tx_do,
	o_TX_Active => zifi_txbusy,
	o_TX_Serial => UART_TX,
	o_TX_Done => zifi_txdone
);

-- usb uart
USB_UART_TX_DATA <= rs232_fifo_tx_do;
USB_UART_TX_WR <= rs232_tx_begin_req;

process (CLK)
begin
    if rising_edge(CLK) then
        rs232_fifo_rx_wr_req <= '0';
        if USB_UART_RX_IDX /= prev_usb_uart_rx_idx then
            rs232_fifo_rx_wr_req <= '1';
            rs232_fifo_rx_di <= USB_UART_RX_DATA;
            prev_usb_uart_rx_idx <= USB_UART_RX_IDX;
        end if;
    end if;
end process;

zifi_fifo_tx_di <= di_reg;
rs232_fifo_tx_di <= di_reg;

do_reg <= zifi_fifo_rx_do when is_rs232 = '0' else rs232_fifo_rx_do;

process (RESET, CLK)
begin
	 if RESET = '1' then 
			zifi_fifo_tx_rd_req <= '0';
            rs232_fifo_tx_rd_req <= '0';
    		zifi_tx_begin_req <= '0';
            rs232_tx_begin_req <= '0';
			zifi_txstate <= idle;
			zifi_rxstate <= idle;
			rs232_txstate <= idle;
			rs232_rxstate <= idle;
			
    elsif rising_edge(CLK) then

			zifi_tx_begin_req <= '0';
            rs232_tx_begin_req <= '0';

		  -- zifi fifo tx -> esp uart tx 
		  case zifi_txstate is
	
			when idle => 
				-- if tx fifo is not empty and transmitter is not busy
				if (zifi_fifo_tx_empty = '0' and zifi_txbusy = '0') then 
					zifi_txstate <= pull_tx_fifo;
				end if;

			-- request to read byte from fifo
			when pull_tx_fifo =>  
				zifi_fifo_tx_rd_req <= '1';
				zifi_txstate <= end_pull_tx_fifo;

			-- end request to read byte from fifo
			when end_pull_tx_fifo => 
				zifi_fifo_tx_rd_req <= '0';
				zifi_txstate <= req_uart_tx;

			-- begin uart tx request
			when req_uart_tx => 
				zifi_tx_begin_req <= '1';
				zifi_txstate <= end_req_uart_tx;

		   -- end uart tx request
			when end_req_uart_tx => 
				zifi_tx_begin_req <= '0';
				if (zifi_txdone = '1') then -- wait txdone from transmitter
				  zifi_txstate <= idle;
				end if;
				
			when others => null;
		  end case;

          -- rs232 fifo tx -> mcu uart tx 
		  case rs232_txstate is
	
			when idle => 
				-- if tx fifo is not empty and transmitter is not busy
				if (rs232_fifo_tx_empty = '0' and rs232_txbusy = '0') then 
					rs232_txstate <= pull_tx_fifo;
				end if;

			-- request to read byte from fifo
			when pull_tx_fifo =>  
				rs232_fifo_tx_rd_req <= '1';
				rs232_txstate <= end_pull_tx_fifo;

			-- end request to read byte from fifo
			when end_pull_tx_fifo => 
				rs232_fifo_tx_rd_req <= '0';
				rs232_txstate <= req_uart_tx;

			-- begin uart tx request
			when req_uart_tx => 
				rs232_tx_begin_req <= '1';
				rs232_txstate <= end_req_uart_tx;

		   -- end uart tx request
			when end_req_uart_tx => 
				rs232_tx_begin_req <= '0';
				if (rs232_txdone = '1') then -- wait txdone from transmitter
				  rs232_txstate <= idle;
				end if;
				
			when others => null;
		  end case;

    end if;
end process;

process (CLK, RESET) 
begin
    if (RESET = '1') then

        command_reg <= (others => '0');
        di_reg <= (others => '0');
        new_command <= '0';

        zifi_wr_allow <= '1';
        zifi_rd_allow <= '1';
        zifi_fifo_tx_wr_req <= '0';

        rs232_wr_allow <= '1';
        rs232_rd_allow <= '1';
        rs232_fifo_tx_wr_req <= '0';

        api_enabled <= '1';
        is_rs232 <= '0';
		  is_evo_rs232 <= '0';
		  
			evo_ier_reg <= (others => '0');
			evo_dl_reg <= (others => '0');
			evo_lcr_reg <= "00000011";
			evo_mcr_reg <= "00000000";
			evo_spr_reg <= (others => '0');  

			USB_UART_DLL_WR <= '0';
			USB_UART_DLM_WR <= '0';
		  
    elsif (rising_edge(CLK)) then
	 
		USB_UART_DLL_WR <= '0';
		USB_UART_DLM_WR <= '0';
	 
		zifi_fifo_tx_clr_req <= '0';
		zifi_fifo_rx_clr_req <= '0';

		rs232_fifo_tx_clr_req <= '0';
		rs232_fifo_rx_clr_req <= '0';
		
		zifi_fifo_tx_wr_req <= '0';
		rs232_fifo_tx_wr_req <= '0';
		
		zifi_fifo_rx_rd_req <= '0';
		rs232_fifo_rx_rd_req <= '0';
	 
        -- zifi_fifo_tx, rs232_fifo_tx write request
        if IORQ_N = '0' and WR_N = '0' then 
			 if A = command_port then 
				if (is_rs232 = '0' and zifi_wr_allow = '1' and new_command = '0') then 
					command_reg <= DI;
					zifi_wr_allow <= '0';
					new_command <= '1';
                elsif (is_rs232 = '1' and rs232_wr_allow = '1' and new_command = '0') then 
					command_reg <= DI;
					rs232_wr_allow <= '0';
					new_command <= '1'; 
				end if;
			 end if;

             if A(7 downto 0) = data_port(7 downto 0) and A(15 downto 8) <= data_port(15 downto 8) then 
				if (is_rs232 = '0' and zifi_fifo_tx_wr_req = '0' and zifi_wr_allow = '1') then
					zifi_wr_allow <= '0';
					di_reg <= DI; 
                    zifi_fifo_tx_wr_req <= '1';
                elsif (is_rs232 = '1' and rs232_fifo_tx_wr_req = '0' and rs232_wr_allow = '1') then
					rs232_wr_allow <= '0';
					di_reg <= DI; 
                    rs232_fifo_tx_wr_req <= '1';
				end if;
			 end if; 

             -- evo data / dll port
             if A = evo_data_port then 
                is_rs232 <= '1';
					 is_evo_rs232 <= '1';
                if evo_lcr_reg(7) = '1' then
                    evo_dl_reg(7 downto 0) <= DI;
						  USB_UART_DLL_WR <= '1';
                elsif (evo_lcr_reg(7) = '0' and rs232_fifo_tx_wr_req = '0' and rs232_wr_allow = '1') then
							rs232_wr_allow <= '0';
							di_reg <= DI; 
                    rs232_fifo_tx_wr_req <= '1';
				end if;
             end if;

             -- evo ier / dlm port
             if A = evo_ier_port then 
                is_rs232 <= '1';
					 is_evo_rs232 <= '1';
                if evo_lcr_reg(7) = '1' then 
                    evo_dl_reg(15 downto 8) <= DI;
						  USB_UART_DLM_WR <= '1';
                else
                    evo_ier_reg <= DI;
                end if;
             end if;

             -- evo fcr port
             if A = evo_fcr_port then 
                is_rs232 <= '1';
					 is_evo_rs232 <= '1';					 
                -- rx fifo clear
                if (DI(0) = '1' and DI(1) = '1') then
                    rs232_fifo_rx_clr_req <= '1';
                end if;
                if (DI(0) = '1' and DI(2) = '1') then
                    rs232_fifo_tx_clr_req <= '1';
                end if;
             end if;

            -- evo_lcr_port
            if A = evo_lcr_port then 
                is_rs232 <= '1';
					 is_evo_rs232 <= '1';					 
                -- bit 7: dl enable
                -- bit 5..3: 001 - odd parity, 011 - even parity, xxx - no parity
                -- bit 2: stop bits count. 0 - 1, 1 - 1.5 in 5 bit mode, else 2 
                -- bit 1..0: word len: 00 - 5 bit, 01 - 6 bit, 10 - 7 bit, 11 - 8 bit  
                evo_lcr_reg <= DI;
             end if;

            -- evo_mcr_port
            if A = evo_mcr_port then 
                is_rs232 <= '1';
					 is_evo_rs232 <= '1';					 
                -- bit 1:  RTS 
                evo_mcr_reg <= DI;
             end if;

            -- evo_spr_port
            if A = evo_spr_port then 
                is_rs232 <= '1';
					 is_evo_rs232 <= '1';
                evo_spr_reg <= DI;
            end if;

        end if;

		if (WR_N = '1') then 
			zifi_wr_allow <= '1';
			rs232_wr_allow <= '1';
		end if;


        -- zifi_fifo_rx read request
        if is_rs232 = '0' and IORQ_N = '0' and RD_N = '0' and A(7 downto 0) = data_port(7 downto 0) and A(15 downto 8) <= data_port(15 downto 8) and zifi_fifo_rx_empty = '0' then
				if (zifi_fifo_rx_rd_req = '0' and zifi_rd_allow = '1') then
					zifi_fifo_rx_rd_req <= '1';
					zifi_rd_allow <= '0';
				end if;
        end if;

        -- rs232_fifo_rx read request
        if is_rs232 = '1' and IORQ_N = '0' and RD_N = '0' and ((A(7 downto 0) = data_port(7 downto 0) and A(15 downto 8) <= data_port(15 downto 8)) or (A = evo_data_port and evo_lcr_reg(7) = '0')) and rs232_fifo_rx_empty = '0' then
				if (rs232_fifo_rx_rd_req = '0' and rs232_rd_allow = '1') then
					rs232_fifo_rx_rd_req <= '1';
					rs232_rd_allow <= '0';
				end if;
        end if;

        -- track access to fifo registers to detect rs232 / zifi mode
        if IORQ_N = '0' and RD_N = '0' and (A = zifi_in_fifo_port or A = zifi_out_fifo_port) then 
            is_rs232 <= '0';
				is_evo_rs232 <= '0';				
        elsif IORQ_N = '0' and RD_N = '0' and (A = rs232_in_fifo_port or A = rs232_out_fifo_port) then 
            is_rs232 <= '1';
				is_evo_rs232 <= '0';	
        elsif IORQ_N = '0' and RD_N = '0' and (A = evo_data_port or A = evo_ier_port or A = evo_lcr_port or A = evo_mcr_port or A = evo_lsr_port or A = evo_msr_port or A = evo_spr_port) then
            is_rs232 <= '1';
				is_evo_rs232 <= '1';	
        end if;
        
        if (RD_N = '1') then 
			zifi_rd_allow <= not zifi_fifo_rx_empty;
			rs232_rd_allow <= not rs232_fifo_rx_empty;
	    end if;
		  
        -- incoming command processing
        if new_command = '1' then
           new_command <= '0';
           err_reg <= (others => '0');
          case (command_reg) is
                -- clear rx fifo
		        when "00000001" => 
                    if (is_rs232 = '1') then
                        rs232_fifo_rx_clr_req <= '1';
                    else
                        zifi_fifo_rx_clr_req  <= '1'; 
                    end if;

                -- clear tx fifo
		        when "00000010" => 
                    if (is_rs232 = '1') then
                        rs232_fifo_tx_clr_req <= '1'; 
                    else                   
                        zifi_fifo_tx_clr_req <= '1'; 
                    end if;

                -- clear both in/out fifo
		        when "00000011" => 
                    if (is_rs232 = '1') then
                        rs232_fifo_tx_clr_req  <= '1'; 
                        rs232_fifo_rx_clr_req <= '1';
                    else
                        zifi_fifo_tx_clr_req  <= '1'; 
                        zifi_fifo_rx_clr_req <= '1';
                    end if;

                -- api disabled
		        when "11110000" => 
                    api_enabled      <= '0'; 

                -- api transparent
		        when "11110001" => 
                    api_enabled      <= '1'; 

                -- get API version
		        when "11111111" => 
			         if (api_enabled = '1') then 
				          err_reg <= "00000001"; 
			         else 
				          err_reg <= "11111111"; 
			         end if;

                -- unknown command 
		        when others => 
                    err_reg <= "11111111"; 
          end case;
        end if;
    end if;
end process;

DO <= -- ts zifi / rs232 ports 
		-- 191 when rx fifo > 191
      "10111111"  when IORQ_N = '0' and RD_N = '0' and A = zifi_in_fifo_port and zifi_fifo_rx_used > 191  else 
      "10111111"  when IORQ_N = '0' and RD_N = '0' and A = rs232_in_fifo_port and rs232_fifo_rx_used > 191  else 
		-- 0 when rx is busy (hotfix)
		"00000000"  when IORQ_N = '0' and RD_N = '0' and A = zifi_in_fifo_port and zifi_fifo_rx_busy = '1' else
		"00000000"  when IORQ_N = '0' and RD_N = '0' and A = rs232_in_fifo_port and rs232_fifo_rx_busy = '1' else
		-- actual rx fifo size
	   zifi_fifo_rx_used(7 downto 0)  when IORQ_N = '0' and RD_N = '0' and A = zifi_in_fifo_port  else 
      rs232_fifo_rx_used(7 downto 0)  when IORQ_N = '0' and RD_N = '0' and A = rs232_in_fifo_port  else 
		-- tx fifo size
      zifi_fifo_tx_free when IORQ_N = '0' and RD_N = '0' and A = zifi_out_fifo_port else 
      rs232_fifo_tx_free when IORQ_N = '0' and RD_N = '0' and A = rs232_out_fifo_port else 
		-- special regs
		err_reg       when IORQ_N = '0' and RD_N = '0' and A = error_port    else 
      do_reg        when IORQ_N = '0' and RD_N = '0' and A(7 downto 0) = data_port(7 downto 0) and A(15 downto 8) <= data_port(15 downto 8) else 
      -- evo rs232 ports
      do_reg when IORQ_N = '0' and RD_N = '0' and A = evo_data_port and evo_lcr_reg(7) = '0' else -- data
      evo_dl_reg(7 downto 0) when IORQ_N = '0' and RD_N = '0' and A = evo_data_port and evo_lcr_reg(7) = '1' else -- dll
      evo_ier_reg when IORQ_N = '0' and RD_N ='0' and A = evo_ier_port and evo_lcr_reg(7) = '0' else  -- ier
      evo_dl_reg(15 downto 8) when IORQ_N = '0' and RD_N = '0' and A = evo_ier_port and evo_lcr_reg(7) = '1' else -- dlm
      "00000000" when IORQ_N = '0' and RD_N = '0' and A = evo_fcr_port else -- isr
      evo_lcr_reg when IORQ_N = '0' and RD_N = '0' and A = evo_lcr_port else -- lcr
      evo_mcr_reg when IORQ_N = '0' and RD_N = '0' and A = evo_mcr_port else -- mcr
      evo_lsr_reg when IORQ_N = '0' and RD_N = '0' and A = evo_lsr_port else -- lsr
      evo_msr_reg when IORQ_N = '0' and RD_N = '0' and A = evo_msr_port else -- msr
      evo_spr_reg when IORQ_N = '0' and RD_N = '0' and A = evo_spr_port else -- spr
   "11111111";

zifi_fifo_tx_free <= std_logic_vector(unsigned(zifi_fifo_size) - unsigned(zifi_fifo_tx_used));
rs232_fifo_tx_free <= std_logic_vector(unsigned(zifi_fifo_size) - unsigned(rs232_fifo_tx_used));
        
ZIFI_OE_N <= '0' when IORQ_N = '0' and RD_N = '0' and (
    A = evo_data_port or
    A = evo_ier_port or 
    A = evo_fcr_port or
    A = evo_lcr_port or
    A = evo_mcr_port or
    A = evo_lsr_port or 
    A = evo_msr_port or
    A = evo_spr_port or
    A = zifi_in_fifo_port or 
    A = zifi_out_fifo_port or 
    A = rs232_in_fifo_port or 
    A = rs232_out_fifo_port or 
    A = error_port or 
    (A(7 downto 0) = data_port(7 downto 0) and A(15 downto 8) <= data_port(15 downto 8))  ) 
    else '1';

-- line status regisrer
-- bit 6: 1 = both transmitter / tx fifo empty
-- bit 5: 1 = tx fifo empty
-- bit 3: 1 = frame error
-- bit 2: 1 = parity error
-- bit 1: 1 = rx fifo full
-- bit 0: 1 = rx fifo has data
evo_lsr_reg(6) <= rs232_fifo_tx_empty;
evo_lsr_reg(5) <= rs232_fifo_tx_empty;
evo_lsr_reg(3 downto 2) <= "00";
evo_lsr_reg(1) <= rs232_fifo_rx_full;
evo_lsr_reg(0) <= not rs232_fifo_rx_empty; 

-- modem status register
-- bit 7: CD (always 1)
-- bit 6: RI (always 1)
-- bit 5: DSR (always 1)
-- bit 4: CTS 
-- bit 1..3: 0
-- bit 0: cts change. 1 if cts changed, 0 when read register 
evo_msr_reg <= "11100000";

ENABLED <= api_enabled;

UART_CTS <= '1' when zifi_fifo_rx_used > 1792 else '0'; -- active 0
USB_UART_DLL <= evo_dl_reg(7 downto 0);
USB_UART_DLM <= evo_dl_reg(15 downto 8);
USB_UART_TX_MODE <= is_evo_rs232;

-- workarround to fix random hang of zifi.spg (a2cfe54), which is always doing 191-bytes-inir (see fifo_inir function)
process (clk) begin
	if rising_edge(clk) then
		-- zifi
		if (zifi_fifo_rx_wr_req = '1') then 
			zifi_fifo_busy_cnt <= "00000000000000000001";
		elsif (zifi_fifo_busy_cnt > 0) then 
			zifi_fifo_busy_cnt <= zifi_fifo_busy_cnt + 1;
		end if;		
		if (zifi_fifo_rx_wr_req = '1' or zifi_fifo_busy_cnt > 0) and zifi_fifo_rx_used < 191 then
			zifi_fifo_rx_busy <= '1';
		else
			zifi_fifo_rx_busy <= '0';
		end if;
		-- rs232
		if (rs232_fifo_rx_wr_req = '1') then 
			rs232_fifo_busy_cnt <= "00000000000000000001";
		elsif (rs232_fifo_busy_cnt > 0) then 
			rs232_fifo_busy_cnt <= rs232_fifo_busy_cnt + 1;
		end if;		
		if (rs232_fifo_rx_wr_req = '1' or rs232_fifo_busy_cnt > 0) and rs232_fifo_rx_used < 191 then
			rs232_fifo_rx_busy <= '1';
		else
			rs232_fifo_rx_busy <= '0';
		end if;		
	end if;
end process;

end rtl;
