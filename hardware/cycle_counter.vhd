library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cycle_counter is
    port (
        clk : in   std_logic;
        rst : in   std_logic;
        -- mode defines the number of cycles to count down
        -- 00 = 6   ( add / sub)
        -- 01 = 33  ( division or sqrt)
        -- 10 = 11  ( multiplication )
        -- 11 = 0     
        mode_i : in std_logic_vector(1 downto 0); 

        start_i : in  std_logic;   -- start countdown
        ready_o : out  std_logic   -- ready signal indicating cycle_counter has finished counting. Active for 1 clock cycle
    );
end entity cycle_counter;

architecture countdown of cycle_counter is
    type state is (S0, S1);
    signal cs : state;      -- current state

    --define the amount of cycles to count for each mode
    constant mode_00 : std_logic_vector(5 downto 0) := "000110";  -- 6
    constant mode_01 : std_logic_vector(5 downto 0) := "100001"; -- 33
    constant mode_10 : std_logic_vector(5 downto 0) := "001011"; -- 11
    constant mode_11 : std_logic_vector(5 downto 0) := "000000"; -- 
    signal reg_count_value_s, new_count_value_s : std_logic_vector(5 downto 0);        -- maximun counter value is 33

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                cs <= S0;
                reg_count_value_s <= (others=> '0');
            else
                case cs is 
                    when S0 =>                  -- wait for start signal
                        if start_i = '1' then     
                            cs <= S1;
                            reg_count_value_s <= new_count_value_s;
                        else
                            cs <= S0;
                        end if;

                    when S1 =>                  -- count down on this state
                        if reg_count_value_s = "000000" then
                            cs <= S0;
                        else
                            reg_count_value_s <= std_Logic_vector(unsigned(reg_count_value_s) - 1);
                            cs <= S1;
                        end if;

                end case;   
            end if;
        end if;
    end process;

    -- mux that selects the next count value
    new_count_value_s <=  mode_00 when mode_i = "00" else
                        mode_01 when mode_i = "01" else
                        mode_10 when mode_i = "10" else
                        mode_11;
    -- ready active during the third state
    ready_o <= '1' when cs = S1 and reg_count_value_s = "000000" else '0';

end countdown ; -- countdown
