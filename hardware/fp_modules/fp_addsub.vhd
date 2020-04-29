library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.fpu_pkg.all;
use work.component_pkg.all;

-- floating point addition / subtraction in 6 clock cycles

entity fp_addsub is
    port (
        clk_i 			: in std_logic;

        -- opeartion:
        -- ==========
        -- 0 = add,
        -- 1 = sub
        op_type         : in std_logic;

        -- Input Operands A & B
        opa_i        	: in std_logic_vector(31 downto 0); 
        opb_i           : in std_logic_vector(31 downto 0);
        
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
end fp_addsub;


-- Asynchronous inputs, Asynchronous outputs
architecture round_to_nearest_even of fp_addsub is

    -- Unit signals
	signal prenorm_addsub_fracta_28_o, prenorm_addsub_fractb_28_o: std_logic_vector(27 downto 0);
	signal prenorm_addsub_exp_o: std_logic_vector(7 downto 0); 
	
	signal addsub_fract_o: std_logic_vector(27 downto 0); 
    signal addsub_sign_o: std_logic;
    
    signal postnorm_addsub_ine_o: std_logic;
	signal s_output_o: std_logic_vector(31 downto 0); -- outputs cannot be read
    
    -- Exception signals
    signal s_qnan_o, s_snan_o: std_logic;
    
begin

    i_prenorm_addsub: pre_norm_addsub
    	port map (
    	    clk_i       => clk_i,
            opa_i       => opa_i,
            opb_i       => opb_i,
            fracta_28_o => prenorm_addsub_fracta_28_o,
            fractb_28_o => prenorm_addsub_fractb_28_o,
            exp_o       => prenorm_addsub_exp_o
        );
				
	i_addsub: addsub_28
        port map(
            clk_i    => clk_i, 			
            fpu_op_i => op_type,		 
            fracta_i => prenorm_addsub_fracta_28_o,	
            fractb_i => prenorm_addsub_fractb_28_o,		
            signa_i  => opa_i(31),			
            signb_i  => opb_i(31),				
            fract_o  => addsub_fract_o,			
            sign_o   => addsub_sign_o
        );	
			 
	i_postnorm_addsub: post_norm_addsub
        port map(
            clk_i      => clk_i,		
            opa_i      => opa_i,
            opb_i      => opb_i,	
            fract_28_i => addsub_fract_o,
            exp_i      => prenorm_addsub_exp_o,
            sign_i     => addsub_sign_o,
            fpu_op_i   => op_type, 
            rmode_i    => "00",
            output_o   => s_output_o,
            ine_o      => postnorm_addsub_ine_o
        );
    
    -- Generate Exceptions 
	underflow_o <= '1' when s_output_o(30 downto 23)="00000000" and postnorm_addsub_ine_o='1' else '0'; 
	overflow_o <= '1' when s_output_o(30 downto 23)="11111111" and postnorm_addsub_ine_o='1' else '0';
    inf_o <= '1' when s_output_o(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
	zero_o <= '1' when or_reduce(s_output_o(30 downto 0))='0' else '0';
	s_qnan_o <= '1' when s_output_o(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when opa_i(30 downto 0)=SNAN or opb_i(30 downto 0)=SNAN else '0';

    --outputs
    qnan_o <= s_qnan_o;
    snan_o <= s_snan_o;
    ine_o <= postnorm_addsub_ine_o;
	output_o <= s_output_o;

end architecture round_to_nearest_even;


-- Asynchronous inputs, Synchronous outputs
architecture round_to_nearest_even_syncOut of fp_addsub is

    -- Unit signals
    signal prenorm_addsub_fracta_28_o, prenorm_addsub_fractb_28_o: std_logic_vector(27 downto 0);
    signal prenorm_addsub_exp_o: std_logic_vector(7 downto 0); 
    
    signal addsub_fract_o: std_logic_vector(27 downto 0); 
    signal addsub_sign_o: std_logic;
    
    signal postnorm_addsub_ine_o: std_logic;
    signal s_output_o: std_logic_vector(31 downto 0); -- outputs cannot be read
    
    -- Exception signals
    signal s_underflow_o, s_overflow_o, s_inf_o, s_zero_o, s_snan_o, s_qnan_o: std_logic;
    
begin

    i_prenorm_addsub: pre_norm_addsub
        port map (
            clk_i       => clk_i,
            opa_i       => opa_i,
            opb_i       => opb_i,
            fracta_28_o => prenorm_addsub_fracta_28_o,
            fractb_28_o => prenorm_addsub_fractb_28_o,
            exp_o       => prenorm_addsub_exp_o
        );
                
    i_addsub: addsub_28
        port map(
            clk_i    => clk_i,          
            fpu_op_i => op_type,         
            fracta_i => prenorm_addsub_fracta_28_o, 
            fractb_i => prenorm_addsub_fractb_28_o,     
            signa_i  => opa_i(31),          
            signb_i  => opb_i(31),              
            fract_o  => addsub_fract_o,         
            sign_o   => addsub_sign_o
        ); 
             
    i_postnorm_addsub: post_norm_addsub
        port map(
            clk_i      => clk_i,        
            opa_i      => opa_i,
            opb_i      => opb_i,    
            fract_28_i => addsub_fract_o,
            exp_i      => prenorm_addsub_exp_o,
            sign_i     => addsub_sign_o,
            fpu_op_i   => op_type, 
            rmode_i    => "00",
            output_o   => s_output_o,
            ine_o      => postnorm_addsub_ine_o
        );
    
    -- Generate Exceptions 
    s_underflow_o <= '1' when s_output_o(30 downto 23)="00000000" and postnorm_addsub_ine_o='1' else '0'; 
    s_overflow_o <= '1' when s_output_o(30 downto 23)="11111111" and postnorm_addsub_ine_o='1' else '0';
    s_inf_o <= '1' when s_output_o(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
    s_zero_o <= '1' when or_reduce(s_output_o(30 downto 0))='0' else '0';
    s_qnan_o <= '1' when s_output_o(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when opa_i(30 downto 0)=SNAN or opb_i(30 downto 0)=SNAN else '0';

    -- Output registers
    process(clk_i) begin

        if rising_edge(clk_i) then

            underflow_o <= s_underflow_o;
            overflow_o <= s_overflow_o;
            inf_o <= s_inf_o;
            zero_o <= s_zero_o;
            qnan_o <= s_qnan_o;
            snan_o <= s_snan_o;
            ine_o <= postnorm_addsub_ine_o;
            output_o <= s_output_o;

        end if;

    end process;

end architecture round_to_nearest_even_syncOut;