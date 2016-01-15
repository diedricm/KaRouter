library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use ieee.math_real.log2;
	use ieee.math_real.ceil;
	
--Package for the classifier containing factory methods 
--for easy creation of the right generic values	
	
package cam_pack is

constant max_classifier_dimensions : integer := 128; 

type comp_res is (greater, smalleroreq);
type comp_res_vec is array (INTEGER range <>) of comp_res;

--SPECS
type rtn_cam_spec is
record
	RCOMPCNT   : integer;		--Number of wanted range CAM submodules
	TCOMPCNT   : integer;		--Number of wanted ternary or normal CAM submodules
	USENCAM    : boolean;		--If true then all ternary CAMs will only be normal cams 
	DATAWIDTH  : integer;		--Bit width of the words to match 
end record;

type rtn_cam_spec_arr is array (max_classifier_dimensions-1 downto 0) of rtn_cam_spec;

type packet_classifier_spec is
record
	DIMCNT         : integer;		--Number of wanted packet fields to match over
	VECWIDTH       : integer;		--Bit width of returned vector
	TRNCAMSPECS    : rtn_cam_spec_arr;
end record;

--GENS Generic values generated through factory functions
type cam_generics is
record
	COMPCNT    : integer;
	ADDRWIDTH  : integer;
end record;

type rtn_cam_generics is
record
	DATAWIDTH  : integer;
	ADDRWIDTH  : integer;
	REQRNGHGH  : integer;
	REQRNGLOW  : integer;
	USENCAM    : boolean;
	RCOMP      : cam_generics;
	TCOMP      : cam_generics;
end record;

type tr_cam_gen_arr  is array (max_classifier_dimensions-1 downto 0) of rtn_cam_generics;

type packet_classifier_generics is
record
	DIMCNT     : integer;
	VECWIDTH   : integer;
	ADDRWIDTH  : integer;
	REQWIDTH   : integer;
	DATAWIDTH  : integer;
	TRNCAMGENS : tr_cam_gen_arr;
end record;

--FUNCS
function get_addr_width(elem_cnt: integer) return integer;
function get_max(a : integer; b : integer) return integer;
function build_rtn_cam_generics(specs : rtn_cam_spec; vecwidth : integer) return rtn_cam_generics;
function build_packet_classifier_generics(specs : packet_classifier_spec) return packet_classifier_generics;


--COMPONENTS
component tcam is
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
end component;
component ncam is
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
		addr_in		: in std_logic_vector(ADDRWIDTH-1 downto 0);
		data_in		: in std_logic_vector(DATAWIDTH-1 downto 0);
		req_in		: in std_logic_vector(DATAWIDTH-1 downto 0);
		vec_out		: out std_logic_vector(VECWIDTH-1 downto 0);
		match_found	: out std_logic
	);
end component;
component rcam is
	generic (
		DATAWIDTH : integer;
		VECWIDTH  : integer;
		COMPCNT   : integer;
		ADDRWIDTH : integer
	);
	port (
		enable	: in std_logic;
		clk		: in std_logic;
		vec_sel	: in std_logic;
		addr_in	: in std_logic_vector(ADDRWIDTH-1 downto 0);
		data_in	: in std_logic_vector(DATAWIDTH-1 downto 0);
		req_in	: in std_logic_vector(DATAWIDTH-1 downto 0);
		vec_out	: out std_logic_vector(VECWIDTH-1 downto 0)
	);
end component;
component rtn_cam is
	generic (
		VECWIDTH  : integer;
		DATAWIDTH : integer;
		ADDRWIDTH : integer;
		USENCAM   : boolean;
		RCOMP     : cam_generics;
		TCOMP     : cam_generics
	);
	port (
		enable    : in std_logic;
		clk       : in std_logic;
		cam_sel   : in std_logic;
		vec_sel   : in std_logic;
		mem_sel   : in std_logic;
		addr_in   : in std_logic_vector(ADDRWIDTH-1 downto 0);
		data_in   : in std_logic_vector(DATAWIDTH-1 downto 0);
		req_in    : in std_logic_vector(DATAWIDTH-1 downto 0);
		vec_out   : out std_logic_vector(VECWIDTH-1 downto 0)
  );
