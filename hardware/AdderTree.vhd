--------------------------------------------------------------------------------
-- Project     : Shapelet Distance Hardware Acceletator
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
--               Make pkg containing input type declaration
--               Why are dual and single path adders the same?
--               
--------------------------------------------------------------------------------


library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.log2;

entity AdderTree is

	generic (
		AmountOfInputs : integer;
		UseDualPath: boolean
	);

	port(

		Clock : in std_logic;
		Reset : in std_logic;

		Inputs : in inputArray(0 to AmountOfInputs - 1);  -- type declaraion must me done in a pkg, yet to be implemented
		Output : out std_logic_vector(33 downto 0)  -- flopoco ieee-like is 34 bits wide 

	);
	
end entity AdderTree;


architecture RTL of AdderTree is

	constant AmountOfLevels: ceil(log2(real(AmountOfInputs)));

	type Operands_t is array(0 to AmountOfLevels, 0 to AmountOfInputs - 1) of std_logic_vector(33 downto 0); 
	signal Operands: Operands_t;

	type integer_vector is array(natural range <>) of integer;
	signal AmountOfAddersInLevel: integer_vector(0 to AmountOfLevels - 1);

begin
	
	-- Sets 0 index operands to entity inputs
	SETOPERANDS: for i in 0 to AmountOfInputs - 1 generate

		Operands(0, i) <= Inputs(i);

	end generate SETOPERANDS;


	-- Determines how many adders will be intantiated at each level
	-- MIGHT NOT BE READY AT ELAB TIME WITH CURRENT IMPLEMENTATION
	SETADDERSINLEVEL: for i in AmountOfLevels - 1 generate

		if i = 0 generate

			AmountOfAddersInLevel(0) = ceil(AmountOfInputs/2);

		end generate;

		if i > 0 generate

			AmountOfAddersInLevel(i) = ceil(AmountOfAddersInLevel(i - 1)/2);

		end generate;

	end generate SETADDERSINLEVEL;


	-- Instantiate flopoco FP adders 
    LEVELSGEN: for level in 0 to AmountOfLevels - 1 generate

    	INSTANCESGEN: for j in 0 to AmountOfAddersInLevel(level) generate

    		-- Instantiate dual path adder
    		DUALPATHGEN: if UseDualPath generate

    			FPADDER: entity work.FPAdd_8_23_F400_uid2

    				port map(
	    				clk => Clock,
	    				rst => Reset,
	    				X => Operands(level, j * 2),
	    				Y => Operands(level, (j * 2) + 1),
	    				R => Operands(level + 1, j)
	    			);

    		end generate DUALPATHGEN;

    		-- Instantiate single path adder
    		SINGLEPATHGEN: if not UseDualPath generate

	    		FPADDER: entity work.FPAdd_8_23_F400_uid2

	    			port map(
	    				clk => Clock,
	    				rst => Reset,
	    				X => Operands(level, j * 2),
	    				Y => Operands(level, (j * 2) + 1),
	    				R => Operands(level + 1, j)
	    			);

	    	end generate SINGLEPATHGEN;

    	end generate INSTANCESGEN;
		
	end generate LEVELSGEN;

	Output => Operands(AmountOfLevels, 0);

end architecture RTL;