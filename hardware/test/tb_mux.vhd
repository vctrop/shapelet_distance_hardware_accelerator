library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mux is
end entity;

architecture test of tb_mux is

    signal clk : std_logic := '0';
    signal rst : std_logic;
    signal sel : natural range 0 to 3;

begin
    DUV: entity work.generic_mux 
    generic map(
        LEN_MAX => 64,        -- length of the shapelet buffer
        NUM_PE  => 8         -- number of processing units
    )
    port map(
        clk => clk,
        rst => rst,
        sel_i => sel
    );

    rst <= '1', '0' after 15 ns;
    clk <= not clk after 10 ns;

    process
    begin
        sel <= 0;
        wait for 10 ns;
        sel <= 1;
        wait for 10 ns;
        sel <= 2;
        wait for 10 ns;
        sel <= 3;
    end process;
end test ; -- test