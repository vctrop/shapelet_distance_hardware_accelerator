
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
    constant coreType: string(1 to 3) := "ADD"; -- "ADD", "SUB", "MUL", "DIV", "SQR" 
    
    -- Stimulus file
    file stimulusFile: text open read_mode is "stimulus.txt";
    --signal textLine: line;
    --signal opATemp, opBTemp: real;
    --signal fileOk: boolean;

    -- Clock signals
    signal clock: std_logic := '0';
    constant clockPeriod: time := 10 ns ;
    constant clockHalfPeriod: time := clockPeriod/2;
    
    -- Operands and flags
    signal start, opType, ine, overflow, underflow, inf, zero, qnan, snan, div_zero: std_logic;
    signal opa, opb, result: std_logic_vector(31 downto 0);
    signal time_to_compute: integer;

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


    -- Generate adder/subtractor
    ADDERGEN: if (coreType = "ADD") or (coreType = "SUB") generate

        -- Set optype if operation is subtraction
        SETOPTYPESUB: if coreType = "SUB" generate
            opType <= '1';
        end generate SETOPTYPESUB;

        -- Set optype if operation is addistion
        SETOPTYPEADD: if coreType = "ADD" generate 
            opType <= '0';
        end generate SETOPTYPEADD;

        -- Instantiate adder/subtractor
        DUV: entity work.fp_addsub
            port map(
                clk_i           => clock,

                -- opeartion:
                -- ==========
                -- 0 = add,
                -- 1 = sub
                op_type         => opType,

                -- Input Operands A & B
                opa_i           => opa,
                opb_i           => opb,
                
                -- Output port
                output_o        => result,
                
                -- Exceptions
                ine_o           => ine,
                overflow_o      => overflow,
                underflow_o     => underflow,
                inf_o           => inf,
                zero_o          => zero,
                qnan_o          => qnan,
                snan_o          => snan
            );

    end generate ADDERGEN;


    -- Generate divider
    DIVGEN: if coreType = "DIV" generate

        -- Instantiate divider
        DUV: entity work.fp_div
            port map (
                clk_i       => clock,
                start_i     => start,
        
                -- Input Operands A & B
                opa_i       => opa,
                opb_i       => opb,
                
                -- Output port
                output_o    => result,
                
                -- Exceptions
                ine_o       => ine,
                overflow_o  => overflow,
                underflow_o => underflow,
                div_zero_o  => div_zero,
                inf_o       => inf,
                zero_o      => zero,
                qnan_o      => qnan,
                snan_o      => snan
            );   

    end generate DIVGEN;


    -- Generate multiplier
    MULGEN: if coreType = "" generate

        DUV: entity work.fp_mul
            port map(
                clk_i       => clock,
                start_i     => start,
        
                -- Input Operands A & B
                opa_i       => opa,
                opb_i       => opb,
                
                -- Output port
                output_o    => result,
                
                -- Exceptions
                ine_o       => ine,
                overflow_o  => overflow,
                underflow_o => underflow,
                inf_o       => inf,
                zero_o      => zero,
                qnan_o      => qnan,
                snan_o      => snan
            );   

    end generate MULGEN;


    -- Generate square root
    SQRTGEN: if coreType = "SQR" generate

        DUV: entity work.fp_sqrt
            port map (
                clk_i       => clock,
                start_i     => start,
        
                -- Input Operand A 
                opa_i       => opa,
                
                -- Output port
                output_o    => result,
                
                -- Exceptions
                ine_o       => ine,
                overflow_o  => overflow,
                underflow_o => underflow,
                inf_o       => inf,
                zero_o      => zero,
                qnan_o      => qnan,
                snan_o      => snan
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
