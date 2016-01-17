library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.numeric_std.all;
library work;
    use work.karouter_pack.all;
    use work.cam_pack.all;

--Takes the header information using data_in and makes a lookup using the packet_classifier
--TODO: Currently the lookup is hardcoded. Make use of generics here. 

entity classifier_socket is
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
end classifier_socket;

architecture Behavioral of classifier_socket is
    constant RULECNT     : integer := 10;
    constant PCG         : packet_classifier_generics := build_packet_classifier_generics((1, RULECNT, (0=>(0,10,false,CLASSDATAWIDTH),others=>(0,0,false,0))));
    constant CONFMEMSIZE : integer := PCG.DATAWIDTH/CONFIGWIDTH+1;
    constant CONFADDRSIZE: integer := (PCG.ADDRWIDTH+4)/CONFIGWIDTH+1;
    constant magic_addr  : std_logic_vector(CONFIGWIDTH-1 downto 0) := (others=>'1');
    constant magic_data  : std_logic_vector(CONFIGWIDTH-1 downto 0) := (1=>'1', others=>'0');

    signal config_mem   : std_logic_vector(CONFMEMSIZE*CONFIGWIDTH-1 downto 0);
    signal config_addr  : std_logic_vector(CONFADDRSIZE*CONFIGWIDTH-1 downto 0);
    
    signal vec_result   : std_logic_vector(PCG.VECWIDTH-1 downto 0);
    signal write_enable : std_logic;
begin

    process_results: process (vec_result)
    begin
        drop_packet <= true;
        outport_mask <= (others => false);
    
        for i in PORTCNT-1 downto 0 loop
            if vec_result(i) = '1' then
                outport_mask(i) <= true;
                drop_packet <= false;
            end if;
        end loop;
    end process;

    change_conf: process (ALL)
        variable addr : integer;
    begin
        if rising_edge(clk) then
            if addr_in = magic_addr and memory_in = magic_data and not write_enable = '1' then
                write_enable <= '1';
            else
                write_enable <= '0';
            end if;
            
            addr := to_integer(unsigned(addr_in));
            if addr_in(31) = '1' then
                if addr < CONFMEMSIZE then
                    config_mem(addr*CONFIGWIDTH-1 downto (addr-1)*CONFIGWIDTH) <= memory_in;
                end if;
            else
                if addr < CONFADDRSIZE then
                    config_addr(addr*CONFIGWIDTH-1 downto (addr-1)*CONFIGWIDTH) <= memory_in;
                end if;
            end if;
        end if;
    end process;

	class: packet_classifier 
    generic map (
        DIMCNT      => PCG.DIMCNT,
        VECWIDTH    => PCG.VECWIDTH,
        ADDRWIDTH   => PCG.ADDRWIDTH,
        REQWIDTH    => PCG.REQWIDTH,
        DATAWIDTH   => PCG.DATAWIDTH,
        TRNCAMGENS  => PCG.TRNCAMGENS
    )
    port map (
        enable      => write_enable,
        clk         => clk,
        dimen_sel   => config_addr(PCG.ADDRWIDTH+3 downto PCG.ADDRWIDTH+3),
        cam_sel     => config_addr(PCG.ADDRWIDTH+2),
        vec_sel     => config_addr(PCG.ADDRWIDTH+1),
        mem_sel     => config_addr(PCG.ADDRWIDTH+0),
        addr_in     => config_addr(PCG.ADDRWIDTH-1 downto 0),
        data_in     => config_mem(PCG.DATAWIDTH-1 downto 0),
        req_in      => data_in(PCG.REQWIDTH-1 downto 0),
        vec_result  => vec_result
    );

end Behavioral;