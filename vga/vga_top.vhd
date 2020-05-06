-- Greg Stitt
-- University of Florida

-- The following entity is the top-level entity for lab 4. No changes are
-- required, but you need to map the I/O to the appropriate pins on the
-- board.

-- I/O Explanation (assumes the switches are on side of the
--                  board that is closest to you)
-- switch(9) is the leftmost switch
-- button(1) is the top button
-- led5 is the leftmost 7-segment LED
-- ledx_dp is the decimal point on the 7-segment LED for LED x

-- Note: this code will cause a harmless synthesis warning because not all
-- the buttons are used and because some output pins are always '0' or '1'

library ieee;
use ieee.std_logic_1164.all;
entity vga_top is
	port (
		clk50MHz : in std_logic;
		--        rst      : in  std_logic;
		switch : in std_logic_vector(9 downto 0);
		button : in std_logic_vector(1 downto 0);

		vga_hsync, vga_vsync : out std_logic;
		r, g, b : out std_logic_vector(3 downto 0)

	);
end vga_top;


architecture STR of vga_top is

	signal clk_gen_out : std_logic;

	-- For active-low signals
	signal button_n : std_logic_vector(1 downto 0);

	-- VGA signals
	signal hcount, vcount : std_logic_vector(9 downto 0);
	signal video_on : std_logic;

begin -- STR

	button_n <= not button;
	-- Clock generator
	U_CLK_DIV : entity work.clk_div
		generic map(
			clk_in_freq => 50000000, -- 50 MHz -> 25 MHz
			clk_out_freq => 25000000
		)
		port map(
			clk_in => clk50MHz,
			clk_out => clk_gen_out,
			rst => button_n(0)
		);
	-- VGA Sync Gen
	U_VGA_SYNC : entity work.vga_sync_gen
		port map(
			clk => clk_gen_out,
			rst => button_n(0),
			Hcount => hcount,
			Vcount => vcount,
			hsync => vga_hsync,
			vsync => vga_vsync,
			video_on => video_on
		);
	-- VGA video output generator
	U_RGB_GEN : entity work.rgb_gen
		port map(
			inputs => switch(2 downto 0), -- Rightmost 3 switches
			vcount => vcount,
			hcount => hcount,
			clk => clk_gen_out,

			video_on => video_on,
			r => r,
			g => g,
			b => b
		);

end STR;