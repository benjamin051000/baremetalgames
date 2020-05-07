library ieee;
use ieee.std_logic_1164.all;
entity vga_top is
	port (
		clk, rst : in std_logic;

		-- Signals for receiving VRAM data from CPU
		cpu_is_writing : in std_logic;
		wraddr, data : in std_logic_vector(11 downto 0);

		vga_hsync, vga_vsync : out std_logic;
		r, g, b : out std_logic_vector(3 downto 0)
	);
end vga_top;


architecture STR of vga_top is

	-- For active-low signals
	signal button_n : std_logic_vector(1 downto 0);

	-- VGA signals
	signal hcount, vcount : std_logic_vector(9 downto 0);
	signal video_on : std_logic;

begin -- STR

	-- VGA Sync Gen
	U_VGA_SYNC : entity work.vga_sync_gen
		port map(
			clk => clk,
			rst => rst,
			Hcount => hcount,
			Vcount => vcount,
			hsync => vga_hsync,
			vsync => vga_vsync,
			video_on => video_on
		);

	-- VGA video output generator
	U_RGB_GEN : entity work.rgb_gen
		port map(
			vcount => vcount,
			hcount => hcount,
			clk => clk,
			rst => rst,

			cpu_is_writing => cpu_is_writing,
			wraddr => wraddr,
			data => data,


			video_on => video_on,
			r => r,
			g => g,
			b => b
		);

end STR;
