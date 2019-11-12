library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity tb_fp_modules is 
end tb_fp_modules;

architecture adder of tb_fp_modules is
    signal clk  : std_logic := '0';
    signal op_type, ine, overflow, underflow, inf, zero, qnan, snan : std_logic;
    signal opa, opb, addsub_out : std_logic_vector(31 downto 0);
    constant clk_half_period : time := 5 ns;
    constant clk_period : time := 2* clk_half_period;
	
begin

    clk <= not clk after clk_half_period;

    DUV:  entity work.fp_addsub
        port map(
            clk_i 			=> clk,

            -- opeartion:
            -- ==========
            -- 0 = add,
            -- 1 = sub
            op_type         => op_type,

            -- Input Operands A & B
            opa_i        	=> opa,
            opb_i           => opb,
            
            -- Output port
            output_o        => addsub_out,
            
            -- Exceptions
            ine_o 			=> ine,
            overflow_o  	=> overflow,
            underflow_o 	=> underflow,
            inf_o			=> inf,
            zero_o			=> zero,
            qnan_o			=> qnan,
            snan_o			=> snan
        );
    
    op_type <= '0'; -- add=0 sub=1
    process
    begin
        opa <= x"3e800000";
        opb <= x"3f000000";
        wait for 7*clk_period;
        op_type <= '1';
	    wait;
    end process;
end architecture adder;
    
architecture multiplier of tb_fp_modules is
    signal clk  : std_logic := '0';
    signal start, ine, overflow, underflow, inf, zero, qnan, snan : std_logic;
    signal opa, opb, result : std_logic_vector(31 downto 0);
	constant clk_half_period : time := 5 ns;
    constant clk_period : time := 2* clk_half_period;
begin

    clk <= not clk after clk_half_period;

    start <= '1', '0' after 3*clk_period;
    DUV: entity work.fp_mul
        port map(
            clk_i 			=> clk,
            start_i         => start,
    
            -- Input Operands A & B
            opa_i        	=> opa,
            opb_i           => opb,
            
            -- Output port
            output_o       => result,
            
            -- Exceptions
            ine_o 			=> ine,
            overflow_o  	=> overflow,
            underflow_o 	=> underflow,
            inf_o			=> inf,
            zero_o			=> zero,
            qnan_o			=> qnan,
            snan_o			=> snan
        );   

    process
    begin
        opa <= x"3e800000";
        opb <= x"3f000000";
        wait;
    end process;
end architecture multiplier;


architecture divider of tb_fp_modules is
    signal clk  : std_logic := '0';
    signal start, ine, overflow, underflow, inf, zero, div_zero, qnan, snan : std_logic;
    signal opa, opb, result : std_logic_vector(31 downto 0);
	constant clk_half_period : time := 5 ns;
    constant clk_period : time := 2* clk_half_period;
begin
    clk <= not clk after clk_half_period;
    start <= '1', '0' after 2*clk_period;

    DUV: entity work.fp_div
        port map (
            clk_i 			=> clk,
            start_i         => start,
    
            -- Input Operands A & B
            opa_i        	=> opa,
            opb_i           => opb,
            
            -- Output port
            output_o       => result,
            
            -- Exceptions
            ine_o 			=> ine,
            overflow_o  	=> overflow,
            underflow_o 	=> underflow,
            div_zero_o      => div_zero,
            inf_o			=> inf,
            zero_o			=> zero,
            qnan_o			=> qnan,
            snan_o			=> snan
        );   
        
    process
    begin
        opa <= x"3e800000";
        opb <= x"3f000000";
        wait;
    end process;
end architecture divider;

architecture sqrt of tb_fp_modules is
    signal clk  : std_logic := '0';
    signal start, ine, overflow, underflow, inf, zero, qnan, snan : std_logic;
    signal opa, result : std_logic_vector(31 downto 0);
	constant clk_half_period : time := 5 ns;
    constant clk_period : time := 2* clk_half_period;
begin
    clk <= not clk after clk_half_period;
    

    DUV: entity work.fp_sqrt
        port map (
            clk_i 			=> clk,
            start_i         => start,
    
            -- Input Operand A 
            opa_i        	=> opa,
            
            -- Output port
            output_o       => result,
            
            -- Exceptions
            ine_o 			=> ine,
            overflow_o  	=> overflow,
            underflow_o 	=> underflow,
            inf_o			=> inf,
            zero_o			=> zero,
            qnan_o			=> qnan,
            snan_o			=> snan
        );

    process
    begin
        start <= '1';
        opa <= x"40800000"; --4
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"41800000"; --16
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"420e0000"; --35.5
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"bf800000"; -- (-1)
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"40551eb8"; -- 3.33
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"49742400"; -- 1000000
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"49742416"; -- 1000001.4
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"411547ae"; -- 9.33
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;
 
        start <= '1';
        opa <= x"41840000"; -- 16.5
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;

        start <= '1';
        opa <= x"41bd47ae"; -- 16.5
        wait for clk_period;
        start <= '0';
        wait for 35*clk_period;
        
        wait;
    end process;
end architecture sqrt;
