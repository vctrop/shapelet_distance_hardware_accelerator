library IEEE;
use IEEE.numeric_std.all
use ieee.std_logic_1164.all;

-- 
-- 
-- 

entity shapelet_distance is
    generic(
        -- Number of processig units (each PU is composed of square, accumulate, sub and div)
        NUM_PU: natural := 2;
        -- Maximum shapelet length (must be multiple of 
        MAX_LEN: natural 
    );
    port (
        clk     : in std_logic;
        rst_n   : in std_logic;
        
        -- Operation
        -- "00": change length
        -- "01": change pivot shapelet and normalize it
        -- "10": change target shapelet and compute distance
        op_i   : in std_logic_vector(1 downto 0);
        
        -- Data input can be:
        -- Unsigned int shapelet length
        -- Single precision float shapelet datapoint
        -- ? data_io : inout std_logic_vector(31 downto 0);
        data_i : in std_logic_vector(31 downto 0);
        distance_o : out std_logic_vector(31 downto 0);
        
        -- Ready flag for operation completion
        ready_o : out std_logic
    );
end shapelet_distance;

architecture behavioral of shapelet_distance is

    ---- SHAPELET BUFFERING DEFINITIONS 
    -- Define shapelet buffer and buffer fsm state types 
    type shapelet_buffer_t                              is array (0 to MAX_LEN - 1) of std_logic_vector(31 downto 0);
    type buffer_state_t                                 is (Sbegin, Srst_pivot, Srst_target, Sfill_pivot, Sfill_target, Send);
    -- Shapelet buffers (driver is FILL_BUFFER)
    signal buffer_pivot_s                               : shapelet_buffer_t;
    signal buffer_target_s                              : shapelet_buffer_t;
    -- Buffer filling counter (driver is FILL_BUFFER)
    signal reg_buf_counter_s                            : natural range 0 to MAX_LEN;
    -- Incremented reg_buf_counter_s net (combinational)
    signal reg_buf_counter_inc_s                        : natural range 0 to MAX_LEN;
    -- Buffer ready flag (driver is FILL_BUFFER)
    signal buffer_ready_s                               : std_logic;
    -- Buffer FSM state (driver is FILL_BUFFER)
    signal buffer_state_s                               : buffer_state_t;
    -- Buffer start signal (driver is XXX_PROCESS)
    signal buffer_start_s                               : std_logic;
    -- Selects which buffer is filled (driver is XXX_PROCESS)
    -- '0': fill pivot
    -- '1': fill target
    signal fill_selector_s                              : std_logic;
    
    
    ---- SHAPELET NORMALIZATION DEFINITIONS
    -- Define normalization fsm state type
    type norm_state_t                                   is (Sbegin, Ssquare, Ssum, Sacc, Ssqrt, Sdiv, Sreg);
    -- Normalization fsm state (driver is NORMALIZE_SHAPELET)
    signal norm_state_s                                 : norm_state_t;
    -- Normalization start flag (driver is (XXX_PROCESS)
    signal norm_start_s                                 : std_logic;
    -- Normalization ready flag
    signal norm_ready_s                                 : std_logic;
    -- Selects which shapelet is normalized
    signal norm_selector_s                              : std_logic;
    
    
    ---- SHAPELET DISTANCE DEFINITIONS
    -- Shapelet length register, ranging from 3 to MAX_LEN (driver is XXX_PROCESS)
    signal shapelet_length_s                            : natural range 3 to MAX_LEN;
    -- Decremented shapelet length net (combinational)
    signal dec_length_s                                 : natural range 3 to MAX_LEN;
    
    
    ---- FLOATING POINT OPERATORS
    -- PU's single bit flags and single precision floating point array types 
    type pu_flags_t                                     is array (0 to NUM_PU - 1) of std_logic;    
    type pu_operands_t                                  is array (0 to NUM_PU - 1) of std_logic_vector(31 downto 0); 
    
    -- Array of accumulator registers (combinational)
    signal reg_acc_s                                    : pu_operands_t;
    
    -- addition/subtraction signals
    signal add_or_sub_s                                 : pu_flags_t;   -- 0: add, 1: sub
    signal addsub_opa_s                                 : pu_operands_t;
    signal addsub_out_s                                 : pu_operands_t;
    signal addsub_opb_s                                 : pu_operands_t;
    -- multiplication signals                          
    signal mul_start_s                                  : pu_flags_t;
    signal mul_opa_s                                    : pu_operands_t;
    signal mul_opb_s                                    : pu_operands_t;
    signal mul_out_s                                    : pu_operands_t;
    -- division signals                                
    signal div_start_s                                  : pu_flags_t;
    signal div_opa_s                                    : pu_operands_t;
    signal div_opb_s                                    : pu_operands_t;
    signal div_out_s                                    : pu_operands_t;
        
    -- sqrt signals                                     
    signal sqrt_start_s                                 : std_logic;
    signal sqrt_opa_s                                   : std_logic_vector(31 downto 0);
    signal sqrt_opb_s                                   : std_logic_vector(31 downto 0);
    signal sqrt_out_s                                   : std_logic_vector(31 downto 0);
    
    
    ---- SHAPELETS POSITIONS MUX
    --
    type positions_by_pu_t is array(0 to LEN_MAX/NUM_PU-1) of std_logic_vector(31 downto 0);
    -- 
    type pu_matrix_t is array(0 to NUM_PU-1) of positions_by_pu_t;
    
    -- Input buffer may be either pivot or target shapelets
    signal input_buffer_s                               : shapelet_buffer_t;
    -- Select which term will be presented to the PUs
    signal pu_sel_s                                     : natural range 0 to LEN_MAX/NUM_PU;
    -- Matrix with processing units as rows and shapelet positions for each PU as columns
    signal output_matrix_s                              : pu_matrix_t;
    -- The shapelet positions presented to each of the NUM_PU processing elements
    signal shapelet_elements_mux_s                      : pu_operands_t;
    
begin
    -- Increment reg_buf_counter_s
    reg_buf_counter_inc_s <= reg_buf_counter_s + 1;
    -- Decrement shapelet_length_s
    dec_length_s <= shapelet_length_s - 1;
    
    ---- MUX to present shapelet positions to the right Processing Units
    -- Selects which shapelet is presented to the MUX
    input_buffer_s <=   buffer_pivot_s  when norm_state_s = Sdiv else
                        buffer_target_s;
    --
    OUTER: for i in NUM_PU - 1 downto 0 generate
        -- 
        INNER: for j in (LEN_MAX/NUM_PU - 1) downto 0 generate
            -- 
            output_matrix_s(i)(j) <= input_buffer_s(i + j*NUM_PU);
        end generate INNER;
        
    end generate OUTER;

    -- 
    MUX: for i in NUM_PU - 1 downto 0 generate
        shapelet_elements_mux_s(i) <= output_matrix_s(i)(pu_sel_s);
    end generate MUX;
    
    
    -- Generate processing units (adder/subtractor, multiplier, divider, square root)
    PROCESSING_UNITS:
    for i in 0 to NUM_PU - 1 generate
        -- ADDSUB computes in 6 cycles
        addsub: fp_addsub
        port map(
            clk_i 			=> clk,      
            op_type         => add_or_sub_s(i),                    -- 0 = add, 1 = sub
            opa_i        	=> addsub_opa_s(i),
            opb_i           => addsub_opb_s(i),
            output_o        => addsub_out_s(i),
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
            start_i         => mul_start_s(i),
            opa_i        	=> mul_opa_s(i),                    -- Input Operands A & B
            opb_i           => mul_opb_s(i),
            output_o        => mul_out_s(i),
            -- Exceptions
            ine_o 			=> open,                -- inexact
            overflow_o  	=> open,                -- overflow
            underflow_o 	=> open,                -- underflow
            inf_o			=> open,                -- infinity
            zero_o			=> open,                -- zero
            qnan_o			=> open,                -- queit Not-a-Number
            snan_o			=> open                 -- signaling Not-a-Number
        );
        
        -- Div computes in 33 cycles (says fpu code)
        div: fp_div
        port map(
            clk_i 			=> clk,
            start_i         => div_start_s(i),
            opa_i        	=> div_opa_s(i),                    -- Input Operands A & B
            opb_i           => div_opb_s(i),
            output_o        => div_out_s(i),
            
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
    end generate PROC_ELEMENTS; 
    
    -- Sqrt computes in 33 cycles (outside for .. generate)
    sqrt: fp_sqrt
    port map(
        clk_i 			=> clk,
        start_i         => sqrt_start_s,
        opa_i        	=> sqrt_op,
        output_o        => sqrt_out_s,
        -- Exceptions
        ine_o 			=> open,                            -- inexact
        overflow_o  	=> open,                            -- overflow
        underflow_o 	=> open,                            -- underflow
        inf_o			=> open,                            -- infinity
        zero_o			=> open,                            -- zero
        qnan_o			=> open,                            -- queit Not-a-Number
        snan_o			=> open                             -- signaling Not-a-Number
    );
    
    -- Process to fill pivot and target buffers
    FILL_BUFFER: process(clk, rst_n, buffer_start_s, fill_selector_s)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                buffer_state_s <= Sbegin;
            else
                case buffer_state_s is
                    -- Reset ready, reg_buf_counter_s and decide buffer according to fill_cmd
                    when Sbegin =>
                        buffer_ready_s <= '0';
                        reg_buf_counter_s <= 0;
                        
                        -- Fill pivot shapelet
                        if buffer_start_s = '1' and fill_selector_s = '0' then
                            buffer_state_s <= Srst_pivot;
                        -- Fill target shapelet
                        else if buffer_start_s = '1' and fill_selector_s = '1' then
                            buffer_state_s <= Srst_target;
                        else
                            buffer_state_s <= Sbegin;
                        end if;
                        
                    -- Clear pivot buffer
                    when Srst_pivot =>
                        buffer_pivot_s <= (others => (others => '0'));
                        buffer_state_s <= Sfill_pivot;
                        
                    -- Clear target buffer
                    when Srst_target =>
                        buffer_target_s <= (others => (others => '0'));
                        buffer_state_s <= Sfill_target;
                         
                    -- Fill pivot shapelet
                    when Sfill_pivot =>
                        buffer_pivot_s(reg_buf_counter_s) <= data_i;
                        reg_buf_counter_s <= reg_buf_counter_inc_s;
                        
                        -- Stay until len(buffer) = shapelet_length_s
                        if reg_buf_counter_s = dec_length_s then
                            buffer_state_s <= Send;
                        else
                            buffer_state_s <= Sfill_pivot;
                        end if;
                    
                    -- Fill target shapelet
                    when Sfill_target =>
                        buffer_target_s(reg_buf_counter_s) <= data_i;
                        reg_buf_counter_s <= reg_buf_counter_inc_s;
                        
                        -- Stay until len(buffer) = shapelet_length_s
                        if reg_buf_counter_s = dec_length_s then
                            buffer_state_s <= Send;
                        else
                            buffer_state_s <= Sfill_target;
                        end if;
                    
                    -- Set buffer_ready_s flag
                    when Send =>
                        buffer_ready_s <= '1';
                        buffer_state_s <= Sbegin;
            end if;
        end if;
    end process;
    
    -- Process to normalize pivot and target shapelets
    NORMALIZE_SHAPELET: process(clk, rst_n, norm_start_s)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                norm_state_s <= Sbegin;
            else
                
                
                
            end if;
        end if;
    
    end process;
    
    
    
    
end behavioral;