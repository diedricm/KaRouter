library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;
	use work.karouter_pack.all;

--Inverts the order of dimensions on 2d vectors of signals

entity switching_matrix is
generic (
    PORTCNT : integer
);
port (
    input    : in bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
    output   : out bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0)
);
end switching_matrix;

architecture Behavioral of switching_matrix is
begin
    setup_switch_matrix: process (input)
    begin
        for i in PORTCNT-1 downto 0 loop
            for j in PORTCNT-1 downto 0 loop
                output(j)(i) <= input(i)(j);
            end loop;
        end loop;
    end process;
end Behavioral;