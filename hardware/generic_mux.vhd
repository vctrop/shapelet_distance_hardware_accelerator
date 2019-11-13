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
        sel_i : in natural range 0 to LEN_MAX/NUM_PE
    );
end entity;

architecture test of generic_mux is

    type buf is array(0 to LEN_MAX-1) of std_logic_vector(31 downto 0);
    type outbuf is array(0 to NUM_PE-1) of std_logic_vector(31 downto 0);
    type mat is array(0 to LEN_MAX/NUM_PE-1) of std_logic_vector(31 downto 0);
    type matrix is array(0 to NUM_PE-1) of mat;
    signal output_matrix : matrix;
    signal input_buffer : buf;
    signal output_mux : outbuf;
    signal sel : natural range 0 to LEN_MAX/NUM_PE;

begin
    sel <= sel_i;

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then 
                for i in input_buffer'range loop
                    input_buffer(i) <= std_logic_vector(to_unsigned(i, 32));
                end loop;
            end if;
        end if;
    end process;

    OUTER: for i in NUM_PE-1 downto 0 generate
        INNER: for j in LEN_MAX/NUM_PE-1 downto 0 generate
            output_matrix(i)(j) <= input_buffer(i + j*NUM_PE);
        end generate INNER;
    end generate OUTER;

    MUX: for i in NUM_PE-1 downto 0 generate
        output_mux(i) <= output_matrix(i)(sel);
    end generate MUX;

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