--------------------------------------------------------------------------------
-- Project     : Shapelet Distance Hardware Acceletator
--------------------------------------------------------------------------------
-- Description : Adder Tree
--               Adds a given number of inputs in IEEE 754 single precision format
--               Amount of FP adders instantiated is half of amount of inputs
--               Used algorithm is iterative, feeding back into the FP adders results from previous iterations 
--------------------------------------------------------------------------------
-- File        : AdderTree.vhd
-- Authors     : Carlos Gewehr (carlos.gewehr@ecomp.ufsm.br)
--               Julio Vicenzi (julio.vicenzi@ecomp.ufsm.br)
--               Victor Costa  (victor.costa@ecomp.ufsm.br)
-- Standard    : VHDL-1993 
--------------------------------------------------------------------------------
-- Changelog   : v0.01 - Initial implementation
--------------------------------------------------------------------------------
-- TODO        : Break math_real dependence (ceil() and log2())
--               Make sure waiting for start_i falling edge is compatible with shapelet_distance control block
--               Make sure use of "mod 2" operations and integer types are synthesis safe
--------------------------------------------------------------------------------


library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
    use ieee.math_real.all;         -- Synthesizable, only used with generics 

use work.array_pkg.all;
    
entity adder_tree is

	generic (
		NUM_INPUTS : integer;                   -- Number of single precision floating point values to sum
		ADDER_NUM_CYCLES: integer := 6          -- Number of cycles the base adder takes to complete a single sum
	);

	port(
		clk         : in std_logic;
		rst         : in std_logic;

		operands_i  : in slv_array_t(0 to NUM_INPUTS - 1);
		start_i     : in std_logic;
        
		sum_o       : out std_logic_vector(31 downto 0);  -- IEEE 754 Single Precision
		ready_o     : out std_logic
	);
	
end entity adder_tree;


architecture RTL of adder_tree is
    
	-- Amount of adders to be instantiated. Half as many inputs, accounting for an uneven number of inputs
	constant num_adders_c               : integer := integer(floor(real(NUM_INPUTS)/real(2)));
	constant num_inputs_uneven_c        : integer := NUM_INPUTS mod 2;
    
    signal reg_initialized_s          : std_logic;                                            
	signal reg_inputs_s               : slv_array_t(0 to NUM_INPUTS - 1);               -- Array of registers. Receives Input values when start_i is set to '1'
	--signal reg_inputs_s               : slv_array_t(0 to 2*num_adders_c - 1);             -- Array of registers. Receives Input values when start_i is set to '1'
	signal adder_outputs_s            : slv_array_t(0 to num_adders_c - 1);               -- Combinational output of adders, input to sum_o registers            
    
	-- Amount of clock cycles in an iteration
	signal reg_cycle_counter_s        : integer range 0 to ADDER_NUM_CYCLES;

	-- Amount of iterations (amount of times adder outputs will be fed back into inputs - 1 first iteration, where there is no feedback)
	constant num_iterations_c           : integer := integer(ceil(log2(real(NUM_INPUTS))));
	constant last_iteration_c            : integer := num_iterations_c - 1;
	signal reg_iterations_counter_s   : integer range 0 to num_iterations_c - 1;
	
	signal reg_num_writebacks_s : integer;
	signal uneven_leftover_used_flag  : std_logic;

	-- Simple increment and wrap around. Used to increment amount of cycles in iteration and total number of iterations
    function incr(value: integer ; maxValue: integer ; minValue: integer) return integer is

    begin

        if value = maxValue then
            return minValue;

        else
            return value + 1;

        end if;

    end function incr;

begin

	-- Generates IEEE 754 single precision adders
	AdderGen: for i in 0 to num_adders_c - 1 generate

        -- FPU100 adder
        ADDER: entity work.fp_addsub

            port map(
                clk_i       => clk,
                op_type     => '0',       -- 0 => Addition

                -- Input Operands A & B
                opa_i       => reg_inputs_s(2*i),
                opb_i       => reg_inputs_s(2*i + 1),
                
                -- sum_o port
                output_o    => adder_outputs_s(i),
                
                -- Exception flags
                ine_o       => open,        -- Inexact flag
                overflow_o  => open,        -- Overflow flag
                underflow_o => open,        -- Underflow flag
                inf_o       => open,        -- Infinity flag
                zero_o      => open,        -- Zero flag
                qnan_o      => open,        -- Quiet Not-a-Number flag
                snan_o      => open         -- Signaling Not-a-Number flag
            );

	end generate AdderGen;


	-- Handles writes to input registers and feeding back of results of previous iteration
	ControlProc: process(clk, rst) begin

		if rising_edge(clk) then

			if rst = '1' then
				reg_initialized_s <= '0';
				reg_cycle_counter_s <= 0;
				reg_iterations_counter_s <= 0;
				reg_inputs_s <= (others => (others => '0'));
				reg_num_writebacks_s <= num_adders_c;
				uneven_leftover_used_flag <= '0';

			elsif start_i = '1' and reg_initialized_s = '0' then
				reg_initialized_s <= '1';
				reg_inputs_s <= operands_i;

			-- Checks if adder tree is not idling. Only begins operation on next falling edge of start_i
			-- TODO: Make sure this (waiting for start_i falling edge) is compatible with shapelet_distance control block
			elsif reg_initialized_s = '1' then  

				reg_cycle_counter_s <= incr(reg_cycle_counter_s, ADDER_NUM_CYCLES, 0);  -- reg_cycle_counter_s++

				-- Checks if this is the last cycle of an iteration (Amount of adder cycles + 1 cycle for writing to output register)
				if reg_cycle_counter_s = ADDER_NUM_CYCLES then 

					reg_iterations_counter_s <= incr(reg_iterations_counter_s, last_iteration_c, 0);  -- reg_iterations_counter_s++

					-- Checks if this is the last cycle of the last iteration
					if reg_iterations_counter_s = last_iteration_c then

						-- Signal final sum is ready. Will wait for next start_i = '1'
						reg_initialized_s <= '0';
						reg_num_writebacks_s <= num_adders_c;

					else  -- Not the last iteration

						-- Feeds back result of previous iteration into adders
						for i in 0 to reg_num_writebacks_s - 1 loop
							reg_inputs_s(i) <= adder_outputs_s(i);
						end loop;
						
						-- Handles leftover inputs, if there is an uneven number of inputs or operands in current iteration
						if reg_num_writebacks_s mod 2 = 1 and num_inputs_uneven_c = 1 and uneven_leftover_used_flag = '0' then
						    reg_inputs_s(reg_num_writebacks_s) <= reg_inputs_s(NUM_INPUTS - 1);
						    uneven_leftover_used_flag <= '1';
						elsif reg_num_writebacks_s mod 2 = 1 then
						    reg_inputs_s(reg_num_writebacks_s) <= (others =>'0');
						end if; 
						
						-- Sets amount of writebacks to occur in next iteration. 
						reg_num_writebacks_s <= reg_num_writebacks_s/2 + reg_num_writebacks_s mod 2;

					end if;

				end if;

			end if;

		end if;

	end process ControlProc;

    sum_o <= adder_outputs_s(0);
    ready_o <=  '1' when reg_cycle_counter_s = ADDER_NUM_CYCLES and reg_iterations_counter_s = last_iteration_c else
                '0';
    
end architecture RTL;
