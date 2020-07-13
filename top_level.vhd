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

    signal writing_to_vram : std_logic;
     
    signal wraddr, data : std_logic_vector(11 downto 0);

    signal rst_low : std_logic;

begin -- STR

    rst_low <= not rst;

    -- Clock generator
	U_CLK_DIV : entity work.clk_div
        generic map(
            clk_in_freq => 50000000, -- 50 MHz -> 25 MHz (for VGA core)
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

            -- Signals to connect to VGA controller
            writing_to_vram => writing_to_vram,
            vga_wraddr => wraddr,
            vga_data => data
        );


    U_VGA : entity work.vga_top
        port map(
            clk => clk_gen_out,
            rst => rst_low,

            cpu_says_swap_buf => writing_to_vram,
            swap_complete => open,
            wraddr => wraddr,
            data => data,
            back_buf_wren => '1',

            vga_hsync => vga_hsync,
            vga_vsync => vga_vsync,
            r => r,
            g => g,
            b => b
        );
end STR;
