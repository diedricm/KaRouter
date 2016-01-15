library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
library work;
	use work.cam_pack.all;
	
--Generic packet classifier. Matches over multiple dimensions using bitvectors.
--It is recommended to create the generics using the factory functions in cam_pack,vhd
	
entity packet_classifier is
	generic (
		DIMCNT        : integer;
		VECWIDTH      : integer;
		ADDRWIDTH     : integer;
		REQWIDTH      : integer;
		DATAWIDTH     : integer;
		TRNCAMGENS    : tr_cam_gen_arr
	);
	port (
		enable    : in  std_logic;
		clk       : in  std_logic;
		
		--Dimension of the memory you want to modify
		dimen_sel : in	std_logic_vector(DIMCNT-1 downto 0);
		
		--Set to modify the NCAM/TCAM, unset to modify RCAM
		cam_sel   : in	std_logic;
		
		--Set to modify vector memory, unset to modify rule memory
		vec_sel   : in	std_logic;
		
		--Set to modify rule memory, unset to modify mask memory (only for TCAMs)
		mem_sel   : in	std_logic;
		
		--Address for programming memories
		addr_in   : in  std_logic_vector(ADDRWIDTH-1 downto 0);
		
		--Data for programming memories
		data_in   : in  std_logic_vector(DATAWIDTH-1 downto 0);
		
		--Data to match against. Lower dimensions are in the lower end of the vector 
		req_in    : in  std_logic_vector(REQWIDTH-1 downto 0);
		
		--Result vector
		vec_result: out std_logic_vector(VECWIDTH-1 downto 0)
	);
end packet_classifier;

architecture Behavioral of packet_classifier is
	subtype vec_word is std_logic_vector(VECWIDTH-1 downto 0);
	type vec_word_array is array(INTEGER range<>) of vec_word;
	
	signal enableandselect : std_logic_vector(DIMCNT-1 downto 0);
	signal cam_results : vec_word_array(DIMCNT-1 downto 0);
begin
	enableandselect <= dimen_sel when enable = '1' else (others=>'0');

	cams: for i in 0 to DIMCNT-1 generate
		cam: rtn_cam
		generic map(
			VECWIDTH => VECWIDTH,
			DATAWIDTH=>	TRNCAMGENS(i).DATAWIDTH,
			ADDRWIDTH=>	TRNCAMGENS(i).ADDRWIDTH,
			USENCAM  => TRNCAMGENS(i).USENCAM,
			RCOMP    =>	TRNCAMGENS(i).RCOMP,
			TCOMP    =>	TRNCAMGENS(i).TCOMP
		)
		port map(
			enable   => enableandselect(i),
			clk      => clk,
			cam_sel  => cam_sel,
			vec_sel  => vec_sel,
			mem_sel  => mem_sel,
			addr_in  => addr_in(TRNCAMGENS(i).ADDRWIDTH-1 downto 0),
			data_in  => data_in(TRNCAMGENS(i).DATAWIDTH-1 downto 0),
			req_in   => req_in(TRNCAMGENS(i).REQRNGHGH-1 downto TRNCAMGENS(i).REQRNGLOW),
			vec_out  => cam_results(i)
		);
	end generate cams;
 
	and_results: process (cam_results)
		variable tmp : vec_word;
	begin
		tmp := (others=>'1');
	
		for i in DIMCNT-1 downto 0 loop
			tmp := tmp and cam_results(i);
		end loop;
		vec_result <= tmp;
	end process;

end Behavioral;