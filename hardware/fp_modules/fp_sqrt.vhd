library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.fpupack.all;
use work.comppack.all;

-- floating point sqrt takes 31 cycles to complete
entity fp_sqrt is
    port (
        clk_i 			: in std_logic;
        start_i         : in std_logic;

        -- Input Operands A & B
        opa_i        	: in std_logic_vector(31 downto 0);
        
        -- Output port
        output_o        : out std_logic_vector(31 downto 0);
        
        -- Exceptions
        ine_o 			: out std_logic; -- inexact
        overflow_o  	: out std_logic; -- overflow
        underflow_o 	: out std_logic; -- underflow
        inf_o			: out std_logic; -- infinity
        zero_o			: out std_logic; -- zero
        qnan_o			: out std_logic; -- queit Not-a-Number
        snan_o			: out std_logic -- signaling Not-a-Number
	);   
end fp_sqrt;


-- Asynchronous inputs, Asynchronous outputs
architecture round_to_nearest_even of fp_sqrt is
    
    signal pre_norm_sqrt_fracta_o: std_logic_vector(51 downto 0);
	signal pre_norm_sqrt_exp_o: std_logic_vector(7 downto 0);
			 
	signal sqrt_sqr_o: std_logic_vector(25 downto 0);
	signal sqrt_ine_o: std_logic;

	signal post_norm_sqrt_output: std_logic_vector(31 downto 0);
    signal post_norm_sqrt_ine_o: std_logic;
    signal s_output_o: std_logic_vector(31 downto 0); -- Outputs cannot be read
    
    -- Exception signals
    signal s_qnan_o, s_snan_o: std_logic;

begin
    
    i_pre_norm_sqrt : pre_norm_sqrt
	    port map(
			clk_i => clk_i,
			opa_i => opa_i,
			fracta_52_o => pre_norm_sqrt_fracta_o,
			exp_o => pre_norm_sqrt_exp_o
        );
		
	i_sqrt: sqrt 
	    generic map(
            RD_WIDTH=>52, 
            SQ_WIDTH=>26
        ) 
    	port map(
    		clk_i => clk_i,
    		rad_i => pre_norm_sqrt_fracta_o, 
    		start_i => start_i, 
    	   	ready_o => open, 
    	  	sqr_o => sqrt_sqr_o,
    		ine_o => sqrt_ine_o
        );

	i_post_norm_sqrt : post_norm_sqrt
    	port map(
    		clk_i => clk_i,
    		opa_i => opa_i,
    		fract_26_i => sqrt_sqr_o,
    		exp_i => pre_norm_sqrt_exp_o,
    		ine_i => sqrt_ine_o,
    		rmode_i => "00",
    		output_o => s_output_o,
    		ine_o => post_norm_sqrt_ine_o
        );
	
    -- Generate Exceptions 
	underflow_o <= '1' when s_output_o(30 downto 23)="00000000" and post_norm_sqrt_ine_o='1' else '0'; 
	overflow_o <= '1' when s_output_o(30 downto 23)="11111111" and post_norm_sqrt_ine_o='1' else '0';
	inf_o <= '1' when s_output_o(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
	zero_o <= '1' when or_reduce(s_output_o(30 downto 0))='0' else '0';
	s_qnan_o <= '1' when s_output_o(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when opa_i(30 downto 0)=SNAN else '0';

	-- Outputs
    qnan_o <= s_qnan_o;
	snan_o <= s_snan_o;
	ine_o <= post_norm_sqrt_ine_o;
	output_o <= s_output_o;

end architecture round_to_nearest_even;


-- Asynchronous inputs, Synchronous outputs
architecture round_to_nearest_even_syncOut of fp_sqrt is
    
    signal pre_norm_sqrt_fracta_o: std_logic_vector(51 downto 0);
    signal pre_norm_sqrt_exp_o: std_logic_vector(7 downto 0);
             
    signal sqrt_sqr_o: std_logic_vector(25 downto 0);
    signal sqrt_ine_o: std_logic;

    signal post_norm_sqrt_output: std_logic_vector(31 downto 0);
    signal post_norm_sqrt_ine_o: std_logic;
    signal s_output_o: std_logic_vector(31 downto 0); -- Outputs cannot be read
    
    -- Exception signals
    signal s_underflow_o, s_overflow_o, s_zero_o, s_inf_o, s_qnan_o, s_snan_o: std_logic;

begin
    
    i_pre_norm_sqrt : pre_norm_sqrt
        port map(
            clk_i => clk_i,
            opa_i => opa_i,
            fracta_52_o => pre_norm_sqrt_fracta_o,
            exp_o => pre_norm_sqrt_exp_o
        );
        
    i_sqrt: sqrt 
        generic map(
            RD_WIDTH=>52, 
            SQ_WIDTH=>26
        ) 
        port map(
            clk_i => clk_i,
            rad_i => pre_norm_sqrt_fracta_o, 
            start_i => start_i, 
            ready_o => open, 
            sqr_o => sqrt_sqr_o,
            ine_o => sqrt_ine_o
        );

    i_post_norm_sqrt : post_norm_sqrt
        port map(
            clk_i => clk_i,
            opa_i => opa_i,
            fract_26_i => sqrt_sqr_o,
            exp_i => pre_norm_sqrt_exp_o,
            ine_i => sqrt_ine_o,
            rmode_i => "00",
            output_o => s_output_o,
            ine_o => post_norm_sqrt_ine_o
        );
    
    -- Generate Exceptions 
    s_underflow_o <= '1' when s_output_o(30 downto 23)="00000000" and post_norm_sqrt_ine_o='1' else '0'; 
    s_overflow_o <= '1' when s_output_o(30 downto 23)="11111111" and post_norm_sqrt_ine_o='1' else '0';
    s_inf_o <= '1' when s_output_o(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
    s_zero_o <= '1' when or_reduce(s_output_o(30 downto 0))='0' else '0';
    s_qnan_o <= '1' when s_output_o(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when opa_i(30 downto 0)=SNAN else '0';

    -- Output registers
    process(clk_i) begin

        if rising_edge(clk_i) then

            underflow_o <= s_underflow_o;
            overflow_o <= s_overflow_o;
            inf_o <= s_inf_o;
            zero_o <= s_zero_o;
            qnan_o <= s_qnan_o;
            snan_o <= s_snan_o;
            ine_o <= post_norm_sqrt_ine_o;
            output_o <= s_output_o;

        end if;

    end process;
    
end architecture round_to_nearest_even_syncOut;