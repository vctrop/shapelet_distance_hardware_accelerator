library IEEE;
use IEEE.numeric_std.all;
use ieee.std_logic_1164.all;

use work.comppack.all;
-- 
-- 
-- 

entity shapelet_distance is
    generic(
        -- Number of processig units (each PU is composed of square, accumulate, sub and div)
        NUM_PU      : natural := 2;
        -- Maximum shapelet length (must be multiple of NUM_PU)
        MAX_LEN     : natural := 12
    );
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        
        -- Operation
        -- '0': set shapelet LENGTH and  change the pivot shapelet and normalize it
        -- '1': change target shapelet and compute distance
        op_i        : in std_logic;
        
        -- Data input is a single precision float shapelet datapoint
        data_i      : in std_logic_vector(31 downto 0);
        length_i    : in natural range 0 to MAX_LEN-1;

        -- begins opeartions
        start_i     : in std_logic;        
        -- Ready flag for operation completion
        ready_o     : out std_logic;
        --distance result
        distance_o  : out std_logic_vector(31 downto 0)
    );
end shapelet_distance;

architecture behavioral of shapelet_distance is
    
    -- Flip-flop to keep the desired operation constant during the entire processing
    signal reg_op_s                                     : std_logic;
    
    -- Register to keep the shapelet length
    signal reg_shapelet_length_s                        : natural range 0 to MAX_LEN-1;
   
    -- Register to keep output result
    signal reg_distance_s                               : std_logic_vector(31 downto 0);

    -- Shapelet distance FSM states definition
    type fsm_state_t                                    is (Sbegin, Sbuf_rst, Sbuf_load,
                                                            Snorm_square, Snorm_sum_acc, Snorm_reg_acc, Snorm_final_acc, Snorm_sqrt, Snorm_div, 
                                                            Sdist_sub, Sdist_square, Sdist_sum_acc, Sdist_reg_acc,
                                                            Swb_pivot, Snorm_ready, Sdist_final_acc, Sout_distance);
    -- Register to keep FSM state
    signal reg_state_s                                  : fsm_state_t;
    
     
    -- Buffer filling counter and its incremented by 1 version
    signal reg_buf_counter_s                            : natural range 0 to MAX_LEN;
    -- Operation counter and its incremented by NUM_PU version
    signal reg_acc_counter_s                            : natural range 0 to MAX_LEN;
    signal inc_acc_counter_s                            : natural range 0 to MAX_LEN;
    ---- SHAPELET BUFFERING DEFINITIONS 
    -- Define shapelet buffer and buffer fsm state types 
    type shapelet_buffer_t                              is array (0 to MAX_LEN - 1) of std_logic_vector(31 downto 0);
    -- Defines the en signal for each element of pivot buffer
    type pivot_en_t                                           is array (0 to MAX_LEN - 1) of std_logic;

    -- Shapelet pivot buffer
    signal buffer_pivot_s                               : shapelet_buffer_t;
    signal pivot_buf_rst_s                              : std_logic;
    signal en_pivot_load_s                              : pivot_en_t; --pivot enable for each element of pivot_buffer_s when loading elements from data_i
    signal en_pivot_wb_s                                : pivot_en_t; --pivot enable for each element of pivot_buffer_s when writting back PU's results
    signal pivot_input_s                                : shapelet_buffer_t;  -- mux that selects between data_i and PU's outputs
    -- Shapelet target buffer
    signal buffer_target_s                              : shapelet_buffer_t;
    signal target_buf_wr_s                              : std_logic;   
    signal target_buf_rst_s                             : std_logic; 

    ---- FLOATING POINT OPERATORS
    -- PU's single precision floating point array types   
    type pu_operands_t                                  is array (0 to NUM_PU - 1) of std_logic_vector(31 downto 0); 
    
    -- Array of accumulator registers
    signal reg_accumulators_s                           : pu_operands_t;
    signal reg_final_accumulator_s                      : std_logic_vector(31 downto 0);    -- holds the sum of every reg_acumulator 
    signal accumulators_wr_s                            : std_logic;
    signal accumulators_rst_s                           : std_logic;
    
    -- Cycle counter signals
    signal counter_start_s                              : std_logic;
    signal counter_mode_s                               : std_logic_vector(1 downto 0);
    
    -- All floating point operations are flagged ready by the same signal
    signal fp_ready_s                                   : std_logic;
    
    -- addition/subtraction signals
    signal add_or_sub_s                                 : std_logic;   -- 0: add, 1: sub
    signal addsub_opa_s                                 : pu_operands_t;
    signal addsub_opb_s                                 : pu_operands_t;
    signal addsub_out_s                                 : pu_operands_t;
    signal addsub_start_s                               : std_logic;    -- used to start the cycle counter
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
    signal sqrt_op_s                                    : std_logic_vector(31 downto 0);
    signal sqrt_out_s                                   : std_logic_vector(31 downto 0);
    
    -- PU output registers:
    signal reg_addsub_out_s : pu_operands_t;
    signal reg_mul_out_s : pu_operands_t;
    signal reg_div_out_s : pu_operands_t;
    signal reg_sqrt_out_s : std_logic_vector(31 downto 0);
    signal reg_acc_sum_out_s : std_logic_vector(31 downto 0);

    ---- SHAPELETS POSITIONS MUX
    --
    type positions_by_pu_t                              is array(0 to MAX_LEN/NUM_PU-1)  of std_logic_vector(31 downto 0);
    -- 
    type pu_matrix_t                                    is array(0 to NUM_PU-1)         of positions_by_pu_t;
    
    -- Input buffer may be either pivot or target shapelets
    signal input_buffer_s                               : shapelet_buffer_t;
    -- Register to count how many blocks of shapelet positions were already presented to the PUs, acting as a MUX selector for the shapelet . (reg_acc_count_s is an absolute element count)
    signal reg_block_sel_s                              : natural range 0 to MAX_LEN/NUM_PU-1;
    signal block_sel_rst_s                              : std_logic;
    signal block_sel_inc_s                              : std_logic;
    -- Matrix with processing units as rows and shapelet positions for each PU as columns
    signal matrix_representation_s                              : pu_matrix_t;
    -- The shapelet positions presented to each of the NUM_PU processing elements
    signal shapelet_elements_mux_s                      : pu_operands_t;
    
