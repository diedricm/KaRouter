library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.numeric_std.all;
library work;
	use work.karouter_pack.all;

--Queue that stores parts of packages using karouter protocol. Can connect to classifier and switching clients.

entity input_queue is
generic (
    QUEUE_DEPTH     : integer;
    BLOCKWIDTH      : integer;
    PORTCNT         : integer
);
port (
    clk             : in std_logic;
    reset           : in std_logic;
    
    --Signals from classifier
    output_dest_data: out std_logic_vector((QUEUE_DEPTH*BLOCKWIDTH)-1 downto 0);
    outport_mask    : in boolean_vector(PORTCNT-1 downto 0);
    
    --Connection establishing signals on switching interface
    self_request_vec: out boolean_vector(PORTCNT-1 downto 0);
    
    --Start/stop forwarding
    drop_event      : in boolean;
    prev_valid      : in boolean;
    next_valid      : in boolean;
    output_drop_event: out boolean;
    output_to_prev_valid: out boolean;
    output_to_next_valid: out boolean;
    
    --Signals on output interface
    input_data      : in std_logic_vector(BLOCKWIDTH-1 downto 0);
    output_data     : out std_logic_vector(BLOCKWIDTH-1 downto 0)
);
end input_queue;

architecture Behavioral of input_queue is
    constant QUEUESIZE  : integer := QUEUE_DEPTH*BLOCKWIDTH;
    
    --Memory
    signal shiftreg : std_logic_vector(QUEUESIZE-1 downto 0);
    
    signal pull     : boolean;
    signal push     : boolean;
    signal new_packet_coming: boolean;
    signal blocks_read_cnt_front: unsigned(BLOCKWIDTH-1 downto 0);
    signal blocks_read_cnt_back: unsigned(BLOCKWIDTH-1 downto 0);
    signal packet_size_front   : unsigned(BLOCKWIDTH-1 downto 0);
    signal packet_size_back   : unsigned(BLOCKWIDTH-1 downto 0);
begin

    output_dest_data <= shiftreg;
    output_data <= shiftreg(BLOCKWIDTH-1 downto 0);

    manage_state: process (ALL)
        variable v_reset : boolean;
        variable v_push : boolean;
        variable v_pull : boolean;
	variable v_blocks_read_cnt_front   : unsigned(BLOCKWIDTH-1 downto 0);
	variable v_blocks_read_cnt_back   : unsigned(BLOCKWIDTH-1 downto 0);
    begin
        v_reset := reset = '1';
        v_push := push;
        v_pull := pull;
	v_blocks_read_cnt_front := blocks_read_cnt_front;
	v_blocks_read_cnt_back := blocks_read_cnt_back;
            
        if rising_edge(clk) then
            --If a last block left the queue
            if blocks_read_cnt_back = packet_size_back then
                self_request_vec <= (others => false);
		new_packet_coming <= true;
                v_push := false;
            end if;
            
            --If the last block entered a queue
            if blocks_read_cnt_front = packet_size_front then
                v_pull := false;
            end if;
            
            --If the queue contains the full header
            if blocks_read_cnt_front = QUEUE_DEPTH then
                self_request_vec <= outport_mask;
                packet_size_back <= packet_size_front;
                v_blocks_read_cnt_back := to_unsigned(0, BLOCKWIDTH);
                v_reset := v_reset or drop_event;
                v_push := true;
            end if;
            
            --If a new packets first block arrived at the queue
            if new_packet_coming and prev_valid then
		new_packet_coming <= false;
                packet_size_front <= unsigned(input_data);
                v_blocks_read_cnt_front := to_unsigned(0, BLOCKWIDTH);
                v_pull := true;
            end if;

            --Push all blocks backwards in the lsr
            if (not v_pull or prev_valid) and (not v_push or next_valid) and (v_push or v_pull) then
                for i in QUEUE_DEPTH-1 downto 1 loop
                    for j in BLOCKWIDTH-1 downto 0 loop
                        shiftreg((i-1)*BLOCKWIDTH+j) <= shiftreg(i*BLOCKWIDTH+j);
                    end loop;
                end loop;
                
                v_blocks_read_cnt_front := v_blocks_read_cnt_front + 1; 
                v_blocks_read_cnt_back := v_blocks_read_cnt_back + 1;
                
                shiftreg(QUEUESIZE-1 downto QUEUESIZE-BLOCKWIDTH) <= input_data;
                
                output_to_prev_valid <= true;
                output_to_next_valid <= true;
            else
                output_to_prev_valid <= false;
                output_to_next_valid <= false;
            end if;

            if v_reset then
                v_push := false;
                v_pull := false;
                new_packet_coming <= true;
                output_drop_event <= true;
                v_blocks_read_cnt_front := (others => '0');
                v_blocks_read_cnt_back := (others => '0');
                packet_size_front <= (others => '1');
                packet_size_back <= (others => '1');
            end if;

	    push <= v_push;
	    pull <= v_pull;
	    blocks_read_cnt_front <= v_blocks_read_cnt_front;
	    blocks_read_cnt_back <= v_blocks_read_cnt_back;
        end if;
    end process;
end Behavioral;