-- Copyright GMicro UFSM 2020.
-- This source describes Open Hardware and is licensed under the CERN-OHLS v2
-- You may redistribute and modify this documentation and make products
-- using it under the terms of the CERN-OHL-S v2 (https:/cern.ch/cern-ohl).
-- This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED
-- WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
-- AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2
-- for applicable conditions.
-- Source location: https://github.com/vctrop/shapelet_distance_hardware_accelerator
-- As per CERN-OHL-S v2 section 4, should You produce hardware based on
-- these sources, You must maintain the Source Location visible on any
-- product you make using this documentation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mux is
end entity;

architecture test of tb_mux is

    signal clk : std_logic := '0';
    signal rst : std_logic;
    signal sel : natural range 0 to 3;
    signal data : std_Logic_vector(31 downto 0);
    signal wr_en : natural range 0 to 12;
    signal fromMEM, wb : std_logic;

begin
    DUV: entity work.generic_mux 
    generic map(
        LEN_MAX => 12,        -- length of the shapelet buffer
        NUM_PE  => 4         -- number of processing units
    )
    port map(
        clk => clk,
        rst => rst,
        data_i => data,
        address => wr_en,
        fromMEM => fromMEM,
        wb_i => wb,
        sel_i => sel
    );

    rst <= '1', '0' after 15 ns;
    clk <= not clk after 5 ns;

    process
    variable i : natural range 0 to 12;
    begin
        fromMEM <= '1';
        wr_en <= 0;
        wb <= '0';
        wait until rst = '0';
        
        while(i < 12) loop
            data <= std_logic_vector(to_unsigned(i, data'length));
            wr_en <= i;
            wait for 10 ns;
            i := i + 1;
        end loop;
        fromMEM <= '0';
        wait for 100 ns;
        sel <= 0;
        wb <= '1';
        wait for 10 ns;
        sel <= 1;
        wait for 10 ns;
        sel <= 2;
        sel <= 0;
        wb <= '1';
        wait for 10 ns;
        sel <= 1;
        wait for 10 ns;
        sel <= 2;
        sel <= 0;
        wb <= '1';
        wait for 10 ns;
        sel <= 1;
        wait for 10 ns;
        sel <= 2;
        wait;
    end process;
end test ; -- test