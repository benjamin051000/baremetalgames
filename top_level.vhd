library ieee;
use ieee.std_logic_1164.all;

entity top_level is
    port (
        clk, rst : in std_logic
    );
end top_level;


architecture bhv of top_level is
begin

    U_CPU : entity work.cpu_top
        port map(
            clk => clk,
            rst => rst,
            inport_enable => '0',
            switches => (others => '0'),
            leds => open
        );

    U_VGA : entity work.vga_top
        port map(
            clk50MHz => clk,
            switch => (others => '0'),
            button => (others => '0'),
            vga_hsync => open,
            vga_vsync => open,
            r => open,
            g => open,
            b => open
        );
end bhv;