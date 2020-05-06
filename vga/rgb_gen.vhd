library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_lib.all;


entity rgb_gen is
port (
	vcount, hcount : in std_logic_vector(9 downto 0);
	-- video_on controlled by sync gen
	video_on, clk : in std_logic;

	wren : in std_logic;
	data : in std_logic_vector(11 downto 0);
	
	r, g, b : out std_logic_vector(3 downto 0)
);
end rgb_gen;


architecture bhv of rgb_gen is
	
	signal address, q : std_logic_vector(11 downto 0);
	signal location : natural;
	signal en : std_logic;
	signal u_vcnt, u_hcnt, row_offset, col_offset, row, col : unsigned(9 downto 0);
	
begin
	
	-- Instantiate ROM
	U_RAM : entity work.vga_ram
	port map (
		address => address,
		clock => clk,
		q => q,

		-- Used for input from CPU
		wren => wren,
		data => data
	);
	
	
	-- Output signals
	r <= q(11 downto 8) when video_on = '1' and en = '1' else "0000";
	g <= q(7 downto 4) when video_on = '1' and en = '1' else "0000";
	b <= q(3 downto 0) when video_on = '1' and en = '1' else "0000";
	

	-- Create location based off the inputs.
	u_vcnt <= unsigned(vcount);
	u_hcnt <= unsigned(hcount);


	-- Generate ROM address from row and column.
	row <= shift_right((u_vcnt - row_offset), 1); -- Uses floor division.
	col <= shift_right((u_hcnt - col_offset), 1); -- Change to unsigned.
	
	address <= std_logic_vector(row(5 downto 0) & col(5 downto 0)); -- Concatenate vectors (lower 6 bits)
	

	process(u_vcnt, u_hcnt)
	begin
		en <= '0';
		row_offset <= (others => '0');
		col_offset <= (others => '0');
		
		if(u_vcnt >= CENTERED_Y_START and u_vcnt <= CENTERED_Y_END and
			u_hcnt >= CENTERED_X_START and u_hcnt <= CENTERED_X_END) then
				en <= '1';
				row_offset <= to_unsigned(CENTERED_Y_START, 10);
				col_offset <= to_unsigned(CENTERED_X_START, 10);
		end if;
	end process;

end bhv;