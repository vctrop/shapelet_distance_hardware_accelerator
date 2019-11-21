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
        -- Maximum shapelet length (must be multiple of NUM_PU)
        MAX_LEN: natural := 12
    );
    port (
        clk     : in std_logic;
        rst_n   : in std_logic;
        
        -- Operation
        -- '0': set shapelet LENGTH and  change the pivot shapelet and normalize it
        -- '1': change target shapelet and compute distance
        op_i   : in std_logic;
        
        -- Data input is a single precision float shapelet datapoint
        data_i : in std_logic_vector(31 downto 0);
        length_i : in natural range 0 to MAX_LEN-1;

        -- begins opeartions
        start_i : in std_logic;        
        -- Ready flag for operation completion
        ready_o : out std_logic
        --distance result
        distance_o : out std_logic_vector(31 downto 0);
    );
end shapelet_distance;

architecture behavioral of shapelet_distance is
    
    -- Flip-flop to keep the desired operation constant during the entire processing
    signal reg_op_s                                     : std_logic;
    
    -- Register to keep the shapelet length
    signal reg_shapelet_length_s                        : natural range 0 to MAX_LEN-1;
   
    -- Shapelet distance FSM states definition
    type fsm_state_t                                    is (Sbegin, Sset_len, Sbuf_rst, Sbuf_load,
                                                            Snorm_square, Snorm_sum_acc, Snorm_reg_acc, Snorm_sqrt, Snorm_div, 
                                                            Sdist_sub, Sdist_square, Sdist_sum_acc, Sdist_reg_acc,
                                                            Swb_pivot, Sout_distance);
    -- Register to keep FSM state
    signal reg_state_s                              : fsm_state_t;
    
     
    -- Buffer filling counter and its incremented by 1 version
    signal reg_buf_counter_s                            : natural range 0 to MAX_LEN;
    -- Operation counter and its incremented by NUM_PU version
    signal reg_acc_counter_s                            : natural range 0 to MAX_LEN;
    
    ---- SHAPELET BUFFERING DEFINITIONS 
    -- Define shapelet buffer and buffer fsm state types 
    type shapelet_buffer_t                              is array (0 to MAX_LEN - 1) of std_logic_vector(31 downto 0);
    --type buffer_state_t                                 is (Sbegin, Srst_pivot, Srst_target, Sfill_pivot, Sfill_target, Send);
    -- Shapelet buffers (drivers are their separate processes)
    signal buffer_pivot_s                               : shapelet_buffer_t;
    signal buffer_target_s                              : shapelet_buffer_t;
    -- Buffers write signals
    signal pivot_buf_wr_s                               : std_logic;
    signal target_buf_wr_s                              : std_logic;    
    -- Buffer reset signals
    signal pivot_buf_rst_s                              : std_logic;
    signal target_buf_rst_s                             : std_logic;
    
    -- Buffer filling counter (driver is FILL_BUFFER)
    --signal reg_buf_counter_s                            : natural range 0 to MAX_LEN;
    -- Incremented reg_buf_counter_s net (combinational)
    -- signal reg_buf_counter_inc_s                        : natural range 0 to MAX_LEN;
    -- Buffer ready flag (driver is FILL_BUFFER)
    --signal buffer_ready_s                               : std_logic;
    -- Buffer FSM state (driver is FILL_BUFFER)
    --signal reg_buf_state_s                               : buffer_state_t;
    -- Buffer start signal (driver is XXX_PROCESS)
    --signal buffer_start_s                               : std_logic;
    -- Selects which buffer is filled (driver is XXX_PROCESS)
    -- '0': fill pivot
    -- '1': fill target
    --signal fill_selector_s                              : std_logic;
    
    
    ---- SHAPELET NORMALIZATION DEFINITIONS
    -- Define normalization fsm state type
    --type norm_state_t                                   is (Sbegin, Ssquare, Ssum, Sacc, Ssqrt, Sdiv, Sout_div);
    -- Normalization fsm state (driver is NORMALIZE_SHAPELET)
    --signal reg_norm_state_s                                 : norm_state_t;
    -- Normalization start flag (driver is (XXX_PROCESS)
    --signal norm_start_s                                 : std_logic;
    -- Normalization ready flag
    --signal norm_ready_s                                 : std_logic;
    -- Selects which shapelet is normalized
    -- signal norm_selector_s                              : std_logic;
    -- Processed points counter register                        
    -- signal reg_norm_count_s                             : natural range 3 to MAX_LEN;
    -- reg_norm_count_s incremented by NUM_PU
    -- signal norm_count_inc_s                             : natural range 3 to MAX_LEN;
    -- Normalization outputs
    --signal norm_out_s                                   : pu_operands_t;
    
    
    ---- SHAPELET DISTANCE DEFINITIONS
    -- Shapelet length register, ranging from 3 to MAX_LEN (driver is XXX_PROCESS)
    
    -- Decremented shapelet length signal (combinational)
    --signal dec_length_s                                 : natural range 3 to MAX_LEN;
    
    
    ---- FLOATING POINT OPERATORS
    -- PU's single precision floating point array types   
    type pu_operands_t                                  is array (0 to NUM_PU - 1) of std_logic_vector(31 downto 0); 
    
    -- Array of accumulator registers (combinational)
    signal reg_accumulators_s                           : pu_operands_t;
    signal accumulators_wr_s                            : std_logic;
    
    -- addition/subtraction signals
    signal add_or_sub_s                                 : std_logic;   -- 0: add, 1: sub
    signal add_or_sub_ready_s                           : std_logic;
    signal addsub_opa_s                                 : pu_operands_t;
    signal addsub_opb_s                                 : pu_operands_t;
    signal addsub_out_s                                 : pu_operands_t;
    -- multiplication signals                          
    signal mul_start_s                                  : std_logic;
    signal mul_ready_s                                  : std_logic;
    signal mul_operator_s                               : pu_operands_t;
    signal mul_out_s                                    : pu_operands_t;
    -- division signals                                
    signal div_start_s                                  : std_logic;
    signal div_ready_s                                  : std_logic;
    signal div_opa_s                                    : pu_operands_t;
    signal div_opb_s                                    : pu_operands_t;
    signal div_out_s                                    : pu_operands_t;
    
    -- sum of accumulators
    signal acc_sum_opa_s                                : std_logic_vector(31 downto 0);
    signal acc_sum_opb_s                                : std_logic_vector(31 downto 0);
    signal acc_sum_out_s                                : std_logic_vector(31 downto 0);
    
    -- sqrt signals                                     
    signal sqrt_start_s                                 : std_logic;
    signal sqrt_ready_s                                 : std_logic;
    signal sqrt_opa_s                                   : std_logic_vector(31 downto 0);
    signal sqrt_opb_s                                   : std_logic_vector(31 downto 0);
    signal sqrt_out_s                                   : std_logic_vector(31 downto 0);
    
    ---- SHAPELETS POSITIONS MUX
    --
    type positions_by_pu_t                              is array(0 to LEN_MAX/NUM_PU-1)  of std_logic_vector(31 downto 0);
    -- 
    type pu_matrix_t                                    is array(0 to NUM_PU-1)         of positions_by_pu_t;
    
    -- Input buffer may be either pivot or target shapelets
    signal input_buffer_s                               : shapelet_buffer_t;
    -- Register to count how many blocks of shapelet positions were already presented to the PUs, acting as a MUX selector for the shapelet . (reg_norm_count_s is an absolute element count)
    signal reg_block_sel_s                              : natural range 0 to LEN_MAX/NUM_PU;
    signal block_sel_rst_s                              : std_logic;
    signal block_sel_inc_s                              : std_logic;
    -- Matrix with processing units as rows and shapelet positions for each PU as columns
    signal output_matrix_s                              : pu_matrix_t;
    -- The shapelet positions presented to each of the NUM_PU processing elements
    signal shapelet_elements_mux_s                      : pu_operands_t;
    
begin
    -- Decrement reg_shapelet_length_s
    -- dec_length_s <= reg_shapelet_length_s - 1;
    
    -- buffer_pivot_in_s() <= data_i when reg_buf_state_s = Sfill_pivot else
                        -- ; -- when reg_norm_state_s = 
                        
    -- ---- REGISTER ARRAYS DEFINITION
    -- -- PIVOT DRIVER
    
    -- pivot_buf_wr_s <= '1' when ? else '0';
    
    -- PIVOT_BUFFER: process(clk) 
    -- begin
        -- if rising_edge(clk) then
            -- if rst_n = '0' or pivot_buf_rst_s = '1' then
                -- buffer_pivot_s <= (others => (others => '0'));
            -- else
                -- if pivot_buf_rst_s = '1' then
                    -- buffer_pivot_s <= (others => (others => '0'));
                
                -- elsif pivot_buf_wr_s = '1' then
                    -- buffer_pivot_s() <= buffer_pivot_in_s();
                
                -- end if;
            -- end if;
        -- end if;
    -- end process;
    
    
    -- INSERIR CODIGO DO JULIO
    
    
   
    -- TARGET DRIVER
    TARGET_BUFFER: process(clk) 
    begin
        if rising_edge(clk) then
            if rst_n = '0' or target_buf_rst_s = '1' then
                buffer_target_s <= (others => (others => '0'));
            else
                if target_buf_rst_s = '1' then
                    buffer_target_s <= (others => (others => '0'));
                elsif target_buf_wr_s = '1' then
                    buffer_target_s(reg_buf_counter_s) <= data_i;
                end if;
            end if;
        end if;
    end process;
    
    
     -- Decrement reg_shapelet_length_s
    dec_length_s <= reg_shapelet_length_s - 1;
    -- Buffers control signals
    pivot_buf_rst_s     <= '1' when reg_state_s = Sbuf_rst              and reg_op_s = '0' else '0';
    target_buf_rst_s    <= '1' when reg_state_s = Sbuf_rst              and reg_op_s = '1' else '0';
    pivot_buf_wr_s      <= '1' when (reg_state_s = Sbuf_load or reg_state_s = Sout_distance) and reg_op_s = '0' else '0';
    target_buf_wr_s     <= '1' when reg_state_s = Sbuf_load             and reg_op_s = '1' else '0';
    
    CONTROL_FSM: process(clk)
    begin
    if rising_edge(clk) then
        if rst_n = '0' then
            reg_state_s <= Sbegin;
            
        else
            case reg_state_s is
                when Sbegin         =>
                    reg_op_s <= op_i;
                    reg_buf_counter_s <= 0;
                    reg_acc_counter_s <= 0;
                    
                    if start_i = '1' then
                        -- Operation is set target
                        if op_i = '1' then
                            reg_state_s <= Sbuf_rst;
                        -- Operation is set pivot
                        else
                            reg_state_s <= Sset_len;
                        end if;
                    end if;
                    
                when Sset_len       => 
                    reg_shapelet_length_s <= length_i;
                    -- Next state
                    reg_state_s <= Sbuf_rst;
                
                when Sbuf_rst       =>
                    -- Next state
                    reg_state_s <= Sbuf_load;
                
                when Sbuf_load      => 
                    reg_buf_counter_s <= reg_buf_counter_s + 1;
                    
                    -- Next state
                    -- Reapeat until current buffer length = shapelet length - 1
                    if reg_buf_counter_s = reg_shapelet_length_s - 1 then
                        reg_state_s <= Snorm_square;
                    end if;
                    
                
                when Snorm_square   =>
                    
                    -- Next state
                    if mul_ready_s = '1' then
                        reg_norm_state_s <= Snorm_sum_acc;
                    end if;
                
                when Snorm_sum_acc  =>  
                    
                    -- Next state
                    if add_or_sub_ready_s = '1' then
                        reg_state_s <= Snorm_reg_acc;
                    end if;
                
                when Snorm_reg_acc  =>
                    reg_acc_counter_s <= reg_acc_counter_s + 1;
                    
                    -- Next state
                    if reg_acc_counter_s >= reg_shapelet_length_s then
                        reg_state_s <= Snorm_sqrt;
                    else
                        reg_state_s <= Snorm_square;
                    end if;
                
                when Snorm_sqrt     =>  
                    reg_acc_counter_s <= 0;
                    
                    -- Next state
                    if sqrt_ready_s = '1' then
                        reg_state_s <= Snorm_div;
                    end if;
                
                when Snorm_div      =>  
                    
                
                when Sdist_sub      =>  
                
                when Sdist_square   =>  
                
                when Sdist_sum_acc  =>  
                
                when Sdist_reg_acc  =>  
                
                when Swb_pivot      =>  
                
                when Sout_distance  =>  
                
            end case;
        end if;
        
    end process;
    
    
    
    -- ACCUMMULATOR DRIVER
    accumulators_wr_s  <= '1' when reg_state_s = Snorm_reg_acc or reg_state_s = Sdist_reg_acc else '0';
    -- Accummulator registers
    acc_regs: process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' or accumulators_rst_s = '1' then
                reg_accumulators_s <= (others => (others => '0'));
            else
                if accumulators_wr_s = '1' then
                    reg_accumulators_s <= addsub_out_s;
                end if;
            end if;
    end process;
    
    
    ---- MUX to present shapelet positions to the right Processing Units
    -- Selects which shapelet is presented to the MUX
    input_buffer_s <=   buffer_pivot_s  when reg_op_s = '0' else
                        buffer_target_s;

    -- GENERATE MUX inputs
    -- transform the linear input_buffer vector into a NUM_PE x LEN_MAX/NUM_PE matrix
    -- each LINE of the matrix represents all elements of the input_buffer that will be input into a mux
    -- at each input of the processing elements. 
    -- for NUM_PE=2 and LEN_MAX=8 we have a buff(7 downto 0)
    -- the matrix will be as follows:
    -- ||       col(0)  col(1)  col(2)  col(3)
    -- line(0)  buff(0) buff(2) buff(4) buff(6)             <-- these will form the inputs of mux(0)
    -- line(1)  buff(1) buff(3) buff(5) buff(7)             <-- these will form the inputs of mux(1)
    OUTER: for i in NUM_PU - 1 downto 0 generate
        INNER: for j in (LEN_MAX/NUM_PU - 1) downto 0 generate
            output_matrix_s(i)(j) <= input_buffer_s(i + j*NUM_PU);
        end generate INNER;
    end generate OUTER;
    
    -- Mux selector is a counter of how many blocks were processed to the moment (designed as a separate process so it can be set both in normalization and euclidean distance, do the same with reg_norm_count_s and reg_dist_count_s)
    block_sel_rst_s <= '1' when reg_state_s = Sbegin        or reg_state_s = Snorm_sqrt  else '0';
    block_sel_inc_s <= '1' when reg_state_s = Snorm_reg_acc or reg_state_s = Snorm_div else '0';
    
    reg_selector: process(clk)
    begin
        if rising_edge(clk) then
            if block_sel_rst_s = '1' then
                reg_block_sel_s <= 0;
            else if block_sel_inc_s = '1' then
                reg_block_sel_s <= reg_block_sel_s + 1;
            end if;
    end process;
    
    -- GENERATE NUM_PE muxes that will be the data inputs for each processing unit
    -- each mux formed by the LINES of the matrix. Each line containts 
    -- all the elements that will be processed by that unit.
    -- The sel signal is shared by all muxes created, so that
    -- each processing unit will recieve the signal 0 to LEN_MAX/NUM_PE
    -- for NUM_PE=2 and LEN_MAX=8 we have the following matrix
    -- ||       col(0)  col(1)  col(2)  col(3)
    -- line(0)  buff(0) buff(2) buff(4) buff(6)        <-- PE(0)
    -- line(1)  buff(1) buff(3) buff(5) buff(7)        <-- PE(1)
    --          ^       ^
    --          |       |
    --          sel=0   sel=1
    -- when sel=1, processing unit 0 will receive buff(2) and processing unit 1 will recieve buff(3)
    MUXES: for i in NUM_PU - 1 downto 0 generate
        shapelet_elements_mux_s(i) <= output_matrix_s(i)(reg_block_sel_s);
    end generate MUXES;
    
    
    ---- PROCESSING UNITS
    -- Addsub
    -- add_or_sub_s selcts if a addition='0' or subtraction='1' will be computed
    add_or_sub_s    <=  '1'                     when reg_state_s = Sdist_sub    else '0';
    addsub_opa_s    <=  div_out_s               when reg_state_s = Sdist_sub    else 
                        reg_accumulators_s;
    addsub_opb_s    <=  input_buffer_s          when reg_state_s = Sdist_sub    else
                        mul_out_s;

    -- Normalization output is division output
    norm_out_s      <=  div_out_s;

    -- Multiplier 
    mul_start_s     <= '0'                      when reg_state_s = Snorm_square or reg_state_s = Sdist_square   else '1';
    -- Square shapelet elements in normalization and the difference in euclidean distance calculation
    -- the multiplier unit always computes A*A (A^2)
    mul_operator_s  <=  shapelet_elements_mux_s when reg_state_s = Snorm_square     else 
                        addsub_out_s;
    
    -- Divider
    div_start_s  <= '0'                         when reg_state_s = Snorm_div        else '1';
    div_opa_s    <= shapelet_elements_mux_s;
    --operand b always recieves the signal sqrt_out_s!

    -- Generate processing units (adder/subtractor, multiplier, divider, square root)
    PROCESSING_UNITS: for i in 0 to NUM_PU - 1 generate
        -- Used in accumulator operation and subtraction during distance calculation
        -- ADDSUB computes in 6 cycles
        addsub: fp_addsub
        port map(
            clk_i 			=> clk,      
            op_type         => add_or_sub_s,                    -- 0 = add, 1 = sub
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
            start_i         => mul_start_s,
            opa_i        	=> mul_operator_s(i),                    -- Input Operands A & B
            opb_i           => mul_operator_s(i),
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
            start_i         => div_start_s,
            opa_i        	=> div_opa_s(i),                    -- Input Operands A & B
            opb_i           => sqrt_out_s,
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
    
    
    -- FUTURE: ADDER TREE
    -- Sum accumulators (NOW: assumes there are only 2 PUs)
    acc_sum_opa_s <= reg_accumulators_s(0);
    acc_sum_opb_s <= reg_accumulators_s(1);
    
    -- sums accumulator registers
    sum_accs: fp_addsub
    port map(
        clk_i 			=> clk,      
        op_type         => '0',                    -- 0 = add, 1 = sub
        opa_i        	=> acc_sum_opa_s,
        opb_i           => acc_sum_opb_s,
        output_o        => acc_sum_out_s,
        -- Exceptions
        ine_o 			=> open,                -- inexact
        overflow_o  	=> open,                -- overflow
        underflow_o 	=> open,                -- underflow
        inf_o			=> open,                -- infinity
        zero_o			=> open,                -- zero
        qnan_o			=> open,                -- queit Not-a-Number
        snan_o			=> open                 -- signaling Not-a-Number
    );
    
    -- Single SQRT unit
    sqrt_op <= acc_sum_out_s;
    sqrt_start_s <= '0'         when reg_state_s = Snorm_sqrt   else '1';
    
    -- Sqrt computes in 33 cycles
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
    
    
    -- Normalization combinational logic
    -- norm_count_inc_s <= reg_norm_count_s + NUM_PU;
    -- norm_ready_s    <= '1' when reg_norm_state_s = Send else '0';

    -- -- Normalization sequential logic
    -- NORMALIZE_SHAPELET: process(clk)
    -- begin
        -- if rising_edge(clk) then
            -- if rst_n = '0' then
                -- reg_norm_state_s <= Sbegin;
            -- else
                -- case reg_norm_state_s is 
                    -- when Sbegin =>
                        -- reg_norm_count_s <= 0;
                        
                        -- if norm_start_s = '1' then
                            -- reg_norm_state_s <= Ssquare;
                        -- end if;
                        
                    -- when Ssquare =>
                        
                        -- if mul_ready_s = '1' then -- instantiate
                            -- reg_norm_state_s <= Ssum;
                        -- end if;
                        
                    -- when Ssum =>
                        
                        -- if add_ready = '1' then           -- instatiate
                            -- reg_norm_state_s <= Sacc;
                        -- end if;
                        
                    -- when Sacc =>
                        -- reg_norm_count_s <= norm_count_inc_s;
                        
                        -- if reg_norm_count_s >= reg_shapelet_length_s then
                            -- reg_norm_state_s <= Ssqrt;
                        -- else 
                            -- reg_norm_state_s <= Ssquare;
                        -- end if;
                    
                    -- when Ssqrt =>
                        -- reg_norm_count_s <= 0;
                        
                        -- if sqrt_ready_s = '1' then          -- instantiate
                            -- reg_norm_state_s <= Sdiv;    
                        -- end if;
                    
                    
                    -- TODO:
                    -- when Sdiv =>
                        
                        -- if div_ready_s = '1' then           -- instantiate
                            -- reg_norm_state_s <= Sout_div;
                        -- end if;
                        
                    -- when Sout_div =>
                        -- reg_norm_count_s <= norm_count_inc_s;
                        
                        -- if reg_norm_count_s >= reg_shapelet_length_s then
                            -- reg_norm_state_s <= Send;
                        -- else 
                            -- reg_norm_state_s <= Sdiv;
                        -- end if;
                    
                    -- when Send =>
                        -- reg_norm_state_s <= Sbegin;
                    
                -- end case; 
            -- end if;
        -- end if;
    -- end process;
    
    
    
end behavioral;