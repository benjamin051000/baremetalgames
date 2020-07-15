library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
generic (WIDTH : natural := 32);
port (
    addr : in std_logic_vector(WIDTH-1 downto 0); -- 9..2 used for RAM, 11..0 used for VRAM
    inputData : in std_logic_vector(31 downto 0);

    memWrite, inportEnSel, inportEn : in std_logic;
    writeData : in std_logic_vector(WIDTH-1 downto 0);

    clk, rst : in std_logic; -- For registers and RAM

    outportData, readData : out std_logic_vector(WIDTH-1 downto 0);

    -- Used to send data from memory to VRAM
    vram_wren : out std_logic;
    vga_wraddr, vga_data : out std_logic_vector(11 downto 0);
    -- Signals for swapping front and back buffers in VRAM.
    cpu_says_swap_buf : out std_logic;
    swap_complete : in std_logic
);
end memory;


architecture str of memory is

    -- adjustedAddr is used as an intermediate signal to check whether data should be written to VRAM or RAM.
    signal adjustedAddr : std_logic_vector(WIDTH-1 downto 0);

    signal inport0En, inport1En : std_logic;
    
    signal mux_sel, mux_sel_delayed : std_logic_vector(1 downto 0);

    signal inport0Data, inport1Data, ramData : std_logic_vector(31 downto 0);

    signal outportWrEn, ramWrEn : std_logic;

    constant INPORT0_ADDR : natural := 65528; -- FFF8
    constant INPORT1_ADDR : natural := 65532; -- FFFC

    -- Highest address to CPU RAM. Any higher addresses (which will be 11 bits wide) will point to VRAM.
    constant CPU_RAM_MAX_ADDR : natural := 1023; -- before shifting by 2

    constant VGA_RAM_BEGIN : natural := 1024; -- First available VRAM address.

begin

    -- Inport enable logic
    inport0En <= inportEn and not inportEnSel; -- Switch set to low
    inport1En <= inportEn and inportEnSel; -- Switch set to high
    

    -- Logic to control outportWrEn, ramWrEn, and mux_sel
    mux_sel <=  "00" when to_integer(unsigned(addr)) = INPORT0_ADDR else
                "01" when to_integer(unsigned(addr)) = INPORT1_ADDR else
                "10" when to_integer(unsigned(addr)) >= 0 and to_integer(unsigned(addr)) <= CPU_RAM_MAX_ADDR
                else "10";
    
    outportWrEn <= '1' when (to_integer(unsigned(addr)) = INPORT1_ADDR) and memWrite = '1' else '0';

    ramWrEn <= '1' when (to_integer(unsigned(addr)) >= 0 and to_integer(unsigned(addr)) <= CPU_RAM_MAX_ADDR) and memWrite = '1' else '0';

    -------------------- VGA Output --------------------

    -- vram_wren will be asserted during store word instructions when the address is higher than the maximum value allotted for CPU RAM.
    vram_wren <= not ramWrEn and memWrite;

    -- Address and data in VRAM are both 12 bits wide
    vga_data <= writeData(11 downto 0);
    vga_wraddr <= addr(11 downto 0);

    -- TODO this is just temporary to make sure it compiles properly
    cpu_says_swap_buf <= '0';

    -------------------- Structural architecture of memory --------------------

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