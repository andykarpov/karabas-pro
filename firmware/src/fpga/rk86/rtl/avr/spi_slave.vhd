----------------------------------------------------------------------------------
-- Author:          Jonny Doin, jdoin@opencores.org
-- 
-- Create Date:     15:36:20 05/15/2011
-- Module Name:     SPI_SLAVE - RTL
-- Project Name:    SPI INTERFACE
-- Target Devices:  Spartan-6
-- Tool versions:   ISE 13.1
-- Description: 
--
--      This block is the SPI slave interface, implemented in one single entity.
--      All internal core operations are synchronous to the external SPI clock, and follows the general SPI de-facto standard.
--      The parallel read/write interface is synchronous to a supplied system master clock, 'clk_i'.
--      Synchronization for the parallel ports is provided by input data request and write enable lines, and output data valid line.
--
--      The block is very simple to use, and has parallel inputs and outputs that behave like a synchronous memory i/o.
--      It is parameterizable via generics for the data width ('N'), SPI mode (CPHA and CPOL), and lookahead prefetch 
--      signaling ('PREFETCH').
--
--      PARALLEL WRITE INTERFACE
--      The parallel interface has a input port 'di_i' and an output port 'do_o'.
--      Parallel load is controlled using 3 signals: 'di_i', 'di_req_o' and 'wren_i'. 
--      When the core needs input data, a look ahead data request strobe , 'di_req_o' is pulsed 'PREFETCH' 'spi_sck_i' 
--      cycles in advance to synchronize a user pipelined memory or fifo to present the next input data at 'di_i' 
--      in time to have continuous clock at the spi bus, to allow back-to-back continuous load.
--      The data request strobe on 'di_req_o' is 2 'clk_i' clock cycles long.
--      The write to 'di_i' must occur at most one 'spi_sck_i' cycle before actual load to the core shift register, to avoid
--      race conditions at the register transfer.
--      The user circuit places data at the 'di_i' port and strobes the 'wren_i' line for one rising edge of 'clk_i'.
--      For a pipelined sync RAM, a PREFETCH of 3 cycles allows an address generator to present the new adress to the RAM in one
--      cycle, and the RAM to respond in one more cycle, in time for 'di_i' to be latched by the interface one clock before transfer.
--      If the user sequencer needs a different value for PREFETCH, the generic can be altered at instantiation time.
--      The 'wren_i' write enable strobe must be valid at least one setup time before the rising edge of the last clock cycle,
--      if continuous transmission is intended. 
--      When the interface is idle ('spi_ssel_i' is HIGH), the top bit of the latched 'di_i' port is presented at port 'spi_miso_o'.
--
--      PARALLEL WRITE PIPELINED SEQUENCE
--      =================================
--                     __    __    __    __    __    __    __ 
--      clk_i       __/  \__/  \__/  \__/  \__/  \__/  \__/  \...     -- parallel interface clock
--                           ___________                        
--      di_req_o    ________/           \_____________________...     -- 'di_req_o' asserted on rising edge of 'clk_i'
--                  ______________ ___________________________...
--      di_i        __old_data____X______new_data_____________...     -- user circuit loads data on 'di_i' at next 'clk_i' rising edge
--                                             ________                        
--      wren_i      __________________________/        \______...     -- 'wren_i' enables latch on rising edge of 'clk_i'
--                      
--
--      PARALLEL READ INTERFACE
--      An internal buffer is used to copy the internal shift register data to drive the 'do_o' port. When a complete 
--      word is received, the core shift register is transferred to the buffer, at the rising edge of the spi clock, 'spi_sck_i'.
--      The signal 'do_valid_o' is strobed 3 'clk_i' clocks after, to directly drive a synchronous memory or fifo write enable.
--      'do_valid_o' is synchronous to the parallel interface clock, and changes only on rising edges of 'clk_i'.
--      When the interface is idle, data at the 'do_o' port holds the last word received.
--
--      PARALLEL READ PIPELINED SEQUENCE
--      ================================
--                      ______        ______        ______        ______
--      clk_spi_i   ___/ bit1 \______/ bitN \______/bitN-1\______/bitN-2\__...  -- spi base clock
--                     __    __    __    __    __    __    __    __    __  
--      clk_i       __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \_...  -- parallel interface clock
--                  _________________ _____________________________________...  -- 1) received data is transferred to 'do_buffer_reg'
--      do_o        __old_data_______X__________new_data___________________...  --    after last bit received, at next shift clock.
--                                                   ____________               
--      do_valid_o  ________________________________/            \_________...  -- 2) 'do_valid_o' strobed for 2 'clk_i' cycles
--                                                                              --    on the 3rd 'clk_i' rising edge.
--
--
--      This design was originally targeted to a Spartan-6 platform, synthesized with XST and normal constraints.
--
------------------------------ COPYRIGHT NOTICE -----------------------------------------------------------------------
--                                                                   
--      This file is part of the SPI MASTER/SLAVE INTERFACE project http://opencores.org/project,spi_master_slave                
--                                                                   
--      Author(s):      Jonny Doin, jdoin@opencores.org
--                                                                   
--      Copyright (C) 2011 Authors and OPENCORES.ORG
--      --------------------------------------------
--                                                                   
--      This source file may be used and distributed without restriction provided that this copyright statement is not    
--      removed from the file and that any derivative work contains the original copyright notice and the associated 
--      disclaimer. 
--                                                                   
--      This source file is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser 
--      General Public License as published by the Free Software Foundation; either version 2.1 of the License, or 
--      (at your option) any later version.
--                                                                   
--      This source is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--      warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more  
--      details.
--
--      You should have received a copy of the GNU Lesser General Public License along with this source; if not, download 
--      it from http://www.opencores.org/lgpl.shtml
--                                                                   
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2011/05/15   v0.10.0050  [JD]    created the slave logic, with 2 clock domains, from SPI_MASTER module.
-- 2011/05/15   v0.15.0055  [JD]    fixed logic for starting state when CPHA='1'.
-- 2011/05/17   v0.80.0049  [JD]    added explicit clock synchronization circuitry across clock boundaries.
-- 2011/05/18   v0.95.0050  [JD]    clock generation circuitry, with generators for all-rising-edge clock core.
-- 2011/06/05   v0.96.0053  [JD]    changed async clear to sync resets.
-- 2011/06/07   v0.97.0065  [JD]    added cross-clock buffers, fixed fsm async glitches.
-- 2011/06/09   v0.97.0068  [JD]    reduced control sets (resets, CE, presets) to the absolute minimum to operate, to reduce 
--                                  synthesis LUT overhead in Spartan-6 architecture.
-- 2011/06/11   v0.97.0075  [JD]    redesigned all parallel data interfacing ports, and implemented cross-clock strobe logic.
-- 2011/06/12   v0.97.0079  [JD]    implemented wren_ack and di_req logic for state 0, and eliminated unnecessary registers reset.
--
--                                                                   
-----------------------------------------------------------------------------------------------------------------------
--  TODO
--  ====
--
--
-----------------------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 
entity spi_slave is
    Generic (   
        N : positive := 32;                                             -- 32bit serial word length is default
        CPOL : std_logic := '0';                                        -- SPI mode selection (mode 0 default)
        CPHA : std_logic := '0';                                        -- CPOL = clock polarity, CPHA = clock phase.
        PREFETCH : positive := 2);                                      -- prefetch lookahead cycles
    Port (  
        clk_i : in std_logic := 'X';                                    -- internal interface clock (clocks di/do registers)
        spi_ssel_i : in std_logic := 'X';                               -- spi bus slave select line
        spi_sck_i : in std_logic := 'X';                                -- spi bus sck clock (clocks the shift register core)
        spi_mosi_i : in std_logic := 'X';                               -- spi bus mosi input
        spi_miso_o : out std_logic := 'X';                              -- spi bus spi_miso_o output
        di_req_o : out std_logic;                                       -- preload lookahead data request line
        di_i : in  std_logic_vector (N-1 downto 0) := (others => 'X');  -- parallel load data in (clocked in on rising edge of clk_i)
        wren_i : in std_logic := 'X';                                   -- user data write enable
        do_valid_o : out std_logic;                                     -- do_o data valid strobe, valid during one clk_i rising edge.
        do_o : out  std_logic_vector (N-1 downto 0);                    -- parallel output (clocked out on falling clk_i)
        --- debug ports: can be removed for the application circuit ---
        do_transfer_o : out std_logic;                                  -- debug: internal transfer driver
        wren_o : out std_logic;                                         -- debug: internal state of the wren_i pulse stretcher
        wren_ack_o : out std_logic;                                     -- debug: wren ack from state machine
        rx_bit_reg_o : out std_logic;                                   -- debug: internal rx bit
        state_dbg_o : out std_logic_vector (5 downto 0)                 -- debug: internal state register
--        sh_reg_dbg_o : out std_logic_vector (N-1 downto 0)            -- debug: internal shift register
    );                      
