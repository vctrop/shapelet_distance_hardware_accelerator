library IEEE;
use IEEE.numeric_std.all
use ieee.std_logic_1164.all;

-- 
-- 
-- 

entity shapelet_distance is
    generic(
        -- Maximum shapelet length
        MAX_LEN: natural;
        -- Number of processig elements (each PE is composed of square, accumulate, sub and div)
        NUM_PES: natural 
    )
    port (
        clk     : in std_logic;
        rst_n   : in std_logic;
        -- Operation
        -- "00": change length
        -- "01": change pivot shapelet and normalize it
        -- "10": change target shapelet and compute distance
        op_in   : in std_logic_vector(1 downto 0);
        
        -- Data input can be:
        -- Unsigned int shapelet length
        -- Single precision float shapelet datapoint
        -- ? data_io : inout std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0);
        distance_o : out std_logic_vector(31 downto 0);
        
        -- Ready flag for operation completion
        ready_o : out std_logic;
    );
end shapelet_distance;

architecture rtl of shapelet_distance is
    -- Define shapelet buffer and buffer fsm states
    type shapelet_buffer_t is array (0 to MAX_LEN - 1) of std_logic_vector(31 downto 0);
    type buffer_state_t is (Sbegin, Srst_pivot, Srst_target, Sfill_pivot, Sfill_target, Send);
    
    -- Shapelet buffers (driver is FILL_BUFFER)
    signal pivot_shapelet       : shapelet_buffer_t;
    signal target_shapelet      : shapelet_buffer_t;
    
    -- Buffer filling counter
    signal counter : natural range 0 to MAX_LEN;
    
    -- Buffer ready flag (driver is FILL_BUFFER)
    signal buffer_ready            : std_logic;
    
    -- Buffer FSM state
    signal buffer_state         : buffer_state_t;
    
    -- Buffer start signal (driver is XXX_PROCESS)
    signal buffer_start            : std_logic;
    
    -- Buffer filling command (driver is XXX_PROCESS)
    -- "00": fill none
    -- "01": fill pivot
    -- "10": fill target
    signal fill_cmd             : std_logic_vector(2 downto 0);
    
    -- Shapelet length register, ranging from 3 to MAX_LEN (driver is XXX_PROCESS)
    signal shapelet_length      : natural range 3 to MAX_LEN;
    
begin

    -- Process to fill pivot and target buffers
    FILL_BUFFER: process(clk, rst_n, fill_cmd)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                buffer_state <= Sbegin;
            else
                case buffer_state is
                    -- Reset ready, counter and decide buffer according to fill_cmd
                    when Sbegin =>
                        buffer_ready <= '0';
                        count <= 0;
                        
                        -- Fill pivot shapelet
                        if buffer_start = '1' and fill_cmd = "01" then
                            buffer_state <= Srst_pivot;
                        -- Fill target shapelet
                        else if buffer_start = '1' and fill_cmd = "10" then
                            buffer_state <= Srst_target;
                        else
                            buffer_state <= Sbegin;
                        end if;
                        
                    -- Clear pivot buffer
                    when Srst_pivot =>
                        pivot_shapelet <= (others => (others => '0'));
                        buffer_state <= Sfill_pivot;
                        
                    -- Clear target buffer
                    when Srst_target =>
                        target_shapelet <= (others => (others => '0'));
                         buffer_state <= Sfill_target;
                         
                    -- Fill pivot shapelet
                    when Sfill_pivot =>
                        pivot_shapelet(count) <= data_in;
                        count <= count + 1;
                        
                        -- Leave state only it has shapelet_length
                        if count = shapelet_length - 1 then
                            buffer_state <= Send;
                        else
                            buffer_state <= Spivot;
                        end if;
                    
                    -- Fill target shapelet
                    when Starget =>
                        target_shapelet(count) <= data_in;
                        count <= count + 1;
                        
                        -- Leave state only it has shapelet_length
                        if count = shapelet_length - 1 then
                            buffer_state <= Send;
                        else
                            buffer_state <= Starget;
                        end if;
                    
                    -- Set buffer_ready flag
                    when Send =>
                        buffer_ready <= '1';
                        buffer_state <= Sbegin;
            end if;
        end if;
    end process;
    
    
    
    
    
    
end rtl;