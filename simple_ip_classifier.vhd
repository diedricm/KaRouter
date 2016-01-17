library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
library work;
	use work.cam_pack.all;

--A simple ipv6 packet classifier that matches over the src, dest and qos fields.

entity simple_ip_classifier is
	generic (
		GENS		: packet_classifier_generics := build_packet_classifier_generics((
			DIMCNT => 3,
			VECWIDTH => 4,
			TRNCAMSPECS => (
				0=>(10,10,true, 128),
				1=>(5,10,true, 128),
				2=>(0, 4,false,  8),
				others=>(0,0,false,0)
			)
		))
	);
	port (
		enable	: in  std_logic;
		clk		: in  std_logic;
		dimen_sel: in	std_logic_vector(GENS.DIMCNT-1 downto 0);
		cam_sel	: in	std_logic;
		vec_sel	: in	std_logic;
		mem_sel	: in	std_logic;
		addr_in	: in  std_logic_vector(GENS.ADDRWIDTH-1 downto 0);
		data_in	: in  std_logic_vector(GENS.DATAWIDTH-1 downto 0);
		req_in	: in  std_logic_vector(GENS.REQWIDTH-1 downto 0);
		vec_result: out std_logic_vector(GENS.VECWIDTH-1 downto 0)
	);
end simple_ip_classifier;

architecture Behavioral of simple_ip_classifier is
begin
	class: packet_classifier
	generic map (
		DIMCNT		=> GENS.DIMCNT,
		VECWIDTH		=> GENS.VECWIDTH,
		ADDRWIDTH	=> GENS.ADDRWIDTH,
		REQWIDTH		=> GENS.REQWIDTH,
		DATAWIDTH	=> GENS.DATAWIDTH,
		TRNCAMGENS	=> GENS.TRNCAMGENS
	)
	port map (
		enable	=> enable,
		clk		=> clk,
		dimen_sel=> dimen_sel,
		cam_sel	=> cam_sel,
		vec_sel	=> vec_sel,
		mem_sel	=> mem_sel,
		addr_in	=> addr_in,
		data_in	=> data_in,
		req_in	=> req_in,
		vec_result=> vec_result
	);
end Behavioral;

