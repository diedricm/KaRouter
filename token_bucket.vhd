library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

--First steps of a token bucket. Will be used with SR-TCM and TC-TCM.

entity token_bucket is
generic (
	DATAWIDTH : integer := 4
);
port (
	enable		   : in std_logic;
	clk            : in std_logic;
	bucket_reset   : in std_logic;
	bucket_size    : in unsigned(DATAWIDTH-1 downto 0);
	token_stream   : in unsigned(DATAWIDTH-1 downto 0);
	tok_req_stream : in unsigned(DATAWIDTH-1 downto 0);
	conforms       : out std_logic
);
end token_bucket;

architecture Behavioral of token_bucket is
	signal bucket_max_size	: unsigned(DATAWIDTH-1 downto 0);
	signal token_count		: unsigned(DATAWIDTH-1 downto 0);
begin
	reset_max: process(clk)
	begin
		if enable = '1' and rising_edge(clk) and bucket_reset = '1' then
			bucket_max_size <= bucket_size;
		end if;
	end process;
	
	admission_check: process(clk)
		variable tmp : unsigned(DATAWIDTH downto 0);
	begin
		if enable = '1' and rising_edge(clk) then
			tmp := ('0' & token_count) + ('0' & token_stream);
			if tmp(DATAWIDTH) = '1' or tmp > ('0' & bucket_max_size) then
				tmp := ('0' & bucket_max_size);
			end if;
			token_count <= tmp(DATAWIDTH-1 downto 0);
			
			tmp := tmp - ('0' & tok_req_stream);
			if tmp(DATAWIDTH) = '1' then
				conforms <= '0';
			else
				conforms <= '1';
				token_count <= tmp(DATAWIDTH-1 downto 0);
			end if;
		end if;
	end process;	
end Behavioral;