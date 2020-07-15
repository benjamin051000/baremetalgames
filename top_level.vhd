library ieee;
use ieee.std_logic_1164.all;

entity top_level is
    port (
        clk, rst : in std_logic;

        -- Video output signals
        vga_hsync, vga_vsync : out std_logic;
        r, g, b : out std_logic_vector(3 downto 0);
        
        -- IO for CPU
        inport_enable : in std_logic;
        switch : in std_logic_vector(9 downto 0);
        leds : out std_logic_vector(31 downto 0)
    );
end top_level;


architecture STR of top_level is

    signal clk_gen_out : std_logic;
    -- Used by the CPU to enable writing to the back buffer in the VGA core.
    signal vram_wren : std_logic;
    
    -- Signals for swapping the buffer in VGA core.
    signal cpu_says_swap_buf, swap_complete : std_logic;
     
    signal vga_wraddr, vga_data : std_logic_vector(11 downto 0);

    signal rst_low : std_logic;

begin -- STR

    rst_low <= not rst;

    -- Clock generator
	U_CLK_DIV : entity work.clk_div
        generic map(
            clk_in_freq => 50000000, -- 50 MHz -> 25 MHz
            clk_out_freq => 25000000
        )
        port map(
            clk_in => clk,
            clk_out => clk_gen_out,
            rst => rst_low
        );


    U_CPU : entity work.cpu_top
        port map(
            clk => clk_gen_out,
            rst => rst_low,
            inport_enable => inport_enable,
            switches => switch,
            leds => leds,

            -- CPU-VGA Communication signals
            vram_wren => vram_wren,
            vga_wraddr => vga_wraddr,
            vga_data => vga_data,
            
            cpu_says_swap_buf => cpu_says_swap_buf, -- To vga
            swap_complete => swap_complete  -- From vga
        );


    U_VGA : entity work.vga_top
        port map(
            clk => clk_gen_out,
            rst => rst_low,

            cpu_says_swap_buf => cpu_says_swap_buf, -- From cpu
            swap_complete => swap_complete,  -- To cpu
            wraddr => vga_wraddr,
            data => vga_data,
            back_buf_wren => vram_wren,

            vga_hsync => vga_hsync,
            vga_vsync => vga_vsync,
            r => r,
            g => g,
            b => b
        );
end STR;