begin
    -- PIVOT BUFFER 
    -- enables writing to pivot buffer when loading values from data_i during operation 0
    ADDS: for i in buffer_pivot_s'range generate 
        en_pivot_load_s(i) <= '1' when reg_buf_counter_s = i and reg_state_s = Sbuf_load and reg_op_s = '0' else '0';
    end generate;

    -- 
    GEN_WB_INPUT_J: for j in 0 to MAX_LEN/NUM_PU-1 generate
        GEN_WB_INPUT_I: for i in 0 to NUM_PU-1 generate
            -- enables writing to corresponding pivot buffer elements when writing back after normalization
            en_pivot_wb_s(i + j*NUM_PU) <= '1' when reg_block_sel_s = j and reg_state_s = Swb_pivot else '0'; 
            -- selects if the pivot buffer will receive data from data_i or data from PU's
            pivot_input_s(i + j*NUM_PU) <= data_i when reg_state_s = Sbuf_load else div_out_s(i);
        end generate;
    end generate;

    -- the pivot buffer receives data from PU's or data_i
    -- the elements that will be loaded from data_i are enabled by en_pivot_load_s
    -- the elements that will be written back are enabled by en_pivot_wb_s
    GEN_PIVOT_BUFFER: for i in buffer_pivot_s'range generate
        process(clk)
        begin 
            if rising_edge(clk) then
                if rst = '0' or pivot_buf_rst_s = '1' then
                    buffer_pivot_s(i) <= (others => '0');
                elsif en_pivot_load_s(i) = '1' or en_pivot_wb_s(i) = '1' then
                    buffer_pivot_s(i) <= pivot_input_s(i);
                end if;
            end if;
        end process;
    end generate;
    
    
    -- TARGET BUFFER
    TARGET_BUFFER: process(clk) 
    begin
        if rising_edge(clk) then
            if rst = '0' or target_buf_rst_s = '1' then
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
    
    -- Entity outputs
    distance_o  <= reg_distance_s;
    ready_o     <= '1' when reg_state_s = Sout_distance or reg_state_s = Snorm_ready else '0';
    
    -- Increment reg_acc_counter_s out of process to create a single adder
    inc_acc_counter_s <= reg_acc_counter_s + NUM_PU;
    
    -- Buffers control signals
    pivot_buf_rst_s     <= '1' when reg_state_s = Sbuf_rst              and reg_op_s = '0' else '0';
    target_buf_rst_s    <= '1' when reg_state_s = Sbuf_rst              and reg_op_s = '1' else '0';
    target_buf_wr_s     <= '1' when reg_state_s = Sbuf_load             and reg_op_s = '1' else '0';
    
    CONTROL_FSM: process(clk)
    begin
    if rising_edge(clk) then
        if rst = '0' then
            reg_state_s <= Sbegin;
            reg_distance_s <= (others => '0');
        else
            case reg_state_s is
                when Sbegin         =>
                    reg_op_s <= op_i;
                    -- reg_buf_counter_s e reg_acc_counter_s podem ser unidos num só reg
                    reg_buf_counter_s <= 0;
                    reg_acc_counter_s <= 0;
                    
                    if start_i = '1' then
                        -- Operation is set pivot and change length
                        if op_i = '0' then
                            reg_shapelet_length_s <= length_i;
                            reg_state_s <= Sbuf_rst;
                        end if;
                        reg_state_s <= Sbuf_rst;
                    end if;
                
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
                    -- Is multiplication ready?
                    if fp_ready_s = '1' then                
                        reg_state_s <= Snorm_sum_acc;
                    end if;
                
                when Snorm_sum_acc  =>  
                    
                    -- Next state
                    -- Is sum ready?
                    if fp_ready_s = '1' then
                        reg_state_s <= Snorm_reg_acc;
                    end if;
                
                when Snorm_reg_acc  =>
                    reg_acc_counter_s <= inc_acc_counter_s;
                    
                    -- Next state
                    -- checks if the next iteration will exceed the shapelet length
                    -- this is to offset the fact that we begin the iterations at 0
                    if inc_acc_counter_s >= reg_shapelet_length_s then
                        reg_state_s <= Snorm_final_acc;
                    else
                        reg_state_s <= Snorm_square;
                    end if;
                
                when Snorm_final_acc =>
                    -- sums each PU's accumulators 
                    if fp_ready_s = '1' then
                        reg_state_s <= Snorm_sqrt;
                    end if;
                    
                when Snorm_sqrt     =>  
                    reg_acc_counter_s <= 0;
                    
                    -- Next state
                    -- Is sqrt ready?
                    if fp_ready_s = '1' then
                        reg_state_s <= Snorm_div;
                    end if;
                    
                when Snorm_div      =>  
                    
                    -- Next state
                    -- Is division ready?
                    if fp_ready_s = '1' then
                        -- Operating with pivot shapelet
                        if reg_op_s = '0' then
                            reg_state_s <= Swb_pivot;
                        -- Operating with target shapelet
                        else
                            reg_state_s <= Sdist_sub;
                        end if;
                    end if;
                    
                
                when Swb_pivot      =>  
                    reg_acc_counter_s <= inc_acc_counter_s;
                    
                    -- Next state
                    -- checks if the next iteration will exceed the shapelet length
                    -- this is to offset the fact that we begin the iterations at 0
                    if inc_acc_counter_s >= reg_shapelet_length_s then
                        reg_state_s <= Snorm_ready;
                    else
                        reg_state_s <= Snorm_div;
                    end if; 

                when Snorm_ready    =>
                    -- activate ready signal for 1 cycle at the end of operation 0
                    reg_state_s <= Sbegin;    -- end operation 0  
                    
                when Sdist_sub      =>  
                        
                    -- Next state
                    -- Is subtraction ready?
                    if fp_ready_s = '1' then
                        reg_state_s <= Sdist_square;
                    end if;
                    
                when Sdist_square   =>  
                    
                    -- Next state
                    -- Is multiplication ready?
                    if fp_ready_s = '1' then
                        reg_state_s <= Sdist_sum_acc;
                    end if;
                
                when Sdist_sum_acc  =>  
                    
                    -- Next state
                    -- Is sum ready?
                    if fp_ready_s = '1' then
                        reg_state_s <= Sdist_reg_acc;
                    end if;
                
                when Sdist_reg_acc  =>  
                    reg_acc_counter_s <= inc_acc_counter_s;
                    
                    -- Next state
                    -- checks if the next iteration will exceed the shapelet length
                    -- this is to offset the fact that we begin the iterations at 0
                    if inc_acc_counter_s >= reg_shapelet_length_s then
                        reg_state_s <= Sdist_final_acc;
                    else
                        reg_state_s <= Snorm_div;
                    end if;
                    
                when Sdist_final_acc =>
                    -- sums each PU's accumulators
                    if fp_ready_s = '1' then
                        reg_state_s <= Sout_distance;
                    end if;

                when Sout_distance  =>
                    reg_distance_s <= reg_acc_sum_out_s;
                    reg_state_s <= Sbegin;          -- end operation 1
                
            end case;
        end if;
    end if;    
    end process;
    
    ---- MUX to present shapelet positions to the right Processing Units
    -- Selects which shapelet is presented to the MUX
    input_buffer_s <=   buffer_pivot_s  when reg_op_s = '0' or (reg_op_s = '1' and reg_state_s = Sdist_sub) else
                        buffer_target_s;

    -- GENERATE MUX inputs
    -- transform the linear input_buffer vector into a NUM_PU x MAX_LEN/NUM_PU matrix
    -- each LINE of the matrix represents all elements of the input_buffer that will be input into a mux
    -- at each input of the processing elements. 
    -- for NUM_PU=2 and MAX_LEN=8 we have a buff(7 downto 0)
    -- the matrix will be as follows:
    -- ||       col(0)  col(1)  col(2)  col(3)
    -- line(0)  buff(0) buff(2) buff(4) buff(6)             <-- these will form the inputs of mux(0)
    -- line(1)  buff(1) buff(3) buff(5) buff(7)             <-- these will form the inputs of mux(1)
    OUTER: for i in NUM_PU - 1 downto 0 generate
        INNER: for j in (MAX_LEN/NUM_PU - 1) downto 0 generate
            matrix_representation_s(i)(j) <= input_buffer_s(i + j*NUM_PU);
        end generate INNER;
    end generate OUTER;
    
    -- Mux selector is a counter of how many blocks were processed to the moment 
    block_sel_rst_s <= '1' when reg_state_s = Sbegin        or reg_state_s = Snorm_sqrt                                 else '0';
    block_sel_inc_s <= '1' when reg_state_s = Snorm_reg_acc or reg_state_s = Swb_pivot or reg_state_s = Sdist_reg_acc   else '0';
    
    reg_selector: process(clk)
    begin
        if rising_edge(clk) then
            if block_sel_rst_s = '1' then
                reg_block_sel_s <= 0;
            elsif block_sel_inc_s = '1' then
                reg_block_sel_s <= reg_block_sel_s + 1;
            end if;
        end if;
    end process;
    
    -- GENERATE NUM_PU muxes that will be the data inputs for each processing unit
    -- each mux formed by the LINES of the matrix. Each line containts 
    -- all the elements that will be processed by that unit.
    -- The sel signal is shared by all muxes created, so that
    -- each processing unit will recieve the signal 0 to MAX_LEN/NUM_PU
    -- for NUM_PU=2 and MAX_LEN=8 we have the following matrix
    -- ||       col(0)  col(1)  col(2)  col(3)
    -- line(0)  buff(0) buff(2) buff(4) buff(6)        <-- PE(0)
    -- line(1)  buff(1) buff(3) buff(5) buff(7)        <-- PE(1)
    --          ^       ^
    --          |       |
    --          sel=0   sel=1
    -- eg. when sel=1, processing unit 0 will receive buff(2) and processing unit 1 will recieve buff(3)
    MUXES: for i in NUM_PU - 1 downto 0 generate
        shapelet_elements_mux_s(i) <= matrix_representation_s(i)(reg_block_sel_s);
    end generate MUXES;
    
    
    ---- PROCESSING UNITS
    -- Addsub
    -- add_or_sub_s selcts if a addition='0' or subtraction='1' will be computed
    add_or_sub_s    <=  '1'                     when reg_state_s = Sdist_sub    else '0';
    addsub_opa_s    <=  reg_div_out_s           when reg_state_s = Sdist_sub    else 
                        reg_accumulators_s; 
    addsub_opb_s    <=  shapelet_elements_mux_s when reg_state_s = Sdist_sub    else
                        reg_mul_out_s;
    addsub_start_s <= '0'                       when reg_state_s = Snorm_sum_acc or reg_state_s = Sdist_sub or reg_state_s = Sdist_sum_acc
                                                or reg_state_s = Snorm_final_acc or reg_state_s = Sdist_final_acc else '1';     -- final accumulator states

    -- Multiplier 
    mul_start_s     <= '0'                      when reg_state_s = Snorm_square or reg_state_s = Sdist_square   else '1';
    -- Square shapelet elements in normalization and the difference in euclidean distance calculation
    -- the multiplier unit always computes A*A (A^2)
    mul_operator_s  <=  shapelet_elements_mux_s when reg_state_s = Snorm_square     else 
                        reg_addsub_out_s;
    
    -- Divider
    div_start_s  <= '0'                         when reg_state_s = Snorm_div        else '1';
    div_opa_s    <= shapelet_elements_mux_s;
    --operand b always recieves the signal reg_sqrt_out_s!

    -- Start cycle counter when an operation start is set down
    counter_start_s <= '1'  when addsub_start_s = '0' or mul_start_s = '0' or div_start_s = '0' or sqrt_start_s = '0' else '0';
    -- Counter mode
    counter_mode_s  <=  "00" when reg_state_s = Snorm_sum_acc or reg_state_s = Snorm_final_acc or reg_state_s = Sdist_final_acc else        -- Addition
                        "01" when reg_state_s = Snorm_div   or reg_state_s = Snorm_sqrt else        -- Division and square root
                        "10"; -- when reg_state_s = Snorm_square or reg_state_s = Sdist_square      -- Multiplication
    
    cycle_counter: entity work.cycle_counter
    port map(   
        clk     => clk,
        rst     => rst,
        -- mode defines the number of cycles to count down
        -- 00 = 6   ( add / sub)
        -- 01 = 33  ( division or sqrt)
        -- 10 = 11  ( multiplication )
        -- 11 = 0     
        mode_i  => counter_mode_s,

        start_i => counter_start_s,   -- start countdown
        ready_o => fp_ready_s  -- ready signal indicating cycle_counter has finished counting. Active for 1 clock cycle
    
    );
    
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
            opb_i           => reg_sqrt_out_s,
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
    end generate PROCESSING_UNITS; 
    
    
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
    sqrt_op_s <= reg_acc_sum_out_s;
    sqrt_start_s <= '0'         when reg_state_s = Snorm_sqrt   else '1';
    
    -- Sqrt computes in 33 cycles
    sqrt: fp_sqrt
    port map(
        clk_i 			=> clk,
        start_i         => sqrt_start_s,
        opa_i        	=> sqrt_op_s,
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
        
    -- registers that save the PU's results
    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                reg_addsub_out_s <= (others => (others => '0'));
                reg_mul_out_s <= (others => (others => '0'));
                reg_div_out_s <= (others => (others => '0'));
                reg_sqrt_out_s <= (others => '0');
                reg_acc_sum_out_s <= (others => '0');
            elsif fp_ready_s = '1' then
                if reg_state_s = Snorm_square or reg_state_s = Sdist_square then
                    reg_mul_out_s <= mul_out_s;
                end if;
                -- the accumulation operations are registered on a separate register (see acc_regs process)
                if reg_state_s = Sdist_sub then
                    reg_addsub_out_s <= addsub_out_s;
                end if;
                -- the write back stage during operation 0 writes directly to pivot_buffer
                if reg_state_s = Snorm_div then
                    reg_div_out_s <= div_out_s;
                end if;
                if reg_state_s = Snorm_sqrt then
                    reg_sqrt_out_s <= sqrt_out_s;
                end if;
                if reg_state_s = Snorm_final_acc or reg_state_s = Sdist_finaL_acc then
                    reg_acc_sum_out_s <= acc_sum_out_s;
                end if;
            end if;
        end if;
    end process;

    -- ACCUMMULATOR DRIVER
    -- reset the accumulator at the start of the FSM and after taking the square root during normalization.
    accumulators_rst_s  <= '1' when reg_state_s = Sbegin        or (reg_state_s = Snorm_sqrt and fp_ready_s = '1')    else '0';
    accumulators_wr_s   <= '1' when reg_state_s = Snorm_reg_acc or reg_state_s = Sdist_reg_acc      else '0';
    -- Accummulator registers
    acc_regs: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' or accumulators_rst_s = '1' then
                reg_accumulators_s <= (others => (others => '0'));
            else
                if accumulators_wr_s = '1' then
                    reg_accumulators_s <= addsub_out_s;
                end if;
            end if;
        end if;
    end process;


end behavioral;