end component;
component priority_encoder is
	generic (
		VECWIDTH  : integer;
		RESWIDTH  : integer
	);
	port (
		INPUT     : in std_logic_vector(VECWIDTH-1 downto 0);
		OUTPUT    : out std_logic_vector(RESWIDTH-1 downto 0)
	);
end component;
component packet_classifier is
	generic (
		DIMCNT    : integer;
		VECWIDTH  : integer;
		ADDRWIDTH : integer;
		REQWIDTH  : integer;
		DATAWIDTH : integer;
		TRNCAMGENS: tr_cam_gen_arr
	);
	port (
		enable    : in  std_logic;
		clk       : in  std_logic;
		dimen_sel : in	std_logic_vector(DIMCNT-1 downto 0);
		cam_sel   : in	std_logic;
		vec_sel   : in	std_logic;
		mem_sel   : in	std_logic;
		addr_in   : in  std_logic_vector(ADDRWIDTH-1 downto 0);
		data_in   : in  std_logic_vector(DATAWIDTH-1 downto 0);
		req_in    : in  std_logic_vector(REQWIDTH-1 downto 0);
		vec_result: out std_logic_vector(VECWIDTH-1 downto 0)
	);
end component;

end cam_pack;



package body cam_pack is

function get_addr_width(elem_cnt: integer) return integer is
begin
	return INTEGER(CEIL(LOG2(REAL(elem_cnt))));
end get_addr_width;

function get_max(a : integer; b : integer) return integer is
	variable result : integer;
begin
	if a < b then
		result := b;
	else
		result := a;
	end if;
	return result;
end get_max;

--Creates correct generic values for packet_classifiers from the desired specification values provided
function build_rtn_cam_generics(specs : rtn_cam_spec; vecwidth : integer) return rtn_cam_generics is
	variable result : rtn_cam_generics;
begin
	result.RCOMP.COMPCNT   := specs.RCOMPCNT;
	result.RCOMP.ADDRWIDTH := get_addr_width(specs.RCOMPCNT+1);
	result.TCOMP.COMPCNT   := specs.TCOMPCNT;
	result.TCOMP.ADDRWIDTH := get_addr_width(specs.TCOMPCNT);
	result.ADDRWIDTH       := get_max(result.RCOMP.ADDRWIDTH, result.TCOMP.ADDRWIDTH);
	result.DATAWIDTH       := get_max(specs.DATAWIDTH, vecwidth);
	result.USENCAM         := specs.USENCAM;
	
	return result;
end build_rtn_cam_generics;

--Creates correct generic values for packet_classifiers from the desired specification values provided
function build_packet_classifier_generics(specs : packet_classifier_spec) return packet_classifier_generics is
	variable result : packet_classifier_generics;
begin
	if specs.DIMCNT <= 0
	or specs.vecwidth <= 0
	then
		report "Invalid srcam_classifier_spec provided to build_srcam_classifier_generics" severity failure;
	end if;
	
	result.DIMCNT      := specs.DIMCNT;
	result.VECWIDTH    := specs.VECWIDTH;
	result.ADDRWIDTH   := 0;
	result.DATAWIDTH   := 0;
	result.REQWIDTH    := 0;
	
	for i in specs.DIMCNT-1 downto 0 loop
		result.TRNCAMGENS(i) := build_rtn_cam_generics(specs.TRNCAMSPECS(i), specs.VECWIDTH);
		
		result.TRNCAMGENS(i).REQRNGLOW := result.REQWIDTH;
		result.REQWIDTH := result.REQWIDTH + result.TRNCAMGENS(i).DATAWIDTH;
		result.TRNCAMGENS(i).REQRNGHGH := result.REQWIDTH;
	
		if result.ADDRWIDTH < result.TRNCAMGENS(i).ADDRWIDTH then
			result.ADDRWIDTH := result.TRNCAMGENS(i).ADDRWIDTH;
		end if;
		
		if result.DATAWIDTH < result.TRNCAMGENS(i).DATAWIDTH then
			result.DATAWIDTH := result.TRNCAMGENS(i).DATAWIDTH;
		end if;
	end loop;
	
	return result;
end function build_packet_classifier_generics;

end cam_pack;