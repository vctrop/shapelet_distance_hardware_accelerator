-------------------------------------------------------------------------
-- Design unit: Util package
-- Description: Package with some general functions/procedures
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package test_pkg is  
    
    -- Converts an hexadecimal string digit into a 4 bits std_logic_vector.
	function CharToStdLogicVector(digit: character) return std_logic_vector;
	
	-- Converts an hexadecimal string number into a std_logic_vector.
	-- The vector length depends on the number of string characteres (string length * 4).
	function StringToStdLogicVector(value: string) return std_logic_vector;
	    
	function StdLogicVectorToChar(slv : std_Logic_vector(3 downto 0)) return character;
	
	function slv_to_hexstr(value : std_logic_vector(31 downto 0)) return string;
	     
end test_pkg;


package body test_pkg is

	-- Converts an hexadecimal string digit into a std_logic_vector(3 downto 0).
	function CharToStdLogicVector(digit: character) return std_logic_vector is         
    	
		variable binaryDigit: std_logic_vector(3 downto 0);
    	
   	begin
    	
    	case (digit) is  
        	when '0' 		=> binaryDigit := "0000";
            when '1' 		=> binaryDigit := "0001";
            when '2' 		=> binaryDigit := "0010";
            when '3' 		=> binaryDigit := "0011";
            when '4' 		=> binaryDigit := "0100";
            when '5' 		=> binaryDigit := "0101";
            when '6' 		=> binaryDigit := "0110";
            when '7' 		=> binaryDigit := "0111";
            when '8' 		=> binaryDigit := "1000";
            when '9' 		=> binaryDigit := "1001";
            when 'A' | 'a'	=> binaryDigit := "1010";
            when 'B' | 'b' 	=> binaryDigit := "1011";
            when 'C' | 'c' 	=> binaryDigit := "1100";
            when 'D' | 'd' 	=> binaryDigit := "1101";
            when 'E' | 'e' 	=> binaryDigit := "1110";
            when 'F' | 'f' 	=> binaryDigit := "1111";
            when others =>  binaryDigit := "0000";  
      	end case;
      
     	return binaryDigit;
  
	end CharToStdLogicVector;
	
  
  
	-- Converts an hexadecimal string number into a std_logic_vector.
	-- The vector length depends on the number of string characteres (string length * 4).
	function StringToStdLogicVector(value: string) return std_logic_vector is
  
  		variable binaryValue: std_logic_vector(value'length*4-1 downto 0);
  		variable vectorLength: integer;
  		variable high, low: integer;
 	
 	begin
 	
 		-- Each string digits is converted into a 4 bits binary digit.
 		vectorLength := value'length*4;
  
  		
  		-- String characters range from 1 to n.
  		-- The left most character has the index 1.
  		-- Ex: value: string:= "5496" -> value(1) = 5, value(2) = 4, value(3) = 9, value(4) = 6
  		
  		
  		-- Converts the string number character by character.
  		-- The left most character is placed at the right most 4 bits in the std_logic_vector.
  		-- The right most character is placed at the left most 4 bits in the std_logic_vector.
  		for i in value'range loop
  			high := vectorLength - (4*(i-1)) - 1;
  			low	:= high-3;
  			binaryValue(high downto low) := CharToStdLogicVector(value(i));		
  		end loop;
  		
  		  
  		return binaryValue;
  	
  	end StringToStdLogicVector;

	function StdLogicVectorToChar(slv : std_Logic_vector(3 downto 0)) return character is         
    	
		variable char : character;
    	
   	begin
    	
    	case (slv) is  
        	when "0000" 		=> char := '0';
            when "0001" 		=> char := '1';
            when "0010" 		=> char := '2';
            when "0011" 		=> char := '3';
            when "0100" 		=> char := '4';
            when "0101" 		=> char := '5';
            when "0110" 		=> char := '6';
            when "0111" 		=> char := '7';
            when "1000" 		=> char := '8';
            when "1001" 		=> char := '9';
            when "1010"			=> char := 'a';
            when "1011" 		=> char := 'b';
            when "1100" 		=> char := 'c';
            when "1101" 		=> char := 'd';
            when "1110" 		=> char := 'e';
            when "1111" 		=> char := 'f';
            when others =>  char := 'Z';  
      	end case;
      
     	return char;
  
	end StdLogicVectorToChar;
  	
	function slv_to_hexstr(value : std_logic_vector(31 downto 0)) return string is
		variable hexstr : string(1 to 8);
	begin
		hexstr(8) := StdLogicVectorToChar(value(3 downto 0));
		hexstr(7) := StdLogicVectorToChar(value(7 downto 4));
		hexstr(6) := StdLogicVectorToChar(value(11 downto 8));
		hexstr(5) := StdLogicVectorToChar(value(15 downto 12));
		hexstr(4) := StdLogicVectorToChar(value(19 downto 16));
		hexstr(3) := StdLogicVectorToChar(value(23 downto 20));
		hexstr(2) := StdLogicVectorToChar(value(27 downto 24));
		hexstr(1) := StdLogicVectorToChar(value(31 downto 28));
		return hexstr;
	end slv_to_hexstr;

end test_pkg;
