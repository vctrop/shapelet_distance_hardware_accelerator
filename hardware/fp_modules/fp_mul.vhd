library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.fpupack.all;
use work.comppack.all;

entity fp_mul is
    port (
        clk_i 			: in std_logic;
        start_i         : in std_logic;

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
end fp_mul;

architecture round_to_nearest_even_parallel of fp_mul is
	
	signal pre_norm_mul_exp_10 : std_logic_vector(9 downto 0);
	signal pre_norm_mul_fracta_24	: std_logic_vector(23 downto 0);
	signal pre_norm_mul_fractb_24	: std_logic_vector(23 downto 0);
	 	
	signal mul_24_fract_48 : std_logic_vector(47 downto 0);
	signal mul_24_sign	: std_logic;
	signal serial_mul_fract_48 : std_logic_vector(47 downto 0);
	signal serial_mul_sign	: std_logic;
	
	signal mul_fract_48: std_logic_vector(47 downto 0);
	signal mul_sign: std_logic;
	
	signal post_norm_mul_output	: std_logic_vector(31 downto 0);
	signal post_norm_mul_ine	: std_logic;
	signal s_output_o			: std_logic_vector(31 downto 0);	--outputs cannot be read
    
    --exception signals
    signal s_qnan_o, s_snan_o : std_logic;
begin

    i_pre_norm_mul: pre_norm_mul
	port map(
		clk_i => clk_i,		
		opa_i => opa_i,
		opb_i => opb_i,
		exp_10_o => pre_norm_mul_exp_10,
		fracta_24_o	=> pre_norm_mul_fracta_24,
		fractb_24_o	=> pre_norm_mul_fractb_24);
			 	
	i_mul_24 : mul_24
	port map(
			 clk_i => clk_i,
			 fracta_i => pre_norm_mul_fracta_24,
			 fractb_i => pre_norm_mul_fractb_24,
			 signa_i => opa_i(31),
			 signb_i => opb_i(31),
			 start_i => start_i,
			 fract_o => mul_24_fract_48, 
			 sign_o =>	mul_24_sign,
			 ready_o => open);	
	
	i_post_norm_mul : post_norm_mul
	port map(
			 clk_i => clk_i,
			 opa_i => opa_i,
			 opb_i => opb_i,
			 exp_10_i => pre_norm_mul_exp_10,
			 fract_48_i	=> mul_24_fract_48,
			 sign_i	=> mul_24_sign,
			 rmode_i => "00",
			 output_o => s_output_o,
             ine_o => post_norm_mul_ine);
             
	output_o <= s_output_o;
    -- Generate Exceptions 
	underflow_o <= '1' when s_output_o(30 downto 23)="00000000" and post_norm_mul_ine='1' else '0'; 
	overflow_o <= '1' when s_output_o(30 downto 23)="11111111" and post_norm_mul_ine='1' else '0';
	inf_o <= '1' when s_output_o(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
	zero_o <= '1' when or_reduce(s_output_o(30 downto 0))='0' else '0';
	s_qnan_o <= '1' when s_output_o(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when opa_i(30 downto 0)=SNAN or opb_i(30 downto 0)=SNAN else '0';

    qnan_o <= s_qnan_o;
    snan_o <= s_snan_o;
end architecture;