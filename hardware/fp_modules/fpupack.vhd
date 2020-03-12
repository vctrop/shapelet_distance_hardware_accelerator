-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: FPU package wich contains constants and functions needed in the FPU core
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--
-- last modified: Julio:
-- Added unsigned to floting point conersion function.

library  ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

package fpupack is


	-- Data width of floating-point number. Deafult: 32
	constant FP_WIDTH : integer := 32;
	
	-- Data width of fraction. Deafult: 23
	constant FRAC_WIDTH : integer := 23;
	
	-- Data width of exponent. Deafult: 8
	constant EXP_WIDTH : integer := 8;

	--Zero vector
	constant ZERO_VECTOR: std_logic_vector(30 downto 0) := "0000000000000000000000000000000";
	
	-- Infinty FP format
	constant INF  : std_logic_vector(30 downto 0) := "1111111100000000000000000000000";
	
	-- QNaN (Quit Not a Number) FP format (without sign bit)
    constant QNAN : std_logic_vector(30 downto 0) := "1111111110000000000000000000000";
    
    -- SNaN (Signaling Not a Number) FP format (without sign bit)
    constant SNAN : std_logic_vector(30 downto 0) := "1111111100000000000000000000001";
    
    -- count the  zeros starting from left
    function count_l_zeros (signal s_vector: std_logic_vector) return std_logic_vector;
    
    -- count the zeros starting from right
	function count_r_zeros (signal s_vector: std_logic_vector) return std_logic_vector;

	-- converts unsigned integer to floating point.
	-- int must be in range of 0 <= <= 2 ^ 24 - 1 
	function uint_to_fp(int_i : std_logic_vector(31 downto 0)) return std_logic_vector;
    
end fpupack;

package body fpupack is
    
    -- count the  zeros starting from left
	function count_l_zeros (signal s_vector: std_logic_vector) return std_logic_vector is
		variable v_count : std_logic_vector(5 downto 0);	
	begin
		v_count := "000000";
		for i in s_vector'range loop
			case s_vector(i) is
				when '0' => v_count := v_count + "000001";
				when others => exit;
			end case;
		end loop;
		return v_count;	
	end count_l_zeros;


	-- count the zeros starting from right
	function count_r_zeros (signal s_vector: std_logic_vector) return std_logic_vector is
		variable v_count : std_logic_vector(5 downto 0);	
	begin
		v_count := "000000";
		for i in 0 to s_vector'length-1 loop
			case s_vector(i) is
				when '0' => v_count := v_count + "000001";
				when others => exit;
			end case;
		end loop;
		return v_count;	
	end count_r_zeros;


	function uint_to_fp(int_i : std_logic_vector(31 downto 0)) return std_logic_vector is
            -- the position of the first '1' bit is also the value we must add to the exponent
            variable shift_num_s : natural range 0 to 23;
            variable mantissa_s, fp_o :  std_logic_vector(31 downto 0);
        begin
            fp_o(31) := '0';        -- sign bit '0': all integers must be positive
        
            -- priority decoder to find the position of the first '1' bit
            if    int_i(23) = '1' then shift_num_s := 23;
            elsif int_i(22) = '1' then shift_num_s := 22;
            elsif int_i(21) = '1' then shift_num_s := 21;
            elsif int_i(20) = '1' then shift_num_s := 20;
            elsif int_i(19) = '1' then shift_num_s := 19;
            elsif int_i(18) = '1' then shift_num_s := 18;
            elsif int_i(17) = '1' then shift_num_s := 17;
            elsif int_i(16) = '1' then shift_num_s := 16;
            elsif int_i(15) = '1' then shift_num_s := 15;
            elsif int_i(14) = '1' then shift_num_s := 14;
            elsif int_i(13) = '1' then shift_num_s := 13;
            elsif int_i(12) = '1' then shift_num_s := 12;
            elsif int_i(11) = '1' then shift_num_s := 11;
            elsif int_i(10) = '1' then shift_num_s := 10;
            elsif int_i(9)  = '1' then shift_num_s := 9;
            elsif int_i(8)  = '1' then shift_num_s := 8;
            elsif int_i(7)  = '1' then shift_num_s := 7;
            elsif int_i(6)  = '1' then shift_num_s := 6;
            elsif int_i(5)  = '1' then shift_num_s := 5;
            elsif int_i(4)  = '1' then shift_num_s := 4;
            elsif int_i(3)  = '1' then shift_num_s := 3;
            elsif int_i(2)  = '1' then shift_num_s := 2;
            elsif int_i(1)  = '1' then shift_num_s := 1;
            else                       shift_num_s := 0;
            end if;
        
            -- add bias to the exponent
            if int_i /= x"00000000" then
                fp_o(30 downto 23) := std_logic_vector(to_unsigned(shift_num_s + 127, 8));
            else
                fp_o(30 downto 23) := x"00";  --if the input is zero, we have all zeroes
            end if;

            -- mantissa contains all bits except the first
            -- we first zero the first '1' in the input number
            -- and then we rotate it shift_num_s times to the right
            mantissa_s := std_logic_vector(unsigned(int_i) ror shift_num_s); -- we cannot slice this due to conversion
            fp_o(22 downto 0) := mantissa_s(31 downto 9);    -- slice to get the actual mantissa value

            return fp_o;
        end function;

		
end fpupack;