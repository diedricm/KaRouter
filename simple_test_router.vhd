library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.numeric_std.all;
library work;
	use work.karouter_pack.all;

--A very simple router that is used to debug and test KaRouters components.
--Contains 4 input and output ports.

entity simple_test_router is
generic (
    PORTCNT         : integer := 4;
    BLOCKWIDTH      : integer := 32
);
port (
    clk             : in std_logic;
    reset           : in std_logic;
    
    --Config interface
    addr_in         : in std_logic_vector(31 downto 0);
    memory_in       : in std_logic_vector(31 downto 0);
    
    --Router data signals
    input_data          : in  std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
    output_data         : out std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
    
    --Start/stop controll
    --Set this if data on input is valid
    prev_valid          : in  boolean_vector(PORTCNT-1 downto 0);
    
    --Set this if you want to recieve data
    next_valid          : in  boolean_vector(PORTCNT-1 downto 0);
    
    --Is set if input will be accepted 
    output_to_prev_valid: out boolean_vector(PORTCNT-1 downto 0);
    
    --Is set if this port should drop the current package
    output_to_prev_drop : out boolean_vector(PORTCNT-1 downto 0);
    
    --Is set if output is valid
    output_to_next_valid: out boolean_vector(PORTCNT-1 downto 0)
);
end simple_test_router ;

architecture Behavioral of simple_test_router is
    constant QUEUE_DEPTH : integer := 5;
    constant CONFIGWIDTH : integer := 32;

    signal data_queue_to_swe : std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
    signal req_queue_to_swe  : bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    signal valid_queue_to_swe: boolean_vector(PORTCNT-1 downto 0);
    signal valid_swe_to_queue: boolean_vector(PORTCNT-1 downto 0);
    signal drop_event        : boolean_vector(PORTCNT-1 downto 0);
    signal outport_mask      : bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    signal dest_class_data   : std_lgk_vec_2d(PORTCNT-1 downto 0)(QUEUE_DEPTH*BLOCKWIDTH-1 downto 0);
begin

    input_classificators: for i in PORTCNT-1 downto 0 generate
        inp_queue: input_queue
        generic map (
            QUEUE_DEPTH     => QUEUE_DEPTH,
            BLOCKWIDTH      => BLOCKWIDTH,
            PORTCNT         => PORTCNT
        )
        port map (
            clk             => clk,
            reset           => reset,
            output_dest_data=> dest_class_data(i),
            outport_mask    => outport_mask(i),
            self_request_vec=> req_queue_to_swe(i),
            drop_event      => drop_event(i),
            prev_valid      => prev_valid(i),
            next_valid      => valid_swe_to_queue(i),
            output_drop_event => output_to_prev_drop(i),
            output_to_prev_valid => output_to_prev_valid(i),
            output_to_next_valid => valid_queue_to_swe(i),
            input_data      => input_data(i),
            output_data     => data_queue_to_swe(i)
        );
        
        class_sock: classifier_socket
        generic map (
            BLOCKWIDTH      => BLOCKWIDTH,
            PORTCNT         => PORTCNT,
            CLASSDATAWIDTH  => QUEUE_DEPTH,
            CONFIGWIDTH     => CONFIGWIDTH      
        )
        port map (
            clk             => clk,
            addr_in         => addr_in,
            memory_in       => memory_in,
            data_in         => dest_class_data(i),
            drop_packet     => drop_event(i),
            outport_mask    => outport_mask(i)
        );
    end generate input_classificators;
    
    sw_engine: switching_engine
    generic map (
        PORTCNT => PORTCNT,
        BLOCKWIDTH => BLOCKWIDTH
    )
    port map (
        clk             => clk,
        reset           => reset,
        prev_request_vec=> req_queue_to_swe,
        input_data_vec  => data_queue_to_swe,
        output_data_vec => output_data,
        prev_valid_vec  => valid_queue_to_swe,
        next_valid_vec  => next_valid,
        output_to_prev_valid=> valid_swe_to_queue,
        output_to_next_valid=> output_to_next_valid
    );
end Behavioral;