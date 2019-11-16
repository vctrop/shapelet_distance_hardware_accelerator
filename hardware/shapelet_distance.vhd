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

    ---- SHAPELET BUFFERING DEFINITIONS 
    -- Define shapelet buffer and buffer fsm state types 
    type shapelet_buffer_t                              is array (0 to MAX_LEN - 1) of std_logic_vector(31 downto 0);
    type buffer_state_t                                 is (Sbegin, Srst_pivot, Srst_target, Sfill_pivot, Sfill_target, Send);
    -- Shapelet buffers (drivers are their separate processes)
    signal buffer_pivot_s                               : shapelet_buffer_t;
    signal buffer_target_s                              : shapelet_buffer_t;
    -- Buffers enable signals
    signal pivot_buf_wr_s                                 : std_logic;
    signal target_buf_wr_s                                : std_logic;    
    -- Buffer reset signals
    signal pivot_buf_rst_s                                : std_logic;
    signal target_buf_rst_s                               : std_logic;
    
    -- Buffer filling counter (driver is FILL_BUFFER)
    signal reg_buf_counter_s                            : natural range 0 to MAX_LEN;
    -- Incremented reg_buf_counter_s net (combinational)
    signal reg_buf_counter_inc_s                        : natural range 0 to MAX_LEN;
    -- Buffer ready flag (driver is FILL_BUFFER)
    signal buffer_ready_s                               : std_logic;
    -- Buffer FSM state (driver is FILL_BUFFER)
    signal reg_buf_state_s                               : buffer_state_t;
    -- Buffer start signal (driver is XXX_PROCESS)
    signal buffer_start_s                               : std_logic;
    -- Selects which buffer is filled (driver is XXX_PROCESS)
    -- '0': fill pivot
    -- '1': fill target
    signal fill_selector_s                              : std_logic;
    
    
    ---- SHAPELET NORMALIZATION DEFINITIONS
    -- Define normalization fsm state type
    type norm_state_t                                   is (Sbegin, Ssquare, Ssum, Sacc, Ssqrt, Sdiv, Sout_div);
    -- Normalization fsm state (driver is NORMALIZE_SHAPELET)
    signal reg_norm_state_s                                 : norm_state_t;
    -- Normalization start flag (driver is (XXX_PROCESS)
    signal norm_start_s                                 : std_logic;
    -- Normalization ready flag
    signal norm_ready_s                                 : std_logic;
    -- Selects which shapelet is normalized
    signal norm_selector_s                              : std_logic;
    -- Processed points counter register                        
    signal reg_norm_count_s                             : natural range 3 to MAX_LEN;
    -- reg_norm_count_s incremented by NUM_PU
    signal norm_count_inc_s                             : natural range 3 to MAX_LEN;
    -- Normalization outputs
    signal norm_out_s                                   : pu_operands_t;
    
    
    ---- SHAPELET DISTANCE DEFINITIONS
    -- Shapelet length register, ranging from 3 to MAX_LEN (driver is XXX_PROCESS)
    signal reg_shapelet_length_s                            : natural range 3 to MAX_LEN;
    -- Decremented shapelet length signal (combinational)
    signal dec_length_s                                 : natural range 3 to MAX_LEN;
    
    
    ---- FLOATING POINT OPERATORS
    -- PU's single precision floating point array types   
    type pu_operands_t                                  is array (0 to NUM_PU - 1) of std_logic_vector(31 downto 0); 
    
    -- Array of accumulator registers (combinational)
    signal reg_accumulators_s                           : pu_operands_t;
    signal accumulators_en_s                            : std_logic;
    
    -- addition/subtraction signals
    signal add_or_sub_s                                 : std_logic;   -- 0: add, 1: sub
    signal addsub_opa_s                                 : pu_operands_t;
    signal addsub_opb_s                                 : pu_operands_t;
    signal addsub_out_s                                 : pu_operands_t;
    -- multiplication signals                          
    signal mul_start_s                                  : std_logic;
    signal mul_operator_s                               : pu_operands_t;
    signal mul_out_s                                    : pu_operands_t;
    -- division signals                                
    signal div_start_s                                  : std_logic;
    signal div_opa_s                                    : pu_operands_t;
    signal div_opb_s                                    : pu_operands_t;
    signal div_out_s                                    : pu_operands_t;
    
    -- sum of accumulators
    signal acc_sum_opa_s                                : std_logic_vector(31 downto 0);
    signal acc_sum_opb_s                                : std_logic_vector(31 downto 0);
    signal acc_sum_out_s                                : std_logic_vector(31 downto 0);
    
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
    
    -- Shapelet selector, 0: pivot, 1:target
    signal shapelet_sel_s                               : std_logic;
    -- Input buffer may be either pivot or target shapelets
    signal input_buffer_s                               : shapelet_buffer_t;
    -- Register to count how many blocks of shapelet positions were already presented to the PUs, acting as a MUX selector for the shapelet . (reg_norm_count_s is an absolute element count)
    signal reg_block_sel_s                                 : natural range 0 to LEN_MAX/NUM_PU;
    signal block_sel_rst_s                                 : std_logic;
    signal block_sel_inc_s                                 : std_logic;
    -- Matrix with processing units as rows and shapelet positions for each PU as columns
    signal output_matrix_s                              : pu_matrix_t;
    -- The shapelet positions presented to each of the NUM_PU processing elements
    signal shapelet_elements_mux_s                      : pu_operands_t;
    
begin
    -- Decrement reg_shapelet_length_s
    dec_length_s <= reg_shapelet_length_s - 1;
    
    buffer_pivot_in_s() <= data_i when reg_buf_state_s = Sfill_pivot else
                        ; -- when reg_norm_state_s = 
                        
    ---- REGISTER ARRAYS DEFINITION
    -- PIVOT DRIVER
    pivot_buf_rst_s <= '1' when reg_buf_state_s = Srst_pivot else '0';
    pivot_buf_wr_s <= '1' when ? else '0';
    
    PIVOT_BUFFER: process(clk, rst_n, pivot_buf_rst_s, pivot_buf_wr_s) 
    begin
        if rising_edge(clk) then
            if rst_n = '0' or pivot_buf_rst_s = '1' then
                buffer_pivot_s <= (others => (others => '0'));
            else
                if pivot_buf_rst_s = '1' then
                    buffer_pivot_s <= (others => (others => '0'));
                
                elsif pivot_buf_wr_s = '1' then
                    buffer_pivot_s() <= buffer_pivot_in_s();
                
                end if;
            end if;
        end if;
    end process;
    
    
    -- INSERIR CODIGO DO JULIO
    
    
   
    -- TARGET DRIVER
    target_buf_wr_s <= '1' when reg_buf_state_s = fill_target else '0';
    target_buf_rst_s <= '1' when 
    TARGET_BUFFER: process(clk, rst_n, target_buf_rst_s, target_buf_wr_s) 
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
    
    
    ---- BUFFER FILLING
    buffer_ready_s <= '1' when reg_buf_state_s = Send else '0';
    -- Increment reg_buf_counter_s
    reg_buf_counter_inc_s <= reg_buf_counter_s + 1;
    -- Process to fill pivot and target buffers
    FILL_BUFFER: process(clk, rst_n, buffer_start_s, fill_selector_s)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                reg_buf_state_s <= Sbegin;
            else
                case reg_buf_state_s is
                    -- Reset ready, reg_buf_counter_s and decide buffer according to fill_cmd
                    when Sbegin =>
                        reg_buf_counter_s <= 0;
                        
                        -- Fill pivot shapelet
                        if buffer_start_s = '1' and fill_selector_s = '0' then
                            reg_buf_state_s <= Srst_pivot;
                        -- Fill target shapelet
                        else if buffer_start_s = '1' and fill_selector_s = '1' then
                            reg_buf_state_s <= Srst_target;
                        else
                            reg_buf_state_s <= Sbegin;
                        end if;
                        
                    -- Clear pivot buffer
                    when Srst_pivot =>
                        reg_buf_state_s <= Sfill_pivot;
                        
                    -- Clear target buffer
                    when Srst_target =>
                        reg_buf_state_s <= Sfill_target;
                         
                    -- Fill pivot shapelet
                    when Sfill_pivot =>
                        reg_buf_counter_s <= reg_buf_counter_inc_s;
                        
                        -- reapeat until len(buffer) = reg_shapelet_length_s
                        if reg_buf_counter_s = dec_length_s then
                            reg_buf_state_s <= Send;
                        else
                            reg_buf_state_s <= Sfill_pivot;
                        end if;
                    
                    -- Fill target shapelet
                    when Sfill_target =>
                        reg_buf_counter_s <= reg_buf_counter_inc_s;
                        
                        -- repeat until len(buffer) = reg_shapelet_length_s
                        if reg_buf_counter_s = dec_length_s then
                            reg_buf_state_s <= Send;
                        else
                            reg_buf_state_s <= Sfill_target;
                        end if;
                    
                    when Send =>
                        reg_buf_state_s <= Sbegin;
                end case;
            end if;
        end if;
    end process;
    
    -- ACCUMMULATOR DRIVER
    accumulators_en_s  <= '1' when reg_norm_state_s = Sacc else '0';
    -- Accummulator registers
        acc_regs: process(clk, rst_n, accumulators_en_s, accumulators_rst_s)
        begin
            if rising_edge(clk) then
                if rst_n = '0' or accumulators_rst_s = '1' then
                    reg_accumulators_s <= (others => (others => '0'));
                else
                    if accumulators_en_s = '1' then
                        reg_accumulators_s <= addsub_out_s;
                    end if;
                end if;
        end process;
    
    
    ---- MUX to present shapelet positions to the right Processing Units
    -- Selec which shapelet will go under the mux generated below
    shapelet_sel_s <=   '0' when ? else '1';
    
    -- Selects which shapelet is presented to the MUX
    input_buffer_s <=   buffer_pivot_s  when shapelet_sel_s = '0' else
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
        -- 
        INNER: for j in (LEN_MAX/NUM_PU - 1) downto 0 generate
            -- 
            output_matrix_s(i)(j) <= input_buffer_s(i + j*NUM_PU);
        end generate INNER;
        
    end generate OUTER;

    
    -- Mux selector is a counter of how many blocks were processed to the moment (designed as a separate process so it can be set both in normalization and euclidean distance, do the same with reg_norm_count_s and reg_dist_count_s)
    block_sel_rst_s <= '1' when reg_norm_state_s = Sbegin or reg_norm_state_s = Ssqrt  else '0';
    block_sel_inc_s <= '1' when reg_norm_state_s = Sacc or reg_norm_state_s = Sout_div else '0';
    
    reg_selector: process(clk, block_sel_rst_s, block_sel_inc_s)
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
    accumulators_en_s  <= '1' when reg_norm_state_s = Sacc else '0';

    -- Addsub
    -- add_or_sub_s selcts if a addition='0' or subtraction='1' will be computed
    add_or_sub_s <=  '0' when reg_norm_state_s = Ssum and reg_buf_state_s = Sbegin else '1';
    addsub_opa_s <=  reg_accumulators_s    when reg_norm_state_s = Ssum and reg_buf_state_s = Sbegin else 
                        div_out_s;
    addsub_opb_s <=  mul_out_s            when reg_norm_state_s = Ssum and reg_buf_state_s = Sbegin else
                        input_buffer_s;

    -- Normalization output is division output
    norm_out_s <= div_out_s;

    -- Multiplier 
    mul_start_s <= '0'  when reg_norm_state_s = Ssquare and reg_buf_state_s = Sbegin else '1';
    -- Square shapelet elements in normalization and the difference in euclidean distance calculation
    -- the multiplier unit always computes A*A (A^2)
    mul_operator_s <= shapelet_elements_mux_s  when reg_norm_state_s = Ssquare and reg_buf_state_s = Sbegin    else addsub_out_s;
    
    -- Divider
    div_start_s  <= '0' when reg_norm_state_s = Sdiv and reg_buf_state_s = Sbegin;
    div_opa_s    <= shapelet_elements_mux_s;
    --operand b always recieves the signal sqrt_out_s!

    -- Generate processing units (adder/subtractor, multiplier, divider, square root)
    PROCESSING_UNITS: for i in 0 to NUM_PU - 1 generate

        -- Accumulator registers
        acc_regs: process(clk, rst_n, accumulators_en_s)
        begin
            if rising_edge(clk) then
                if rst_n = '0' then
                    reg_accumulators_s(i) <= (others => (others => '0'));
                else
                    if accumulators_en_s = '1' then
                        reg_accumulators_s(i) <= addsub_out_s(i);
                    end if;
                end if;
        end process;
    
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
    sqrt_start_s <= '0' when reg_norm_state_s = Ssqrt and reg_buf_state_s = Sbegin else '1';
    
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
    norm_count_inc_s <= reg_norm_count_s + NUM_PU;
    norm_ready_s <= '1' when reg_norm_state_s = Send else '0';

    -- Normalization sequential logic
    NORMALIZE_SHAPELET: process(clk, rst_n, norm_start_s)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                reg_norm_state_s <= Sbegin;
            else
                case reg_norm_state_s is 
                    when Sbegin =>
                        reg_norm_count_s <= 0;
                        
                        if norm_start_s = '1' then
                            reg_norm_state_s <= Ssquare;
                        end if;
                        
                    when Ssquare =>
                        
                        if mul_ready_s = '1' then -- instantiate
                            reg_norm_state_s <= Ssum;
                        end if;
                        
                    when Ssum =>
                        
                        if add_ready = '1' then           -- instatiate
                            reg_norm_state_s <= Sacc;
                        end if;
                        
                    when Sacc =>
                        reg_norm_count_s <= norm_count_inc_s;
                        
                        if reg_norm_count_s >= reg_shapelet_length_s then
                            reg_norm_state_s <= Ssqrt;
                        else 
                            reg_norm_state_s <= Ssquare;
                        end if;
                    
                    when Ssqrt =>
                        reg_norm_count_s <= 0;
                        
                        if sqrt_ready_s = '1' then          -- instantiate
                            reg_norm_state_s <= Sdiv;    
                        end if;
                    
                    when Sdiv =>
                        
                        if div_ready_s = '1' then           -- instantiate
                            reg_norm_state_s <= Sout_div;
                        end if;
                        
                    when Sout_div =>
                        reg_norm_count_s <= norm_count_inc_s;
                        
                        if reg_norm_count_s >= reg_shapelet_length_s then
                            reg_norm_state_s <= Send;
                        else 
                            reg_norm_state_s <= Sdiv;
                        end if;
                    
                    when Send =>
                        reg_norm_state_s <= Sbegin;
                    
                end case; 
            end if;
        end if;
    end process;
    
    
    
end behavioral;