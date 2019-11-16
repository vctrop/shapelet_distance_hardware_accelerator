library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity generic_mux is
    generic (
        LEN_MAX : natural := 12;        -- length of the shapelet buffer. This MUST be a multiple of NUM_PE
        NUM_PE  : natural := 4         -- number of processing units. This MUST be a power of 2
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        data_i : in std_logic_vector(31 downto 0);
        address : in natural range 0 to LEN_MAX;
        fromMEM : in std_logic;
        wb_i : in std_logic;
        sel_i : in natural range 0 to LEN_MAX/NUM_PE-1
    );
end entity;

architecture test of generic_mux is
    type buf is array(0 to LEN_MAX-1) of std_logic_vector(31 downto 0);
    type outbuf is array(0 to NUM_PE-1) of std_logic_vector(31 downto 0);
    type mat is array(0 to LEN_MAX/NUM_PE-1) of std_logic_vector(31 downto 0);
    type matrix is array(0 to NUM_PE-1) of mat;
    type en_t is array(0 to LEN_MAX-1) of std_logic;

    signal output_matrix : matrix;
    signal input_buffer : buf;
    signal output_mux : outbuf;
    signal wb_input, reg_in : buf;
    signal buff_en, wr_buf : en_t;
    signal sel : natural range 0 to LEN_MAX/NUM_PE-1;

begin
    sel <= sel_i;

    ADDS: for i in input_buffer'range generate 
        wr_buf(i) <= '1' when address = i and fromMEM = '1' else '0';
    end generate;

    GEN_INPUT_BUFFER: for i in input_buffer'range generate
        process(clk, rst)
        begin 
            if rising_edge(clk) then
                if rst = '1' then
                    input_buffer(i) <= (others => '0');
                elsif buff_en(i) = '1' or wr_buf(i) = '1' then
                    input_buffer(i) <= wb_input(i);
                end if;
            end if;
        end process;
    end generate;
    
    GEN_WB_INPUT_J: for j in 0 to LEN_MAX/NUM_PE-1 generate
        GEN_WB_INPUT_I: for i in 0 to NUM_PE-1 generate
            buff_en(i + j*NUM_PE) <= '1' when sel = j and wb_i = '1' else '0'; 
            wb_input(i + j*NUM_PE) <= data_i when fromMEM = '1' else output_mux(i);
        end generate;
    end generate;

    -- GENERATE MUX inputs
    -- transform the linear input_buffer vector into a NUM_PE x LEN_MAX/NUM_PE matrix
    -- each LINE of the matrix represents all elements of the input_buffer that will be input into a mux
    -- at each input of the processing elements. 
    -- for NUM_PE=2 and LEN_MAX=8 we have a buff(7 downto 0)
    -- the matrix will be as follows:
    -- ||       col(0)  col(1)  col(2)  col(3)
    -- line(0)  buff(0) buff(2) buff(4) buff(6)             <-- these will form the inputs of mux(0)
    -- line(1)  buff(1) buff(3) buff(5) buff(7)             <-- these will form the inputs of mux(1)
    OUTER: for i in NUM_PE-1 downto 0 generate
        INNER: for j in LEN_MAX/NUM_PE-1 downto 0 generate
            output_matrix(i)(j) <= input_buffer(i + j*NUM_PE);
        end generate INNER;
    end generate OUTER;

    -- GENERATE NUM_PE muxes that will be the data inputs for each processing unit
    -- each mux formed by the LINES of the matrix. Each line containts 
    -- all the elements that will be processed by that unit.
    -- The sel signal is shared by all muxes created, so that
    -- each processing unit will recieve the signal 0 to LEN_MAX/NUM_PE
    -- for NUM_PE=2 and LEN_MAX=8 we have the following matrix
    -- ||       col(0)  col(1)  col(2)  col(3)
    -- line(0)  buff(0) buff(2) buff(4) buff(6)  
    -- line(1)  buff(1) buff(3) buff(5) buff(7)
    --          ^       ^
    --          |       |
    --          sel=0   sel=1
    -- when sel=1, processing unit 0 will receive buff(2) and processing unit 1 will recieve buff(3)
    MUX: for i in NUM_PE-1 downto 0 generate
        output_mux(i) <= output_matrix(i)(sel);
    end generate MUX;

    -- generate the inputs of the buffer

    
end test ;

-- architecture type2 of generic_mux is

--     type buf is array(0 to LEN_MAX) of std_logic_vector(31 downto 0);
--     signal input_buffer, output_mux: buf;
--     signal sel : natural range 0 to LEN_MAX/NUM_PE;

-- begin

--     for i in input_buffer'range loop
--         input_buffer(i) <= std_logic_vector(to_unsigned(i, i'length));
--     end loop;

--     MUX: for i in range NUM_PE downto 0 generate
--         output_mux(i) <= input_buffer(i + sel*NUM_PE);
--     end generate MUX;
    
-- end type2 ; 