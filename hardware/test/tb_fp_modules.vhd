
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_misc.all;
    use ieee.math_real.all;
    use ieee.float_pkg.all;

--library ieee_proposed;
--    use ieee_proposed.float_pkg.all;
--    use ieee_proposed.math_real.all;

library std;
    use std.textio.all;
   
--library work;
--    use work.float_pkg.all;
    
entity tb_fp_modules is 
end tb_fp_modules;

architecture testbench of tb_fp_modules is

    -- Core to be instantiated
    constant coreType: string(1 to 3) := "ADD"; -- "ADD", "MUL", "DIV", "SQR", "ROO"
    constant adderType: string(1 to 3) := "SGL"; -- "SGL", "DUA"
    
    -- Stimulus file
    file stimulusFile: text open read_mode is "stimulus.txt";

    -- Clock signals
    signal clock: std_logic := '0';
    constant clockPeriod: time := 10 ns ;
    constant clockHalfPeriod: time := clockPeriod/2;
    
    -- Operands and flags
    signal start, opType, ine, overflow, underflow, inf, zero, qnan, snan, div_zero: std_logic;
    signal opa, opb, result: std_logic_vector(31 downto 0);
    signal time_to_compute: integer;

    -- IEEE to flopoco
    signal IEEEToFlopocoInA, IEEEToFlopocoInB: std_logic_vector(31 downto 0);
    signal IEEEToFlopocoOutA, IEEEToFlopocoOutB: std_logic_vector(33 downto 0);

    -- Flopoco to IEEE
    signal FlopocoToIEEEIn: std_logic_vector(33 downto 0);
    signal FlopocoToIEEEOut: std_logic_vector(31 downto 0); 

    -- Clock Counter
    signal clockCounter: integer := 0;

