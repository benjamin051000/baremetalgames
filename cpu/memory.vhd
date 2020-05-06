library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
generic (WIDTH : natural := 32);
port (
    addr : in std_logic_vector(WIDTH-1 downto 0); -- only 9-2 will read RAM data
    inputData : in std_logic_vector(31 downto 0);

    memWrite, inportEnSel, inportEn : in std_logic;
    writeData : in std_logic_vector(WIDTH-1 downto 0);

    clk, rst : in std_logic; -- For registers and RAM

    outportData, readData : out std_logic_vector(WIDTH-1 downto 0)
);
end memory;



architecture str of memory is

    signal inport0En, inport1En : std_logic;
    
    signal mux_sel, mux_sel_delayed : std_logic_vector(1 downto 0);

    signal inport0Data, inport1Data, ramData : std_logic_vector(31 downto 0);

    signal outportWrEn, ramWrEn : std_logic;

    -- signal resizedInput : std_logic_vector(31 downto 0);

    constant INPORT0_ADDR : natural := 65528;
    constant INPORT1_ADDR : natural := 65532;
    constant RAM_MAX_ADDR : natural := 1024; -- before shifting by 2

begin


    -- resizedInput <= std_logic_vector(resize(unsigned(inputData), 32));

    -- Inport enable logic
    inport0En <= inportEn and not inportEnSel; -- Switch set to low
    inport1En <= inportEn and inportEnSel; -- Switch set to high
    

    -- Logic to control outportWrEn, ramWrEn, and mux_sel
    mux_sel <=  "00" when to_integer(unsigned(addr)) = INPORT0_ADDR else
                "01" when to_integer(unsigned(addr)) = INPORT1_ADDR else
                "10" when to_integer(unsigned(addr)) >= 0 and to_integer(unsigned(addr)) <= 1023
                else "10";
    
    outportWrEn <= '1' when (to_integer(unsigned(addr)) = INPORT1_ADDR) and memWrite = '1' else '0';

    ramWrEn <= '1' when (to_integer(unsigned(addr)) >= 0 and to_integer(unsigned(addr)) <= 1023) and memWrite = '1' else '0';



    -- Instantiate RAM
    U_RAM : entity work.ram
    port map (
        address => addr(9 downto 2),
        clock => clk,
        data => writeData,
        wren => ramWrEn,
        q => ramData
    );

    -- Inport logic
    U_INPORT_0 : entity work.reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => '0',
        en => inport0En,
        input => inputData,
        output => inport0Data
    );

    U_INPORT_1 : entity work.reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => '0',
        en => inport1En,
        input => inputData,
        output => inport1Data
    );

    U_DELAY_REG : entity work.reg
    generic map (width => 2)
    port map (
        clk => clk,
        rst => rst,
        en => '1',
        input => mux_sel,
        output => mux_sel_delayed
    );

    U_READ_MUX : entity work.mux_3x1
    generic map (width => 32)
    port map (
        input1 => inport0Data,
        input2 => inport1Data,
        input3 => ramData,
        sel => mux_sel_delayed,
        output => readData
    );


    -- Outport logic
    U_OUTPORT : entity work.reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => outportWrEn,
        input => writeData,
        output => outportData
    );


end str;