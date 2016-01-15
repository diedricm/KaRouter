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

    manage_state: process (clk)
        variable v_reset : boolean;
        variable v_push : boolean;
        variable v_pull : boolean;
    begin
        v_reset := reset = '1';
        v_push := push;
        v_pull := pull;
            
        if rising_edge(clk) then        
            --If a last block left the queue
            if blocks_read_cnt_back = packet_size_back then
                self_request_vec <= (others => false);
                v_push := false;
            end if;
            
            --If the last block entered a queue
            if blocks_read_cnt_front = packet_size_front then
                v_pull := false;
            end if;
            
            --If the queue contains the full header
            if blocks_read_cnt_front = QUEUE_DEPTH then
                packet_size_back <= packet_size_front;
                blocks_read_cnt_back <= to_unsigned(1, BLOCKWIDTH);
                self_request_vec <= outport_mask;
                v_reset := v_reset or drop_event;
                v_push := true;
            end if;
            
            --If a new packets first block arrived at the queue
            if new_packet_coming and prev_valid then
                packet_size_front <= unsigned(input_data);
                blocks_read_cnt_front <= to_unsigned(1, BLOCKWIDTH);
                v_pull := true;
            end if;
            
            if v_reset then
                v_push := false;
                v_pull := false;
                new_packet_coming <= true;
                output_drop_event <= true;
                blocks_read_cnt_front <= (others => '0');
                blocks_read_cnt_back <= (others => '0');
                packet_size_front <= (others => '1');
                packet_size_back <= (others => '1');
            end if;
            
            --Push all blocks backwards in the lsr
            if (not pull or prev_valid) and (not push or next_valid) and (push or pull) then
                for i in QUEUE_DEPTH-1 downto 1 loop
                    for j in BLOCKWIDTH-1 downto 0 loop
                        shiftreg((i-1)*BLOCKWIDTH+j) <= shiftreg(i*BLOCKWIDTH+j);
                    end loop;
                end loop;
                
                blocks_read_cnt_front <= blocks_read_cnt_front + 1; 
                blocks_read_cnt_back <= blocks_read_cnt_back + 1;
                
                shiftreg(QUEUESIZE-1 downto QUEUESIZE-BLOCKWIDTH) <= input_data;
                output_data <= shiftreg(BLOCKWIDTH-1 downto 0);
                
                output_to_prev_valid <= true;
                output_to_next_valid <= true;
            else
                output_to_prev_valid <= false;
                output_to_next_valid <= false;
            end if;
        end if;
        
        push <= v_push;
        pull <= v_pull;
    end process;
end Behavioral;

