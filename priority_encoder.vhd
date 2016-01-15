library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
library work;
	use work.cam_pack.all;

--Takes a vector of VECWIDTH and returns a unsigned number of index of the highest set bit

entity priority_encoder is
	generic (
		VECWIDTH : integer;
		RESWIDTH : integer
	);
	port (
		input : in std_logic_vector(VECWIDTH-1 downto 0);
		output: out std_logic_vector(RESWIDTH-1 downto 0)
	);
end priority_encoder;

architecture Behavioral of priority_encoder is
begin

	prioencode: process (input)
		variable res : integer;
	begin
		res := 0;
		
		for i in 0 to VECWIDTH-1 loop
			if input(i) = '1' then
				res := i+1;
			end if;
		end loop;
		
		output <= std_logic_vector(to_unsigned(res, RESWIDTH));
	end process;
	
end Behavioral;

