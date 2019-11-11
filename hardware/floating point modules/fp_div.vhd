library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.fpupack.all;
use work.comppack.vhd.all;

entity fp_div is
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
        div_zero_o      : out std_logic; -- division by zero
        inf_o			: out std_logic; -- infinity
        zero_o			: out std_logic; -- zero
        qnan_o			: out std_logic; -- queit Not-a-Number
        snan_o			: out std_logic -- signaling Not-a-Number
	);   
end fp_div;

architecture round_to_nearest_even of fp_div is
	
	signal pre_norm_div_dvdnd : std_logic_vector(49 downto 0);
	signal pre_norm_div_dvsor : std_logic_vector(26 downto 0);
	signal pre_norm_div_exp	: std_logic_vector(EXP_WIDTH+1 downto 0);
	
	signal serial_div_qutnt : std_logic_vector(26 downto 0);
	signal serial_div_rmndr : std_logic_vector(26 downto 0);
	signal serial_div_sign : std_logic;
	signal serial_div_div_zero : std_logic;
	
	signal post_norm_div_output : std_logic_vector(31 downto 0);
    signal post_norm_div_ine : std_logic;
    
    --exception signals
    signal s_qnan_o, s_snan_o : std_logic;
begin

    i_pre_norm_div : pre_norm_div
	port map(
			 clk_i => clk_i,
			 opa_i => opa_i,
			 opb_i => opb_i,
			 exp_10_o => pre_norm_div_exp,
			 dvdnd_50_o	=> pre_norm_div_dvdnd,
			 dvsor_27_o	=> pre_norm_div_dvsor);
			 
	i_serial_div : serial_div
	port map(
			 clk_i=> clk_i,
			 dvdnd_i => pre_norm_div_dvdnd,
			 dvsor_i => pre_norm_div_dvsor,
			 sign_dvd_i => opa_i(31),
			 sign_div_i => opb_i(31),
			 start_i => start_i,
			 ready_o => open,
			 qutnt_o => serial_div_qutnt,
			 rmndr_o => serial_div_rmndr,
			 sign_o => serial_div_sign,
			 div_zero_o	=> div_zero_o);
	
	i_post_norm_div : post_norm_div
	port map(
			 clk_i => clk_i,
			 opa_i => s_opa_i,
			 opb_i => s_opb_i,
			 qutnt_i =>	serial_div_qutnt,
			 rmndr_i => serial_div_rmndr,
			 exp_10_i => pre_norm_div_exp,
			 sign_i	=> serial_div_sign,
			 rmode_i =>	"00",
			 output_o => output_o,
             ine_o => post_norm_div_ine);
             
        -- Generate Exceptions 
	underflow_o <= '1' when output_o(30 downto 23)="00000000" and post_norm_div_ine='1' else '0'; 
	overflow_o <= '1' when output_o(30 downto 23)="11111111" and post_norm_div_ine='1' else '0';
    inf_o <= '1' when output_o(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
	zero_o <= '1' when or_reduce(output_o(30 downto 0))='0' else '0';
	s_qnan_o <= '1' when output_o(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when opa_i(30 downto 0)=SNAN or opb_i(30 downto 0)=SNAN else '0';

    qnan_o <= s_qnan_o;
    snan_o <= s_snan_o;

end architecture;