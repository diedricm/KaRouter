library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.numeric_std.all;
library work;
	use work.karouter_pack.all;

--Multiplexes PORTCNT number of karouter connections into a single.
--Uses a bad implementation of round robin. Is not really fair, but small.

entity round_robin_scheduler is
generic (
    PORTCNT : integer;
    BLOCKWIDTH : integer
);
port (
    clk             : in std_logic;
    reset           : in std_logic;

    --Connection establishing signals on input interface 
    prev_request_vec: in boolean_vector(PORTCNT-1 downto 0);
    self_respons_vec: out boolean_vector(PORTCNT-1 downto 0);
    
    --Data forwarding
    input_data_vec  : in std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
    output_data     : out std_logic_vector(BLOCKWIDTH-1 downto 0);
    
    --Start/stop forwarding
    prev_valid_vec  : in boolean_vector(PORTCNT-1 downto 0);
    next_valid      : in boolean;
    output_to_prev_valid: out boolean;
    output_to_next_valid: out boolean
);
end round_robin_scheduler;

architecture Behavioral of round_robin_scheduler is
    constant ADDRWIDTH  : integer := get_addr_width(PORTCNT);

    signal current_slot : unsigned(ADDRWIDTH-1 downto 0);
    signal has_connction : boolean;
begin

    schedule: process (clk)
        variable hit : boolean;
        variable next_slot : unsigned(ADDRWIDTH-1 downto 0);
    begin
        if rising_edge(clk) then
            output_data <= input_data_vec(to_integer(current_slot));
            
            has_connction <= not ((prev_request_vec and self_respons_vec) = (self_respons_vec'range => false));
            output_to_prev_valid <= prev_valid_vec(to_integer(current_slot)) and next_valid and has_connction;
            output_to_next_valid <= prev_valid_vec(to_integer(current_slot)) and next_valid and has_connction;
            
            if not has_connction then
                hit := false;
                next_slot := current_slot;
                
                for i in 1 to PORTCNT loop
                    next_slot  := i + next_slot;
                    if prev_request_vec(to_integer(next_slot)) and (not hit) then
                        hit := true;
                        self_respons_vec(to_integer(next_slot)) <= true;
                    else
                        self_respons_vec(to_integer(next_slot)) <= false;
                    end if;
                end loop;
                
                current_slot <= next_slot;
            end if;
        end if;
    end process;
    
end Behavioral;