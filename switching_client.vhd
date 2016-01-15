library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;
	use work.karouter_pack.all;

--Maps a single karouter connection to multiple using a request vector.

entity switching_client is
generic (
    BLOCKWIDTH      : integer;
    PORTCNT         : integer
);
port (
    --Connection establishing signals on switching interface
    prev_request_vec: in boolean_vector(PORTCNT-1 downto 0);
    self_request_vec: out boolean_vector(PORTCNT-1 downto 0);
    next_respons_vec: in boolean_vector(PORTCNT-1 downto 0);
    
    --Start/stop forwarding
    prev_valid      : in boolean;
    next_valid      : in boolean;
    output_to_prev_valid: out boolean;
    output_to_next_valid: out boolean;
    
    --Signals on output interface
    input_data      : in std_logic_vector(BLOCKWIDTH-1 downto 0);
    output_data     : out std_logic_vector(BLOCKWIDTH-1 downto 0)
);
end switching_client;

architecture Behavioral of switching_client is
    signal has_connection : boolean;
begin
    output_data <= input_data;
    self_request_vec <= prev_request_vec;
    has_connection <= not ((next_respons_vec and prev_request_vec) = (prev_request_vec'range => false));
    output_to_prev_valid <= has_connection and prev_valid and next_valid;
    output_to_next_valid <= has_connection and prev_valid and next_valid;
end Behavioral;