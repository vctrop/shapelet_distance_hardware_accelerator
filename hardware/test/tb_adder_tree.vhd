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
	use ieee.math_real.all;

library work;
	use work.array_pkg.all;

entity tb_adder_tree is

end entity tb_adder_tree;

architecture TB of tb_adder_tree is

	constant num_inputs: integer := 10;
	constant adder_num_cycles: integer := 6;

	constant clockPeriod: time := 10 ns ;
    constant clockHalfPeriod: time := clockPeriod/2;
 
    signal Clock, Reset, Start, Ready : std_logic;
	signal Inputs: slv_array_t(0 to num_inputs - 1);
	signal Output: std_logic_vector(31 downto 0);
	
	function uint_to_fp(int_i: std_logic_vector(31 downto 0)) return std_logic_vector is
            -- the position of the first '1' bit is also the value we must add to the exponent
            variable shift_num_s: natural range 0 to 23;
            variable mantissa_s, fp_o:  std_logic_vector(31 downto 0);
        begin
            fp_o(31) := '0';        -- sign bit '0': all integers must be positive
        
            -- priority decoder to find the position of the first '1' bit
            if    int_i(23) = '1' then shift_num_s := 23;
            elsif int_i(22) = '1' then shift_num_s := 22;
            elsif int_i(21) = '1' then shift_num_s := 21;
            elsif int_i(20) = '1' then shift_num_s := 20;
            elsif int_i(19) = '1' then shift_num_s := 19;
            elsif int_i(18) = '1' then shift_num_s := 18;
            elsif int_i(17) = '1' then shift_num_s := 17;
            elsif int_i(16) = '1' then shift_num_s := 16;
            elsif int_i(15) = '1' then shift_num_s := 15;
            elsif int_i(14) = '1' then shift_num_s := 14;
            elsif int_i(13) = '1' then shift_num_s := 13;
            elsif int_i(12) = '1' then shift_num_s := 12;
            elsif int_i(11) = '1' then shift_num_s := 11;
            elsif int_i(10) = '1' then shift_num_s := 10;
            elsif int_i(9)  = '1' then shift_num_s := 9;
            elsif int_i(8)  = '1' then shift_num_s := 8;
            elsif int_i(7)  = '1' then shift_num_s := 7;
            elsif int_i(6)  = '1' then shift_num_s := 6;
            elsif int_i(5)  = '1' then shift_num_s := 5;
            elsif int_i(4)  = '1' then shift_num_s := 4;
            elsif int_i(3)  = '1' then shift_num_s := 3;
            elsif int_i(2)  = '1' then shift_num_s := 2;
            elsif int_i(1)  = '1' then shift_num_s := 1;
            else                       shift_num_s := 0;
            end if;
        
            -- add bias to the exponent
            if int_i /= x"00000000" then
                fp_o(30 downto 23) := std_logic_vector(to_unsigned(shift_num_s + 127, 8));
            else
                fp_o(30 downto 23) := x"00";  --if the input is zero, we have all zeroes
            end if;

            -- mantissa contains all bits except the first
            -- we first zero the first '1' in the input number
            -- and then we rotate it shift_num_s times to the right
            mantissa_s := std_logic_vector(unsigned(int_i) ror shift_num_s); -- we cannot slice this due to conversion
            fp_o(22 downto 0) := mantissa_s(31 downto 9);    -- slice to get the actual mantissa value

            return fp_o;
            
        end function;

begin

	-- Instantiate component
	DUV: entity work.adder_tree

		generic map(
			NUM_INPUTS => num_inputs,
			ADDER_NUM_CYCLES => adder_num_cycles
		)

		port map(
			clk       => Clock,
			rst       => Reset,
                   
			operands_i  => Inputs,
			start_i     => Start,
			
            sum_o       => Output,
			ready_o     => Ready
		);


	-- Generates clock signal
    ClockProcess: process begin

    	Clock <= '0';
        wait for clockHalfPeriod;
        Clock <= '1';
        wait for clockHalfPeriod;

    end process ClockProcess;


    -- Generates stimulus to DUV
    StimProcess: process

    begin

    	-- Set default values 
    	Inputs <= (others=>(others=>'0'));
    	Start <= '0';

    	-- Hold default values for a set time. Sets inputs at falling edges
    	Reset <= '1';
    	wait for (clockPeriod * 10) + clockHalfPeriod; 
    	Reset <= '0';

    	-- Generate inputs
    	for i in 0 to num_inputs - 1 loop

    		Inputs(i) <= uint_to_fp(std_logic_vector(to_unsigned(i, 32)));

    	end loop;

    	-- Begin sum of inputs
    	Start <= '1';
    	wait for clockPeriod;
    	Start <= '0';

    	-- Waits for final sum to end and end simulation
    	wait until Ready = '1';
    	wait for clockPeriod;
    	wait;

    end process StimProcess;
	
end architecture TB;