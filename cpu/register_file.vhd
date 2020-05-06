library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port(
        clk : in std_logic;
        rst : in std_logic;
        rd_addr0 : in std_logic_vector(4 downto 0);
        rd_addr1 : in std_logic_vector(4 downto 0);
        wr_addr : in std_logic_vector(4 downto 0); -- Titled "Write register" in datasheet schematic
        wr_en : in std_logic;
        wr_data : in std_logic_vector(31 downto 0);
        rd_data0 : out std_logic_vector(31 downto 0);
        rd_data1 : out std_logic_vector(31 downto 0);
        JandL : in std_logic -- TODO not sure what this is for
        );
end register_file;


architecture async_read of register_file is
    type reg_array is array(0 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_array;
begin
    process (clk, rst) is
    begin
        if (rst = '1') then
            for i in regs'range loop
                regs(i) <= (others => '0');
            end loop;
        elsif (rising_edge(clk)) then
            if(JandL = '1') then
                regs(31) <= wr_data; -- If Jump and Link, write directly to reg 31.
            elsif (wr_en = '1' and wr_addr /= "00000") then
                regs(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;                
        end if;
    end process;

    rd_data0 <= regs(to_integer(unsigned(rd_addr0)));
    rd_data1 <= regs(to_integer(unsigned(rd_addr1)));
   
end async_read;


architecture sync_read_during_write of register_file is
    type reg_array is array(0 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_array;
    signal rd_addr0_r : std_logic_vector(3 downto 0);
    signal rd_addr1_r : std_logic_vector(3 downto 0);
    
begin
    process (clk, rst) is
    begin
        if (rst = '1') then
            for i in regs'range loop
                regs(i) <= (others => '0');
            end loop;
        elsif (rising_edge(clk)) then
            if (wr_en = '1') then
                regs(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;

            rd_addr0_r <= rd_addr0;
            rd_addr1_r <= rd_addr1;
        end if;
    end process;

    rd_data0 <= regs(to_integer(unsigned(rd_addr0_r)));
    rd_data1 <= regs(to_integer(unsigned(rd_addr1_r)));
    
end sync_read_during_write;


architecture sync_read of register_file is
    type reg_array is array(0 to 31) of std_logic_vector(31 downto 0);
    signal regs : reg_array;
    
begin
    process (clk, rst) is
    begin
        if (rst = '1') then
            for i in regs'range loop
                regs(i) <= (others => '0');
            end loop;
        elsif (rising_edge(clk)) then
            if (wr_en = '1') then
                regs(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;

            rd_data0 <= regs(to_integer(unsigned(rd_addr0)));
            rd_data1 <= regs(to_integer(unsigned(rd_addr1)));
        end if;
    end process;
    
end sync_read;