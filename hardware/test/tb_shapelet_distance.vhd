library IEEE;
use IEEE.numeric_std.all;
use ieee.std_logic_1164.all;

use std.textio.all;
use work.test_pkg.all;


entity tb_shapelet_distance is
end tb_shapelet_distance;

architecture behavioral of tb_shapelet_distance is

    component shapelet_distance is
        generic (
            NUM_PU      : natural;
            MAX_LEN     : natural
        );
        port (
            clk         : in std_logic;
            rst         : in std_logic;
            
            -- Operation
            -- '0': set shapelet LENGTH and  change the pivot shapelet and normalize it
            -- '1': change target shapelet and compute distance
            op_i        : in std_logic;
            
            -- Data input is a single precision float shapelet datapoint
            data_i      : in std_logic_vector(31 downto 0);
            --length_i    : in std_logic_vector(6 downto 0);
    
            -- begins opeartions
            start_i     : in std_logic;        
            -- Ready flag for operation completion
            ready_o     : out std_logic;
            --distance result
            distance_o  : out std_logic_vector(31 downto 0);
             
            -- invalid length signal
            invalid_length_o : out std_logic
        );
    end component;
    
    constant half_clk_period : time := 8 ns;
    constant clK_period : time := 2*half_clk_period;

    -- generic constants
    constant NUM_PU : integer := 4;
    constant MAX_LEN : integer := 16;

    file testFile : TEXT open READ_MODE is "test/debug_vector.txt";
    -- 1 line for integer length 
	-- 1 line for pivot shapelet 32-bit float values, separated by 1 character
	-- 1 line for target shapelet 32-bit float values, separated by 1 character
	-- 1 line for expected output 32-bit float distance
	-- all values must be in hexadecimal, each with 8 characters of length. eg.: 00000004
	file outFile : text open write_mode is "output_file.txt"; --output file contains the number of the test and the distance found for each input followed by the expected output, one per line.
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal start, ready, op, invalid_length : std_logic;
    signal data, distance, expected_output : std_logic_vector(31 downto 0);
    signal index : natural;

