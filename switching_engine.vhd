library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;
	use work.karouter_pack.all;

--NxN switching engine

entity switching_engine is
generic (
    PORTCNT         : integer;
    BLOCKWIDTH      : integer
);
port (
    clk                 : in std_logic;
    reset               : in std_logic;
    
    prev_request_vec    : in bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    
    input_data_vec      : in std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
    output_data_vec     : out std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
    
    prev_valid_vec      : in boolean_vector(PORTCNT-1 downto 0);
    next_valid_vec      : in boolean_vector(PORTCNT-1 downto 0);
    output_to_prev_valid: out boolean_vector(PORTCNT-1 downto 0);
    output_to_next_valid: out boolean_vector(PORTCNT-1 downto 0)
);
end switching_engine ;

architecture Behavioral of switching_engine is
    --Switching matrix connectors
    signal req_swclients_to_swmatrix    : bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    signal ack_swmatrix_to_swclients    : bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    signal req_swmatrix_to_shed         : bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    signal ack_sched_to_swmatrix        : bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    
    
    signal valid_sched_to_swclients     : boolean_vector(PORTCNT-1 downto 0);
    signal valid_swclients_to_sched     : boolean_vector(PORTCNT-1 downto 0);
    signal dataout_swclients_to_sched   : std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
begin
    switching_clients: for i in PORTCNT-1 downto 0 generate
        switching_cli: switching_client
        generic map (
            PORTCNT => PORTCNT,
            BLOCKWIDTH => BLOCKWIDTH
        )
        port map (
            prev_request_vec => prev_request_vec(i),
            self_request_vec => req_swclients_to_swmatrix(i),
            next_respons_vec => ack_swmatrix_to_swclients(i),
            prev_valid => prev_valid_vec(i),
            next_valid => valid_sched_to_swclients(i),
            output_to_prev_valid => output_to_prev_valid(i),
            output_to_next_valid => valid_swclients_to_sched(i),
            input_data => input_data_vec(i),
            output_data => dataout_swclients_to_sched(i)
        );
    end generate switching_clients; 

    reqmatrix: switching_matrix
    generic map (
        PORTCNT => PORTCNT
    )
    port map (
        input => req_swclients_to_swmatrix,
        output => req_swmatrix_to_shed
    );

    ackmatrix: switching_matrix
    generic map (
        PORTCNT => PORTCNT
    )
    port map (
        input => ack_sched_to_swmatrix,
        output => ack_swmatrix_to_swclients 
    );

    schedulers: for i in PORTCNT-1 downto 0 generate
        scheduler: round_robin_scheduler
        generic map (
            PORTCNT => PORTCNT,
            BLOCKWIDTH => BLOCKWIDTH
        )
        port map (
            clk => clk,
            reset => reset,
            prev_request_vec=> req_swmatrix_to_shed(i),
            self_respons_vec=> ack_sched_to_swmatrix(i),
            input_data_vec  => dataout_swclients_to_sched,
            output_data     => output_data_vec(i),
            prev_valid_vec  => valid_swclients_to_sched,
            next_valid      => next_valid_vec(i),
            output_to_prev_valid    => valid_sched_to_swclients(i),
            output_to_next_valid    => output_to_next_valid(i)
        );
    end generate schedulers;
end Behavioral;