end spi_slave;
 
--================================================================================================================
-- this architecture is a pipelined register-transfer description.
-- the spi bus and core registers are synchronous to the 'spi_sck_i' clock.
-- the parallel write/read interface is synchronous to the 'clk_i' clock.
--================================================================================================================
architecture RTL of spi_slave is
    -- constants to control FlipFlop synthesis
    constant SAMPLE_EDGE : std_logic := (CPOL xnor CPHA);
    constant SAMPLE_LEVEL : std_logic := SAMPLE_EDGE;
    constant SHIFT_EDGE : std_logic := (CPOL xor CPHA);
    --
    -- GLOBAL RESET:
    --      all signals are initialized to zero at GSR (global set/reset) by giving explicit
    --      initialization values at declaration. This is needed for all Xilinx FPGAs, and 
    --      especially for the Spartan-6 and newer CLB architectures, where a local reset can
    --      reduce the usability of the slice registers, due to the need to share the control
    --      set (RESET/PRESET, CLOCK ENABLE and CLOCK) by all 8 registers in a slice.
    --      By using GSR for the initialization, and reducing RESET local init to the bare
    --      essential, the model achieves better LUT/FF packing and CLB usability.
    --
    -- internal state signals for register and combinational stages
    signal state_next : natural range N+1 downto 0 := 0;
    signal state_reg : natural range N+1 downto 0 := 0;
    -- shifter signals for register and combinational stages
    signal sh_next : std_logic_vector (N-1 downto 0) := (others => '0');
    signal sh_reg : std_logic_vector (N-1 downto 0) := (others => '0');
    -- input bit sampled buffer
    signal rx_bit_reg : std_logic := '0';
    -- buffered di_i data signals for register and combinational stages
    signal di_reg : std_logic_vector (N-1 downto 0) := (others => '0');
    -- internal wren_i stretcher for fsm combinational stage
    signal wren : std_logic := '0';
    signal wren_ack_next : std_logic := '0';
    signal wren_ack_reg : std_logic := '0';
    -- buffered do_o data signals for register and combinational stages
    signal do_buffer_next : std_logic_vector (N-1 downto 0)  := (others => '0');
    signal do_buffer_reg : std_logic_vector (N-1 downto 0)  := (others => '0');
    -- internal signal to flag transfer to do_buffer_reg
    signal do_transfer_next : std_logic := '0';
    signal do_transfer_reg : std_logic := '0';
    -- internal input data request signal 
    signal di_req : std_logic := '0';
    -- cross-clock do_valid_o logic
    signal do_valid_next : std_logic := '0';
    signal do_valid_A : std_logic := '0';
    signal do_valid_B : std_logic := '0';
    signal do_valid_C : std_logic := '0';
    signal do_valid_D : std_logic := '0';
    signal do_valid_o_reg : std_logic := '0';
    -- cross-clock di_req_o logic
    signal di_req_o_next : std_logic := '0';
    signal di_req_o_A : std_logic := '0';
    signal di_req_o_B : std_logic := '0';
    signal di_req_o_C : std_logic := '0';
    signal di_req_o_D : std_logic := '0';
    signal di_req_o_reg : std_logic := '0';
