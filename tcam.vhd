library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

--Ternary Cam

entity tcam is
	generic (
		DATAWIDTH	: integer;
		VECWIDTH	: integer;
		COMPCNT		: integer;
		ADDRWIDTH	: integer
	);
	port (
		enable		: in std_logic;
		clk			: in std_logic;
		vec_sel		: in std_logic;
		mem_sel		: in std_logic;
		addr_in		: in std_logic_vector(ADDRWIDTH-1 downto 0);
		data_in		: in std_logic_vector(DATAWIDTH-1 downto 0);
		req_in		: in std_logic_vector(DATAWIDTH-1 downto 0);
		vec_out		: out std_logic_vector(VECWIDTH-1 downto 0);
		match_found	: out std_logic
	);
end tcam;

architecture rtl of tcam is
	type data_word is array (INTEGER range <>) of std_logic_vector(DATAWIDTH-1 downto 0);
	type vector_word is array (INTEGER range <>) of std_logic_vector(VECWIDTH-1 downto 0);

	signal data_mem : data_word(COMPCNT-1 downto 0);
	signal mask_mem : data_word(COMPCNT-1 downto 0);
	signal vec_mem : vector_word(COMPCNT-1 downto 0);
begin

	prog: process(clk, addr_in, enable)
		variable index : integer;
	begin
		index := to_integer(unsigned(addr_in));
	
		if rising_edge(clk) and enable = '1' and index < COMPCNT then
			if vec_sel = '1' then
				vec_mem(index)  <= data_in(VECWIDTH-1 downto 0);
			else
				if mem_sel = '1' then
					data_mem(index) <= data_in(DATAWIDTH-1 downto 0);
				else
					mask_mem(index) <= data_in(DATAWIDTH-1 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	check: process(req_in, data_mem, mask_mem, vec_mem)
	begin
		vec_out <= (OTHERS => '0');
		match_found <= '0';
	
		for i in COMPCNT-1 downto 0 loop
			if (data_mem(i) and mask_mem(i)) = (req_in and mask_mem(i)) then
				vec_out <= vec_mem(i);
				match_found <= '1';
			end if;
		end loop;
	end process;
end rtl;
