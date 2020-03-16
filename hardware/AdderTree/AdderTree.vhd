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
-- TODO        : Check for uneven number of input and any implications
--               Break math_real dependence (ceil() and log2())
--               Make sure waiting for Start falling edge is compatible with shapelet_distance control block
--------------------------------------------------------------------------------


library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;

library work;
	use work.AdderTreePKG.all;

entity AdderTree is

	generic (
		AmountOfInputs : integer;
		AdderAmountOfCycles: integer := 6
	);

	port(
		Clock  : in std_logic;
		Reset  : in std_logic;

		Inputs : in slv_vector;  -- Type declaration must be done in a separate pkg, yet to be implemented
		Start  : in std_logic;
		Output : out std_logic_vector(31 downto 0);  -- IEEE 754 Single Precision
		Ready  : out std_logic
	);
	
end entity AdderTree;


architecture RTL of AdderTree is

	-- Amount of adders to be instantiated. Half as many inputs, accounting for an uneven number of inputs
	constant AmountOfAdders: integer := integer(ceil(real(AmountOfInputs)/real(2)));

	signal inputRegisters: slv_vector(0 to AmountOfInputs - 1);               -- Array of registers. Receives Input values when Start is set to '1'
	signal adderOutputs: slv_vector(0 to AmountOfAdders - 1);                 -- Combinational output of adders, input to Output registers            
    signal initialized: std_logic;                                            
    
	-- Amount of clock cycles in an iteration
	signal cycleCounter: integer range 0 to AdderAmountOfCycles - 1;

	-- Amount of iterations (amount of times adder outputs will be fed back into inputs - 1 first iteration, where there is no feedback)
	constant AmountOfIterations: integer := integer(ceil(log2(real(AmountOfInputs))));
	constant LastIteration: integer := AmountOfIterations - 1;
	signal iterationsCounter: integer range 0 to AmountOfIterations - 1;

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
	AdderGen: for i in 0 to AmountOfAdders - 1 generate

		-- FPU100 adder
		ADDER: entity work.fp_addsub

			port map(
				clk_i => Clock,
		        op_type => '0',       -- 0 => Addition

		        -- Input Operands A & B
		        opa_i => inputRegisters(2*i),
		        opb_i => inputRegisters(2*i + 1),
		        
		        -- Output port
		        output_o => adderOutputs(i),
		        
		        -- Exception flags
		        ine_o => open,        -- Inexact flag
		        overflow_o => open,   -- Overflow flag
		        underflow_o => open,  -- Underflow flag
		        inf_o => open,        -- Infinity flag
		        zero_o => open,       -- Zero flag
		        qnan_o => open,       -- Quiet Not-a-Number flag
		        snan_o => open        -- Signaling Not-a-Number flag
			);

	end generate AdderGen;


	-- Handles writes to input registers and feeding back of results of previous iteration
	ControlProc: process(Clock, Reset) begin

		if rising_edge(Clock) then

			if Reset = '1' then
				initialized <= '0';
				Ready <= '0';
				cycleCounter <= 0;
				inputRegisters <= (others => (others => '0'));

			elsif Start = '1' then
				initialized <= '1';
				inputRegisters <= Inputs;

			-- Checks if adder tree is not idling. Only begins operation on next falling edge of Start
			-- TODO: Make sure this (waiting for Start falling edge) is compatible with shapelet_distance control block
			elsif Start = '0' and initialized = '1' then  

				cycleCounter <= incr(cycleCounter, AdderAmountOfCycles, 0);  -- cycleCounter++

				-- Checks if this is the last cycle of an iteration (Amount of adder cycles + 1 cycle for writing to output register)
				if cycleCounter = AdderAmountOfCycles then 

					iterationsCounter <= incr(iterationsCounter, LastIteration, 0);  -- iterationsCounter++

					-- Checks if this is the last cycle of the last iteration
					if iterationsCounter = LastIteration then

						-- Signal final sum is ready. Will wait for next Start = '1'
						Ready <= '1';
						initialized <= '0';
						Output <= adderOutputs(0);

					else  -- Not the last iteration

						-- Feeds back result of previous iteration into adders
						for i in 0 to (AmountOfAdders - 2*(iterationsCounter)) - 1 loop

							inputRegisters(i) <= adderOutputs(i);

						end loop;

					end if;

				end if;

			end if;

		end if;

	end process ControlProc;


end architecture RTL;