begin

    -- Generates clock square wave
    ClockProcess: process begin

        wait for clockHalfPeriod;
        Clock <= '1';
        wait for clockHalfPeriod;
        Clock <= '0';

    end process ClockProcess;


    -- Generates flopoco to IEEE 754 single precision format converter
    FlopocoToIEEE: entity work.OutputIEEE_8_23_to_8_23
        port map(
            clk => open,
            rst => open,
            X => FlopocoToIEEEIn,
            R => FlopocoToIEEEOut
        ); 


    -- Generates IEEE 754 single precision to flopoco format converter
    IEEEToFlopocoA: entity work.InputIEEE_8_23_to_8_23
        port map(
            clk => open,
            rst => open,
            X => IEEEToFlopocoInA,
            R => IEEEToFlopocoOutA
        );


    -- Generates IEEE 754 single precision to flopoco format converter
    IEEEToFlopocoB: entity work.InputIEEE_8_23_to_8_23
        port map(
            clk => open,
            rst => open,
            X => IEEEToFlopocoInB,
            R => IEEEToFlopocoOutB
        );


    -- Generate adder
    ADDERGEN: if coreType = "ADD" generate


        -- Generates single path adder (Less area, more latency)
        SINGLEPATHGEN: if adderType = "SGL" generate

            DUV: entity work.FPAddSingle_8_23_F400_uid2
                port map(
                    clk => Clock,
                    rst => Reset,
                    X => IEEEToFlopocoOutA,
                    Y => IEEEToFlopocoOutB,
                    R => FlopocoToIEEEIn
                );

        end generate SINGLEPATHGEN;


        -- Generates dual path adder (More area, less latency)
        DUALPATHGEN: if adderType = "DUA" generate

            DUV: entity work.FPAddDual_8_23_F400_uid2
                port map(
                    clk => Clock,
                    rst => Reset,
                    X => IEEEToFlopocoOutA,
                    Y => IEEEToFlopocoOutB,
                    R => FlopocoToIEEEIn
                );

        end generate DUALPATHGEN;

    end generate ADDERGEN;


    -- Generate multiplier
    MULGEN: if coreType = "MUL" generate

        DUV: entity work.FPMult_8_23_8_23_8_23_F400_uid2
            port map(
                clk => Clock,
                rst => Reset,
                X => IEEEToFlopocoOutA,
                Y => IEEEToFlopocoOutB,
                R => FlopocoToIEEEIn
            );

    end generate MULGEN;


    -- Generate squarer
    SQUAREGEN: if coreType = "SQR" generate

        DUV: entity work.FPSquare_8_23_23_F400_uid2
            port map(
                clk => Clock,
                rst => Reset,
                X => IEEEToFlopocoOutA,
                R => FlopocoToIEEEIn
            );

    end generate SQUAREGEN;


    -- Generate divider
    DIVGEN: if coreType = "DIV" generate

        DUV: entity work.FPDiv_8_23_F400_uid2
            port map(
                clk => Clock,
                rst => Reset,
                X => IEEEToFlopocoOutA,
                Y => IEEEToFlopocoOutB,
                R => FlopocoToIEEEIn
            );

    end generate DIVGEN;


    -- Generate square root
    SQRTGEN: if coreType = "ROO" generate

        DUV: entity work.FPSqrt_8_23
            port map(
                clk => Clock,
                rst => Reset,
                X => IEEEToFlopocoOutA,
                R => FlopocoToIEEEIn
            );


    end generate SQRTGEN;


    -- Reads stimulus from text file and compares the result against expected value
    StimProc: process 
        variable textLine: line;
        variable opATemp, opBTemp: real;
        variable fileOk: boolean;
        variable lineCounter: integer := 0;
    begin

        TestCaseIteration: while not endfile(stimulusFile) loop

            -- Skip empty lines and single-line comments
            --if textLine.all'length = 0 or textLine.all(1) = '#' then
            --    next;
            --end if;

            -- Resets flags for new test case
            clockCounter <= 0;
            start <= '0';

            -- Sets inputs at falling edge
            wait for 2*clockPeriod;
            wait for clockHalfPeriod;
    
            -- Read OP A value from line
            readline(stimulusFile, textLine);
            read(textLine, opATemp, fileOk);
            lineCounter := lineCounter + 1;
            assert fileOk report "Error reading Operand A value @ line " & integer'image(lineCounter)& ": " & textLine.all severity error; 
            opA <= to_slv(to_float(opATemp,f));

            -- Read OP B value from line
            readline(stimulusFile, textLine);
            read(textLine, opBTemp, fileOk);
            lineCounter := lineCounter + 1;
            assert fileOk report "Error reading Operand B value @ line " & integer'image(lineCounter)& ": " & textLine.all severity error; 
            opB <= to_slv(to_float(opBTemp,f));

            -- Signals operands are ready
            start <= '1';

            -- Every falling edge increments counter and waits for next falling edge
            for i in 0 to 39 loop

                clockCounter <= i;
                wait for clockPeriod;

            end loop;

            -- Compares given result with expected result
            if coreType = "ADD" then

                if to_real(result) = (opATemp + opBTemp) then
                    report ( real'image(opATemp) & " + " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " PASS" ) severity note;
                else
                    report ( real'image(opATemp) & " + " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " FAIL" ) severity warning;
                end if;

            elsif coreType = "SUB" then

                if to_real(result) = (opATemp - opBTemp) then
                    report ( real'image(opATemp) & " - " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " PASS" ) severity note;
                else
                    report ( real'image(opATemp) & " - " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " FAIL" ) severity warning;
                end if;

            elsif coreType = "MUL" then

                if to_real(result) = (opATemp * opBTemp) then
                    report ( real'image(opATemp) & " * " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " PASS" ) severity note;
                else
                    report ( real'image(opATemp) & " * " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " FAIL" ) severity warning;
                end if;

            elsif coreType = "DIV" then

                if to_real(result) = (opATemp / opBTemp) then
                    report ( real'image(opATemp) & " / " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " PASS" ) severity note;
                else
                    report ( real'image(opATemp) & " / " & real'image(opBTemp) & " = " & real'image(to_real(result)) & " FAIL" ) severity warning;
                end if;


            elsif coreType = "SQR" then

                if to_real(result) = sqrt(tp_real(opATemp)) then
                    report ( "Square Root of " & real'image(opATemp) & " = " real'image(to_real(result)) & " PASS" ) severity note;
                else
                    report ( "Square Root of " & real'image(opATemp) & " = " real'image(to_real(result)) & " PASS" ) severity warning;
                end if;

            end if;
            
            -- Reads empty line
            readline(stimulusFile, textLine);

        end loop TestCaseIteration;

    end process;

end architecture testbench;
