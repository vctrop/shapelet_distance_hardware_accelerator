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
    );
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
        ready_o : out std_logic
    );
end shapelet_distance;

architecture behavioral of shapelet_distance is

    ---- SHAPELET BUFFERING DEFINITIONS 
    -- Define shapelet buffer and buffer fsm state types 
    type shapelet_buffer_t      is array (0 to MAX_LEN - 1) of std_logic_vector(31 downto 0);
    type buffer_state_t         is (Sbegin, Srst_pivot, Srst_target, Sfill_pivot, Sfill_target, Send);
    -- Shapelet buffers (driver is FILL_BUFFER)
    signal pivot_shapelet       : shapelet_buffer_t;
    signal target_shapelet      : shapelet_buffer_t;
    -- Buffer filling counter (driver is FILL_BUFFER)
    signal counter              : natural range 0 to MAX_LEN;
    -- Incremented counter net
    signal counter_inc          : natural range 0 to MAX_LEN;
    -- Buffer ready flag (driver is FILL_BUFFER)
    signal buffer_ready         : std_logic;
    -- Buffer FSM state (driver is FILL_BUFFER)
    signal buffer_state         : buffer_state_t;
    -- Buffer start signal (driver is XXX_PROCESS)
    signal buffer_start         : std_logic;
    -- Buffer filling command (driver is XXX_PROCESS)
    -- "00": fill none
    -- "01": fill pivot
    -- "10": fill target
    signal fill_cmd             : std_logic_vector(2 downto 0);
    
    ---- SHAPELET NORMALIZATION DEFINITIONS
    -- Define normalization fsm state type
    type norm_state_t is (Sbegin);
    -- Normalization fsm state (driver is NORMALIZE_SHAPELET)
    signal norm_state           : norm_state_t;
    -- Normalization start flag (driver is (XXX_PROCESS)
    signal norm_start           : std_logic;
    
    ---- SHAPELET DISTANCE DEFINITIONS
    -- Shapelet length register, ranging from 3 to MAX_LEN (driver is XXX_PROCESS)
    signal shapelet_length      : natural range 3 to MAX_LEN;
    -- Decremented shapelet length net
    signal dec_length           : natural range 3 to MAX_LEN;
    
    ---- FLOATING POINT OPERATORS
    -- PE's single bit flags and single precision floating point array types 
    type flag_array                     is array (0 to NUM_PES-1) of std_logic;    
    type fp_array                       is array (0 to NUM_PES-1) of std_logic_vector(31 downto 0); 
    
    -- addition/subtraction signals
    signal addsub_start                 flag_array;
    signal addsub_opa                   fp_array;
    signal addsub_opb                   fp_array;
    signal addsub_out                   fp_array;
    -- multiplication signals           
    signal mul_start                    fp_array;
    signal mul_opa                      fp_array;
    signal mul_opb                      fp_array;
    signal mul_out                      fp_array;
    -- division signals                 
    signal div_start                    fp_array;
    signal div_opa                      fp_array;
    signal div_opb                      fp_array;
    signal div_out                      fp_array;
    -- sqrt signals                     
    signal sqrt_start                   fp_array;
    signal sqrt_opa                     fp_array;
    signal sqrt_opb                     fp_array;
    signal sqrt_out                     fp_array;
    
begin
    -- Increment counter
    counter_inc <= counter + 1;
    -- Decrement shapelet_length
    dec_length <= shapelet_length - 1;
    -- (TODO: JOIN ALL EXCEPTIONS IN A SLV)
    
    -- Generate NUM_PES processing elements (adder/subtractor, multiplier, divider, square root)
    PROC_ELEMENTS:
    for i in 0 to 1 generate
        -- ADDSUB computes in 6 cycles
        addsub: fp_addsub
        port map(
            clk_i 			=> clk,      
            op_type         => addsub_start(i),                    -- 0 = add, 1 = sub
            opa_i        	=> addsub_opa(i),
            opb_i           => addsub_opb(i),
            output_o        => addsub_out(i),
            -- Exceptions
            ine_o 			=> open,                -- inexact
            overflow_o  	=> open,                -- overflow
            underflow_o 	=> open,                -- underflow
            inf_o			=> open,                -- infinity
            zero_o			=> open,                -- zero
            qnan_o			=> open,                -- queit Not-a-Number
            snan_o			=> open                 -- signaling Not-a-Number
        );
        
        -- MUL computes in 11 cycles
        mul: fp_mul
        port map(
            clk_i 			=> clk,
            start_i         => mul_start(i),
            opa_i        	=> mul_opa(i),                    -- Input Operands A & B
            opb_i           => mul_opb(i),
            output_o        => mul_out(i),
            -- Exceptions
            ine_o 			=> open,                -- inexact
            overflow_o  	=> open,                -- overflow
            underflow_o 	=> open,                -- underflow
            inf_o			=> open,                -- infinity
            zero_o			=> open,                -- zero
            qnan_o			=> open,                -- queit Not-a-Number
            snan_o			=> open                 -- signaling Not-a-Number
        );
        
        -- Div computes in 33 cycles (says fpu code) or 7 cycles (says fp_div) (TODO: VERIFY)
        div: fp_div
        port map(
            clk_i 			=> clk,
            start_i         => div_start(i),
            opa_i        	=> div_opa(i),                    -- Input Operands A & B
            opb_i           => div_opb(i),
            output_o        => div_out(i),
            
            -- Exceptions
            ine_o 			 => open,                       -- inexact
            overflow_o  	 => open,                       -- overflow
            underflow_o 	 => open,                       -- underflow
            div_zero_o       => open,                       -- division by zero
            inf_o			 => open,                       -- infinity
            zero_o			 => open,                       -- zero
            qnan_o			 => open,                       -- queit Not-a-Number
            snan_o			 => open                        -- signaling Not-a-Number
        );
        
        -- Sqrt computes in 33 cycles (?perfect squares finish faster)
        sqrt: fp_sqrt
        port map(
            clk_i 			=> clk,
            start_i         => sqrt_start(i),
            opa_i        	=> sqrt_op(i),
            output_o        => sqrt_out(i),
            -- Exceptions
            ine_o 			=> open,                            -- inexact
            overflow_o  	=> open,                            -- overflow
            underflow_o 	=> open,                            -- underflow
            inf_o			=> open,                            -- infinity
            zero_o			=> open,                            -- zero
            qnan_o			=> open,                            -- queit Not-a-Number
            snan_o			=> open                             -- signaling Not-a-Number
        );
    end generate PROC_ELEMENTS; 
    
    
    -- Process to fill pivot and target buffers
    FILL_BUFFER: process(clk, rst_n, buffer_start, fill_cmd)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                buffer_state <= Sbegin;
            else
                case buffer_state is
                    -- Reset ready, counter and decide buffer according to fill_cmd
                    when Sbegin =>
                        buffer_ready <= '0';
                        counter <= 0;
                        
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
                        pivot_shapelet(counter) <= data_in;
                        counter <= counter_inc;
                        
                        -- Stay until len(buffer) = shapelet_length
                        if counter = dec_length then
                            buffer_state <= Send;
                        else
                            buffer_state <= Sfill_pivot;
                        end if;
                    
                    -- Fill target shapelet
                    when Sfill_target =>
                        target_shapelet(counter) <= data_in;
                        counter <= counter_inc;
                        
                        -- Stay until len(buffer) = shapelet_length
                        if counter = dec_length then
                            buffer_state <= Send;
                        else
                            buffer_state <= Sfill_target;
                        end if;
                    
                    -- Set buffer_ready flag
                    when Send =>
                        buffer_ready <= '1';
                        buffer_state <= Sbegin;
            end if;
        end if;
    end process;
    
    -- Process to normalize pivot and target shapelets
    NORMALIZE_SHAPELET: process(clk, rst_n, norm_start)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                norm_state <= Sbegin;
            else
                
                
                
            end if;
        end if;
    
    end process;
    
    
    
    
end behavioral;