begin
    --=============================================================================================
    --  GENERICS CONSTRAINTS CHECKING
    --=============================================================================================
    -- minimum word width is 8 bits
    assert N >= 8
    report "Generic parameter 'N' error: SPI shift register size needs to be 8 bits minimum"
    severity FAILURE;    
    -- maximum prefetch lookahead check
    assert PREFETCH <= N-5
    report "Generic parameter 'PREFETCH' error: lookahead count out of range, needs to be N-5 maximum"
    severity FAILURE;    
 
    --=============================================================================================
    --  REGISTERED INPUTS
    --=============================================================================================
    -- rx bit flop: capture rx bit after SAMPLE edge of sck
    rx_bit_proc : process (spi_sck_i, spi_mosi_i) is
    begin
        if spi_sck_i'event and spi_sck_i = SAMPLE_EDGE then
            rx_bit_reg <= spi_mosi_i;
        end if;
    end process rx_bit_proc;
 
    --=============================================================================================
    --  RTL CORE REGISTER PROCESSES
    --=============================================================================================
    -- fsm state and data registers change on spi SHIFT clock
    core_reg_proc : process (spi_sck_i, spi_ssel_i) is
    begin
        -- FFD registers clocked on SHIFT edge and cleared on idle (spi_ssel_i = 1)
        if spi_ssel_i = '1' then                                -- async clr
            state_reg <= 0;                                     -- state falls back to idle when slave not selected
        elsif spi_sck_i'event and spi_sck_i = SHIFT_EDGE then   -- on SHIFT edge, update all core registers
            state_reg <= state_next;                            -- core fsm changes state with spi SHIFT clock
        end if;
        -- FFD registers clocked on SHIFT edge
        if spi_sck_i'event and spi_sck_i = SHIFT_EDGE then      -- on fsm state change, update all core registers
            sh_reg <= sh_next;                                  -- core shift register
            do_buffer_reg <= do_buffer_next;                    -- registered data output
            do_transfer_reg <= do_transfer_next;                -- cross-clock transfer flag
            wren_ack_reg <= wren_ack_next;                      -- wren ack for data load synchronization
        end if;
    end process core_reg_proc;
 
    --=============================================================================================
    --  CROSS-CLOCK PIPELINE TRANSFER LOGIC
    --=============================================================================================
    -- do_valid_o and di_req_o strobe output logic
    -- this is a delayed pulse generator with a ripple-transfer FFD pipeline, that generates a 
    -- fixed-length delayed pulse for the output flags, at the parallel clock domain
    out_transfer_proc : process ( clk_i, do_transfer_reg, di_req,
                                  do_valid_A, do_valid_B, do_valid_D, 
                                  di_req_o_A, di_req_o_B, di_req_o_D) is
    begin
        if clk_i'event and clk_i = '1' then                     -- clock at parallel port clock
            -- do_transfer_reg -> do_valid_o_reg
            do_valid_A <= do_transfer_reg;                      -- the input signal must be at least 2 clocks long
            do_valid_B <= do_valid_A;                           -- feed it to a ripple chain of FFDs
            do_valid_C <= do_valid_B;
            do_valid_D <= do_valid_C;
            do_valid_o_reg <= do_valid_next;                    -- registered output pulse
            --------------------------------
            -- di_req -> di_req_o_reg
            di_req_o_A <= di_req;                          -- the input signal must be at least 2 clocks long
            di_req_o_B <= di_req_o_A;                           -- feed it to a ripple chain of FFDs
            di_req_o_C <= di_req_o_B;                               
            di_req_o_D <= di_req_o_C;                               
            di_req_o_reg <= di_req_o_next;                      -- registered output pulse
        end if;
        -- generate a 2-clocks pulse at the 3rd clock cycle
        do_valid_next <= do_valid_A and do_valid_B and not do_valid_D;
        di_req_o_next <= di_req_o_A and di_req_o_B and not di_req_o_D;
    end process out_transfer_proc;
    -- parallel load input registers: data register and write enable
    in_transfer_proc: process (clk_i, wren_i, wren_ack_reg) is
    begin
        -- registered data input, input register with clock enable
        if clk_i'event and clk_i = '1' then
            if wren_i = '1' then
                di_reg <= di_i;                                 -- parallel data input buffer register
            end if;
        end  if;
        -- stretch wren pulse to be detected by spi fsm (ffd with sync preset and sync reset)
        if clk_i'event and clk_i = '1' then
            if wren_i = '1' then                                -- wren_i is the sync preset for wren
                wren <= '1';
            elsif wren_ack_reg = '1' then                       -- wren_ack is the sync reset for wren
                wren <= '0';
            end if;
        end  if;
    end process in_transfer_proc;
 
    --=============================================================================================
    --  RTL COMBINATIONAL LOGIC PROCESSES
    --=============================================================================================
    -- state and datapath combinational logic
    core_combi_proc : process ( sh_reg, state_reg, rx_bit_reg, do_buffer_reg, 
                                do_transfer_reg, di_reg, wren, wren_ack_reg) is
    begin
        sh_next <= sh_reg;                                              -- all output signals are assigned to (avoid latches)
        do_buffer_next <= do_buffer_reg;                                -- output data buffer
        do_transfer_next <= do_transfer_reg;                            -- output data flag
        wren_ack_next <= '0';                                           -- remove data load ack for all but the load stages
        di_req <= '0';                                                  -- prefetch data request: deassert when shifting data
        spi_miso_o <= sh_reg(N-1);                                      -- output serial data from the MSb
        state_next <= state_reg - 1;                                    -- update next state at each sck pulse
        case state_reg is
            when (N) =>
                do_transfer_next <= '0';                                -- reset transfer signal
                sh_next(N-1 downto 1) <= sh_reg(N-2 downto 0);          -- shift inner bits
                sh_next(0) <= rx_bit_reg;                               -- shift in rx bit into LSb
            when (N-1) downto (PREFETCH+3) =>
                do_transfer_next <= '0';                                -- reset transfer signal
                sh_next(N-1 downto 1) <= sh_reg(N-2 downto 0);          -- shift inner bits
                sh_next(0) <= rx_bit_reg;                               -- shift in rx bit into LSb
            when (PREFETCH+2) downto 2 =>
                -- raise data prefetch request
                di_req <= '1';                                          -- request data in advance to allow for pipeline delays
                sh_next(N-1 downto 1) <= sh_reg(N-2 downto 0);          -- shift inner bits
                sh_next(0) <= rx_bit_reg;                               -- shift in rx bit into LSb
            when 1 =>
                -- restart from state 'N' if more sck pulses come
                di_req <= '1';                                          -- request data in advance to allow for pipeline delays
                do_buffer_next(N-1 downto 1) <= sh_reg(N-2 downto 0);   -- shift rx data directly into rx buffer
                do_buffer_next(0) <= rx_bit_reg;                        -- shift last rx bit into rx buffer
                do_transfer_next <= '1';                                -- signal transfer to do_buffer
                state_next <= N;                                        -- next state is top bit of new data
                if wren = '1' then                                      -- load tx register if valid data present at di_reg
                    sh_next <= di_reg;                                  -- load parallel data from di_reg into shifter
                    wren_ack_next <= '1';                               -- acknowledge data in transfer
                else
                    sh_next <= (others => '0');                         -- load null data (output '0' if no load)
                end if;
            when 0 =>
                di_req <= not wren_ack_reg;                             -- will request data if shifter empty
                do_transfer_next <= '0';                                -- clear signal transfer to do_buffer
                spi_miso_o <= di_reg(N-1);                              -- shift out first tx bit from the MSb
                if CPHA = '0' then
                    -- initial state for CPHA=0, when slave interface is first selected or idle
                    state_next <= N-1;                                  -- next state is top bit of new data
                    sh_next(0) <= rx_bit_reg;                           -- shift in rx bit into LSb
                    sh_next(N-1 downto 1) <= di_reg(N-2 downto 0);      -- shift inner bits
                    wren_ack_next <= '1';                               -- acknowledge data in transfer
                else
                    -- initial state for CPHA=1, when slave interface is first selected or idle
                    state_next <= N;                                    -- next state is top bit of new data
                    sh_next <= di_reg;                                  -- load parallel data from di_reg into shifter
                end if;
            when others =>
                state_next <= 0;                                        -- state 0 is safe state
        end case; 
    end process core_combi_proc;
 
    --=============================================================================================
    --  RTL OUTPUT LOGIC PROCESSES
    --=============================================================================================
    -- data output processes
    do_o_proc :         do_o <= do_buffer_reg;                              -- do_o always available
    do_valid_o_proc:    do_valid_o <= do_valid_o_reg;                       -- copy registered do_valid_o to output
    di_req_o_proc:      di_req_o <= di_req_o_reg;                           -- copy registered di_req_o to output
 
    --=============================================================================================
    --  DEBUG LOGIC PROCESSES
    --=============================================================================================
    -- these signals are useful for verification, and can be deleted or commented-out after debug.
    do_transfer_proc:   do_transfer_o <= do_transfer_reg;
    state_debug_proc:   state_dbg_o <= std_logic_vector(to_unsigned(state_reg, 6)); -- export internal state to debug
    rx_bit_reg_proc:    rx_bit_reg_o <= rx_bit_reg;
    wren_o_proc:        wren_o <= wren;
    wren_ack_o_proc:    wren_ack_o <= wren_ack_reg;
--    sh_reg_debug_proc:  sh_reg_dbg_o <= sh_reg;                                   -- export sh_reg to debug
end architecture RTL;
