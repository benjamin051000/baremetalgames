library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_lib.all;


entity rgb_gen is
port (
	vcount, hcount : in std_logic_vector(9 downto 0);
	-- video_on and vsync controlled by sync gen
	video_on, vsync : in std_logic;
	clk, rst : in std_logic;

	cpu_says_swap_buf : in std_logic;
	swap_complete : out std_logic;
	wraddr, data : in std_logic_vector(11 downto 0);
	back_buf_wren : in std_logic;
	
	r, g, b : out std_logic_vector(3 downto 0)
);
end rgb_gen;


architecture bhv of rgb_gen is
	
	signal readaddr, q : std_logic_vector(11 downto 0);
	signal location : natural;
	signal en : std_logic;
	signal u_vcnt, u_hcnt, row_offset, col_offset, row, col : unsigned(9 downto 0);
	
begin
	
	-- Instantiate frame buffer
	U_FRAME_BUF : entity work.double_frame_buf
		port map (
			clk => clk,
			rst => rst,

			cpu_says_swap_buf => cpu_says_swap_buf,
			swap_complete => swap_complete,

			vsync => vsync,
			vcount => vcount,
			hcount => hcount,

			readAddr => readaddr,
			wrAddr => wraddr,
			wrData => data,
			back_buf_wren => back_buf_wren,
			
			readData => q
		);
	

	-- Create location based off the inputs.
	u_vcnt <= unsigned(vcount);
	u_hcnt <= unsigned(hcount);


	-- Generate VRAM readaddr from row and column.
	row <= shift_right((u_vcnt - row_offset), 1);
	col <= shift_right((u_hcnt - col_offset), 1); -- Change to unsigned.
	readaddr <= std_logic_vector(row(5 downto 0) & col(5 downto 0));
	

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


	-- Output signals
	r <= q(11 downto 8) when video_on = '1' and en = '1' else "0000";
	g <= q(7 downto 4) when video_on = '1' and en = '1' else "0000";
	b <= q(3 downto 0) when video_on = '1' and en = '1' else "0000";

end bhv;