begin
    clk <= not clk after half_clk_period;
    rst <= '0' after 5*clk_period;  -- wait 1 clk cycles before starting simulation

    
    DUV: shapelet_distance
        generic map(
            NUM_PU      => NUM_PU,
            MAX_LEN     => MAX_LEN
        )
        port map(
            clk         => clk,
            rst         => rst,
            
            -- Operation
            -- '0': set shapelet LENGTH and  change the pivot shapelet and normalize it
            -- '1': change target shapelet and compute distance
            op_i        => op,
            
            -- Data input is a single precision float shapelet datapoint
            data_i      => data,
    
            -- begins opeartions
            start_i     => start,      
            -- Ready flag for operation completion
            ready_o     => ready,
            --distance result
            distance_o  => distance,
            
            invalid_length_o => invalid_length
        );

    process
        variable fileLine	        : line;				-- Stores a read line from a text file
        variable str 		        : string(1 to 8);	-- Stores an 8 characters string
        variable char		        : character;		-- Stores a single character
        variable bool		        : boolean;	
		variable row                : line;				-- Output file line
 		variable length	            : integer;
        variable current_minimum    : std_logic_vector(31 downto 0);
		variable l_v                : std_logic_vector(31 downto 0);
    begin
		op <= '0';
		start <= '0';
        index <= 0;
        --wait until rst = '1'; -- wait for the circuit to be reset
        wait until rst = '0'; -- wait for the circuit to be reset
		--wait until clk = '0'; -- synchronize with clk
		--wait for half_clk_period;
        -- read all lines in the test file
        while not (endfile(testFile)) loop
            -- Pivot normalization 
            -- read the line containing length
            readline(testFile, fileLine);   
            for i in str'range loop
                read(fileLine, char, bool);
                str(i) := char;
            end loop;
			l_v := StringToStdLogicVector(str);
            data <= l_v;
			length := to_integer(unsigned(l_v));
			report "length: " & integer'image(length);
            --assert length > 0 report "Incompatible length < 0 !" severity warning;

            -- Start normalization
            start <= '1';
            op <= '0';
            wait for clk_period;

            -- if the input length was invalid, retry it
            while invalid_length = '1' loop
                readline(testFile, fileLine);   
                for i in str'range loop
                    read(fileLine, char, bool);
                    str(i) := char;
                end loop;
                l_v := StringToStdLogicVector(str);
                data <= l_v;
                length := to_integer(unsigned(l_v));
                report "length: " & integer'image(length);
                wait for clk_period;
            end loop;


            start <= '0';

            report "loading values";

            -- load pivot values
            readline(testFile, fileLine);
            for i in 0 to length-1 loop

                for i in str'range  loop
                    read(fileLine, char, bool);
                    str(i) := char;
                end loop;
                data <= StringToStdLogicVector(str);

                read(fileLine, char, bool); -- read the space separating the values

                wait for clk_period;
            end loop;
			report "waiting for normalization";

            wait until ready = '1';
			wait for clk_period;
			wait for clk_period;
            
            ---- 1st TARGET
            -- Read the line containing current minimum distance
            readline(testFile, fileLine);   
            for i in str'range loop
                read(fileLine, char, bool);
                str(i) := char;
            end loop;
            data <= StringToStdLogicVector(str);          
            
            start <= '1';
            op <= '1';
            wait for clk_period;
            start <= '0';
            
            -- Read target shapelet
            readline(testFile, fileLine);
            for i in 0 to length-1 loop
                for i in str'range  loop
                    read(fileLine, char, bool);
                    str(i) := char;
                end loop;
                data <= StringToStdLogicVector(str);

                read(fileLine, char, bool); -- read the space separating the values
                wait for clk_period;
            end loop;

            wait until ready = '1';

            -- Read expected output
            readline(testFile, fileLine);
            for i in str'range loop
                read(fileLine, char, bool);
                str(i) := char;
            end loop;
            expected_output <= StringToStdLogicVector(str);

            report "shapelet " & natural'image(index) & " has output " & integer'image(to_integer(unsigned(distance))) & "expected " & integer'image(to_integer(unsigned(expected_output)));
            index <= index + 1;
			wait for clk_period;
			wait for clk_period;
            
            ---- 2nd TARGET
            -- Read the line containing current minimum distance
            readline(testFile, fileLine);   
            for i in str'range loop
                read(fileLine, char, bool);
                str(i) := char;
            end loop;
            data <= StringToStdLogicVector(str);          
            
            start <= '1';
            op <= '1';
            wait for clk_period;
            start <= '0';
            
            -- Read target shapelet
            readline(testFile, fileLine);
            for i in 0 to length-1 loop
                for i in str'range  loop
                    read(fileLine, char, bool);
                    str(i) := char;
                end loop;
                data <= StringToStdLogicVector(str);

                read(fileLine, char, bool); -- read the space separating the values
                wait for clk_period;
            end loop;

            wait until ready = '1';

            -- Read expected output
            readline(testFile, fileLine);
            for i in str'range loop
                read(fileLine, char, bool);
                str(i) := char;
            end loop;
            expected_output <= StringToStdLogicVector(str);

            report "shapelet " & natural'image(index) & " has output " & integer'image(to_integer(unsigned(distance))) & "expected " & integer'image(to_integer(unsigned(expected_output)));
            index <= index + 1;
			wait for clk_period;
			wait for clk_period;
            
            ---- 3rd TARGET
            -- Read the line containing current minimum distance
            readline(testFile, fileLine);   
            for i in str'range loop
                read(fileLine, char, bool);
                str(i) := char;
            end loop;
            data <= StringToStdLogicVector(str);          
            
            start <= '1';
            op <= '1';
            wait for clk_period;
            start <= '0';
            
            -- Read target shapelet
            readline(testFile, fileLine);
            for i in 0 to length-1 loop
                for i in str'range  loop
                    read(fileLine, char, bool);
                    str(i) := char;
                end loop;
                data <= StringToStdLogicVector(str);

                read(fileLine, char, bool); -- read the space separating the values
                wait for clk_period;
            end loop;

            wait until ready = '1';

            -- Read expected output
            readline(testFile, fileLine);
            for i in str'range loop
                read(fileLine, char, bool);
                str(i) := char;
            end loop;
            expected_output <= StringToStdLogicVector(str);

            report "shapelet " & natural'image(index) & " has output " & integer'image(to_integer(unsigned(distance))) & "expected " & integer'image(to_integer(unsigned(expected_output)));
            index <= index + 1;
			wait for clk_period;
			wait for clk_period;
			

            
            
            -- write to output file:
            -- write(row, index, right, 9);
			-- write(row, slv_to_hexstr(distance), right, 9); -- transform distance to string
			-- write(row, str, right, 9);	-- expected output in string format
			-- writeLine(outFile, row);
        end loop;
        wait;
    end process;
end behavioral ; -- behavioral

