library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
generic (WIDTH : natural := 32);
port (
    addr : in std_logic_vector(WIDTH-1 downto 0); -- 9..2 used for RAM, 11..0 used for VRAM
    inputData : in std_logic_vector(31 downto 0); -- Used with the inports

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
    signal adjustedAddr : std_logic_vector(WIDTH-1 downto 0); -- TODO unused?

    signal inport0En, inport1En : std_logic;
    
    signal mux_sel, mux_sel_delayed : std_logic_vector(1 downto 0);

    signal inport0Data, inport1Data, ramData : std_logic_vector(31 downto 0);

    signal outportWrEn, ramWrEn : std_logic;

    constant INPORT0_ADDR : natural := 65528; -- 0xFFF8
    constant INPORT1_ADDR : natural := 65532; -- 0xFFFC

    -- Highest address to CPU RAM. Any higher addresses (which will be 11 bits wide) will point to VRAM.
    constant CPU_RAM_MAX_ADDR : natural := 1023; -- before shifting by 2

    constant VGA_RAM_BEGIN : natural := 1024; -- First available VRAM address. (0b100_0000_0000)

    -- This address is reserved for alerting the VGA core that it is ready to swap frame buffers.
    -- To use this, write a value of '1' to the following address. That signal will be passed to the VGA core to swap frame buffers at the next available oppportunity. The VGA core will remember this value being asserted, so it does not need to be held here.
    constant cpu_swap_buf_addr : natural := 65534; -- 0xFFFE

    -- This address points to a Flip Flop to check if swap_complete was asserted. This is how we will check when it is safe to write to the VGA back frame again.
    -- The delayed version is used when accessing this ram section, since it takes two cycles to retrieve memory. This ensures swap_complete_capture is read from memory on the right clock cycle.
    constant swap_complete_addr : natural := 65535; -- 0xFFFF
    signal swap_complete_capture, swap_cmp_cap_del : std_logic_vector(WIDTH-1 downto 0);

begin -- str

    -- Inport enable logic
    inport0En <= inportEn and not inportEnSel; -- Switch set to low
    inport1En <= inportEn and inportEnSel; -- Switch set to high
    

    -- Logic to control outportWrEn, ramWrEn, and mux_sel
    mux_sel <=  "00" when to_integer(unsigned(addr)) = INPORT0_ADDR else
                "01" when to_integer(unsigned(addr)) = INPORT1_ADDR else
                "10" when to_integer(unsigned(addr)) >= 0 and to_integer(unsigned(addr)) <= CPU_RAM_MAX_ADDR
                else "11" when to_integer(unsigned(addr)) = swap_complete_addr
                else "10"; -- Default case is read from memory
    
    outportWrEn <= '1' when (to_integer(unsigned(addr)) = INPORT1_ADDR) and memWrite = '1' else '0';


    -------------------- VGA Output --------------------
    -- vram_wren will be asserted during store word instructions when the address is higher than the maximum value allotted for CPU RAM.
    vram_wren <= not ramWrEn and memWrite;

    -- Address and data in VRAM are both 12 bits wide
    vga_data <= writeData(11 downto 0);
    vga_wraddr <= addr(11 downto 0);

    -- Assert cpu_says_swap_buf when the 0xFFFE address is asserted ('1' written to it).
    cpu_says_swap_buf <= '1' when unsigned(addr) = cpu_swap_buf_addr and to_integer(unsigned(writeData)) = 1 else '0';


    -------------------- Swap Complete Register --------------------
    -- This remembers if swap_complete was asserted, and is reset when read by the CPU.
    process(clk, rst)
    begin
        if(rst = '1') then
            swap_complete_capture <= (others => '0');
        elsif rising_edge(clk) then
            -- Capture swap_complete
            if(swap_complete = '1') then
                swap_complete_capture <= (0 => '1', others => '0');
            end if;
            -- If the CPU reads this register, reset swap_complete
            if(to_integer(unsigned(addr)) = swap_complete_addr and memWrite = '0') then
                swap_complete_capture <= (others => '0');
            end if;
        end if;
    end process;


    -------------------- Structural architecture of memory --------------------

    ramWrEn <= '1' when (to_integer(unsigned(addr)) >= 0 and to_integer(unsigned(addr)) <= CPU_RAM_MAX_ADDR) and memWrite = '1' else '0';

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

    U_DELAY_SWAP_COMPLETE : entity work.reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => '1',
        input => swap_complete_capture,
        output => swap_cmp_cap_del
    );

    -- Mux that controls what the CPU is reading
    U_READ_MUX : entity work.mux_4x1
    generic map (width => 32)
    port map (
        input1 => inport0Data,
        input2 => inport1Data,
        input3 => ramData,
        input4 => swap_cmp_cap_del,
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