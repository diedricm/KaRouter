library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
--Range CAM. Performs bitvector algorithm on req_in data. Max/min bounds of the dimension are implicitly added.
  
entity rcam is
	generic (
		DATAWIDTH : integer;
		VECWIDTH  : integer;
		COMPCNT   : integer;
		ADDRWIDTH : integer
	);
	port (
		enable	: in std_logic;
		clk		: in std_logic;
		
		--Set if you want to program vector memory
		vec_sel	: in std_logic;
		
		--Address for programming memories
		addr_in	: in std_logic_vector(ADDRWIDTH-1 downto 0);
		
		--Data to match against
		data_in	: in std_logic_vector(DATAWIDTH-1 downto 0);
		
		--Data to match against
		req_in	: in std_logic_vector(DATAWIDTH-1 downto 0);
		
		--Result vector, always valid
		vec_out	: out std_logic_vector(VECWIDTH-1 downto 0)
	);
end rcam;

architecture rtl of rcam is
	constant RANGECNT : integer := COMPCNT + 1;

	type data_word is array (INTEGER range <>) of std_logic_vector(DATAWIDTH-1 downto 0);
	type vector_word is array (INTEGER range <>) of std_logic_vector(VECWIDTH-1 downto 0);

	signal data_mem : data_word(COMPCNT-1 downto 0);
	signal vec_mem : vector_word(RANGECNT-1 downto 0);
begin

	prog: process(clk)
		variable index : integer;
	begin
		index := to_integer(unsigned(addr_in));
	
		if rising_edge(clk) and enable = '1' then
			if vec_sel = '1' then
				vec_mem(index) <= data_in(VECWIDTH-1 downto 0);
			else
				data_mem(index) <= data_in(DATAWIDTH-1 downto 0);
			end if;
		end if;
	end process;
	
	check: process(req_in)
		variable upperIsGreater : boolean;
		variable lowerIsSmaller : boolean;
	begin
		upperIsGreater:= true;
		vec_out <= (OTHERS => '0');
	
		for i in RANGECNT-1 downto 1 loop
			lowerIsSmaller := req_in >= data_mem(i-1);
			if upperIsGreater = true and lowerIsSmaller then
				vec_out <= vec_mem(i);
			end if;
			upperIsGreater := not lowerIsSmaller;
		end loop;
	end process;
end rtl;
