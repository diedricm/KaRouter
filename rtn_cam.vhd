library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
	use work.cam_pack.all;

--A "Meta" CAM matching over a dimension of an package using 1 to 2 cams.
--Depending on the generics it contains RCAM OR (TCAM XOR NCAM).
--If both RCAM and the other CAM return a value, then the RCAM value is ignored.

entity rtn_cam is
	generic (
		VECWIDTH      : integer;
		DATAWIDTH     : integer;
		ADDRWIDTH     : integer;
		USENCAM       : boolean;
		RCOMP         : cam_generics;
		TCOMP         : cam_generics
	);
	port (
		enable	: in std_logic;
		clk		: in std_logic;
		cam_sel	: in std_logic;
		vec_sel	: in std_logic;
		mem_sel	: in std_logic;
		addr_in	: in std_logic_vector(ADDRWIDTH-1 downto 0);
		data_in	: in std_logic_vector(DATAWIDTH-1 downto 0);
		req_in	: in std_logic_vector(DATAWIDTH-1 downto 0);
		vec_out	: out std_logic_vector(VECWIDTH-1 downto 0)
  );
end rtn_cam;

architecture rtl of rtn_cam is
	type vector_word is array (INTEGER range <>) of std_logic_vector(VECWIDTH-1 downto 0);

	signal results : vector_word(1 downto 0);
	signal match_found : std_logic;
begin

	rangecams: if RCOMP.COMPCNT > 0 generate
		rangecam: rcam
		generic map(
			DATAWIDTH => DATAWIDTH,
			COMPCNT => RCOMP.COMPCNT,
			VECWIDTH => VECWIDTH,
			ADDRWIDTH => RCOMP.ADDRWIDTH
		)
		port map(
			enable  => cam_sel,
			clk     => clk,
			vec_sel => vec_sel,
			addr_in => addr_in(RCOMP.ADDRWIDTH-1 downto 0),
			data_in => data_in,
			req_in  => req_in,
			vec_out => results(0)
		);
	end generate rangecams;
	
	normalcams: if USENCAM and TCOMP.COMPCNT > 0 generate
		normalcam: ncam
		generic map(
			DATAWIDTH => DATAWIDTH,
			COMPCNT => TCOMP.COMPCNT,
			VECWIDTH => VECWIDTH,
			ADDRWIDTH => TCOMP.ADDRWIDTH
		)
		port map(
			enable  => not cam_sel,
			clk     => clk,
			vec_sel => vec_sel,
			addr_in => addr_in(TCOMP.ADDRWIDTH-1 downto 0),
			data_in => data_in,
			req_in  => req_in,
			vec_out => results(1),
			match_found => match_found
		);
	end generate normalcams;
	
	terncams: if (not USENCAM) and TCOMP.COMPCNT > 0 generate
		terncam: tcam
		generic map(
			DATAWIDTH => DATAWIDTH,
			COMPCNT => TCOMP.COMPCNT,
			VECWIDTH => VECWIDTH,
			ADDRWIDTH => TCOMP.ADDRWIDTH
		)
		port map(
			enable  => not cam_sel,
			clk     => clk,
			vec_sel => vec_sel,
			mem_sel => mem_sel,
			addr_in => addr_in(TCOMP.ADDRWIDTH-1 downto 0),
			data_in => data_in,
			req_in  => req_in,
			vec_out => results(1),
			match_found => match_found
		);
	end generate terncams;
	
	check: process(match_found, results)
	begin
		if match_found = '1' or RCOMP.COMPCNT < 1 then
			vec_out <= results(1);
		else
			vec_out <= results(0);
		end if;
	end process;
end rtl;
