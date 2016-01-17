library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.numeric_std.all;
library work;
	use work.karouter_pack.all;

entity input_queue_tb is
end input_queue_tb;

architecture Behavioral of input_queue_tb is
    constant clk_period : time := 10 ns;
    constant BLOCKWIDTH  : integer := 32;
    constant PORTCNT     : integer := 4;
    constant QUEUE_DEPTH : integer := 5;
    
    type int_arr is array(INTEGER range <>) of integer;

    signal clk : std_logic;
    signal reset : std_logic;
    signal output_dest_data : std_logic_vector((QUEUE_DEPTH*BLOCKWIDTH)-1 downto 0);
    signal outport_mask : boolean_vector(PORTCNT-1 downto 0);
    signal self_request_vec : boolean_vector(PORTCNT-1 downto 0);
    signal drop_event : boolean;
    signal prev_valid : boolean;
    signal next_valid : boolean;
    signal output_drop_event : boolean;
    signal output_to_prev_valid : boolean;
    signal output_to_next_valid : boolean;
    signal input_data : std_logic_vector(BLOCKWIDTH-1 downto 0);
    signal output_data : std_logic_vector(BLOCKWIDTH-1 downto 0);
begin

    testrun: process
    begin
        reset <= '1';
        prev_valid <= false;
        next_valid <= false;
        
        wait for clk_period;
        
        reset <= '0';

        wait for clk_period;

        prev_valid <= true;
        next_valid <= false;
        input_data <= std_logic_vector(to_unsigned(8, input_data'length));
        
        wait for clk_period;
        
        input_data <= std_logic_vector(to_unsigned(2, input_data'length));
        
        wait for clk_period;
        
        input_data <= std_logic_vector(to_unsigned(3, input_data'length));
                
        wait for clk_period;
                
        input_data <= std_logic_vector(to_unsigned(4, input_data'length));
        
        wait for clk_period;
        
        input_data <= std_logic_vector(to_unsigned(5, input_data'length));

        wait for clk_period;
        
	next_valid <= true;
        input_data <= std_logic_vector(to_unsigned(6, input_data'length));
	assert (output_data = std_logic_vector(to_unsigned(8, output_data'length))) report "1. Block not correct" severity error;

        wait for clk_period;
        
	prev_valid <= false;
        input_data <= std_logic_vector(to_unsigned(404, input_data'length));

        wait for clk_period;

       	assert (output_data = std_logic_vector(to_unsigned(2, output_data'length))) report "2. Block not correct" severity error;

        wait for clk_period;

	prev_valid <= true;
        input_data <= std_logic_vector(to_unsigned(7, input_data'length));

        wait for clk_period;

        input_data <= std_logic_vector(to_unsigned(8, input_data'length));
	assert (output_data = std_logic_vector(to_unsigned(3, output_data'length))) report "3. Block not correct" severity error;

        wait for clk_period;

	assert (output_data = std_logic_vector(to_unsigned(4, output_data'length))) report "4. Block not correct" severity error;

        wait for clk_period;

	assert (output_data = std_logic_vector(to_unsigned(5, output_data'length))) report "5. Block not correct" severity error;

        wait for clk_period;

	assert (output_data = std_logic_vector(to_unsigned(6, output_data'length))) report "6. Block not correct" severity error;

        wait for clk_period;

	assert (output_data = std_logic_vector(to_unsigned(7, output_data'length))) report "7. Block not correct" severity error;

        wait for clk_period;

	assert (output_data = std_logic_vector(to_unsigned(8, output_data'length))) report "8. Block not correct" severity error;
	prev_valid <= false;

        wait for clk_period;

        wait for clk_period;

        wait for clk_period;

        wait;
    end process;

    clk_generate :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    uut: input_queue
    generic map (
        QUEUE_DEPTH     => QUEUE_DEPTH,
        BLOCKWIDTH      => BLOCKWIDTH,
        PORTCNT         => PORTCNT
    )
    port map (
        clk             => clk,
        reset           => reset,
        output_dest_data=> output_dest_data, 
        outport_mask    => outport_mask,
        self_request_vec=> self_request_vec,
        drop_event      => drop_event,
        prev_valid      => prev_valid,
        next_valid      => next_valid,
        output_drop_event=> output_drop_event,
        output_to_prev_valid=> output_to_prev_valid,
        output_to_next_valid=> output_to_next_valid,
        input_data      => input_data,
        output_data     => output_data
    );

end Behavioral;
