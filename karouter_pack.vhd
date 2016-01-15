library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use ieee.math_real.log2;
	use ieee.math_real.ceil;
    
--Stores some components of the karouter project 
    
package karouter_pack is
    type std_lgk_vec_2d is array(INTEGER range <>) of std_logic_vector;
    type bool_vec_2d is array(INTEGER range <>) of boolean_vector;
    
    function get_addr_width(elem_cnt: integer) return integer;
    
    component switching_engine is
    generic (
        PORTCNT         : integer;
        BLOCKWIDTH      : integer
    );
    port (
        clk                 : in std_logic;
        reset               : in std_logic;
        
        prev_request_vec    : in bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
        
        input_data_vec      : in std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
        output_data_vec     : out std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
        
        prev_valid_vec      : in boolean_vector(PORTCNT-1 downto 0);
        next_valid_vec      : in boolean_vector(PORTCNT-1 downto 0);
        output_to_prev_valid: out boolean_vector(PORTCNT-1 downto 0);
        output_to_next_valid: out boolean_vector(PORTCNT-1 downto 0)
    );
    end component ;
    component input_queue is
    generic (
        QUEUE_DEPTH     : integer;
        BLOCKWIDTH      : integer;
        PORTCNT         : integer
    );
    port (
        clk             : in std_logic;
        reset           : in std_logic;
        
        --Signals from classifier
        output_dest_data: out std_logic_vector((QUEUE_DEPTH*BLOCKWIDTH)-1 downto 0);
        outport_mask    : in boolean_vector(PORTCNT-1 downto 0);
        
        --Connection establishing signals on switching interface
        self_request_vec: out boolean_vector(PORTCNT-1 downto 0);
        
        --Start/stop forwarding
        drop_event      : in boolean;
        prev_valid      : in boolean;
        next_valid      : in boolean;
        output_drop_event: out boolean;
        output_to_prev_valid: out boolean;
        output_to_next_valid: out boolean;
        
        --Signals on output interface
        input_data      : in std_logic_vector(BLOCKWIDTH-1 downto 0);
        output_data     : out std_logic_vector(BLOCKWIDTH-1 downto 0)
    );
    end component;
    component classifier_socket is
    generic (
        BLOCKWIDTH      : integer;
        PORTCNT         : integer;
        CLASSDATAWIDTH  : integer;
        CONFIGWIDTH     : integer
    );
    port (
        clk             : in std_logic;
    
        --Config interface
        addr_in         : in std_logic_vector(CONFIGWIDTH-1 downto 0);
        memory_in       : in std_logic_vector(CONFIGWIDTH-1 downto 0);
    
        --Signals on input interface
        data_in         : in  std_logic_vector(CLASSDATAWIDTH*BLOCKWIDTH-1 downto 0);
        drop_packet     : out boolean;
        outport_mask    : out boolean_vector(PORTCNT-1 downto 0)
    );
    end component;
    component switching_client is
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
    end component;
    component round_robin_scheduler is
    generic (
        PORTCNT : integer;
        BLOCKWIDTH : integer
    );
    port (
        clk             : in std_logic;
        reset           : in std_logic;
    
        --Connection establishing signals on input interface 
        prev_request_vec: in boolean_vector(PORTCNT-1 downto 0);
        self_respons_vec: out boolean_vector(PORTCNT-1 downto 0);
        
        --Data forwarding
        input_data_vec  : in std_lgk_vec_2d(PORTCNT-1 downto 0)(BLOCKWIDTH-1 downto 0);
        output_data     : out std_logic_vector(BLOCKWIDTH-1 downto 0);
        
        --Start/stop forwarding
        prev_valid_vec  : in boolean_vector(PORTCNT-1 downto 0);
        next_valid      : in boolean;
        output_to_prev_valid: out boolean;
        output_to_next_valid: out boolean
    );
    end component;
    component switching_matrix is
    generic (
        PORTCNT : integer
    );
    port (
        input    : in bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0);
        output   : out bool_vec_2d(PORTCNT-1 downto 0)(PORTCNT-1 downto 0)
    );
    end component;
end karouter_pack;

package body karouter_pack is

function get_addr_width(elem_cnt: integer) return integer is
begin
	return INTEGER(CEIL(LOG2(REAL(elem_cnt))));
end get_addr_width;

end karouter_pack;