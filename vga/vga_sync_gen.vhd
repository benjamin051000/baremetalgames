library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_lib.all;


entity vga_sync_gen is
port (
    clk, rst : in std_logic;
    Hcount, Vcount : out std_logic_vector(9 downto 0);
    hsync, vsync, video_on : out std_logic
);
end vga_sync_gen;


architecture bhv of vga_sync_gen is
    signal h, v : natural;
begin
    -- Counters
    process(clk, rst)
    begin
        if(rst = '1') then
            v <= 0;
            h <= 0;
        elsif(rising_edge(clk)) then

            if(v = V_MAX) then
                v <= 0;
            elsif(h = H_VERT_INC) then
                v <= v + 1;
            end if;

            if(h = H_MAX) then
                h <= 0;
            else
                h <= h + 1;
            end if;
        end if;
    end process;

    
    -- Output process
    process(v, h)
    begin
        video_on <= '0';
        hsync <= '1'; -- Active L
        vsync <= '1';

        -- Video on
        if(h <= H_DISPLAY_END and v <= V_DISPLAY_END) then
            video_on <= '1';
        else
		  
            -- Otherwise, we're syncing or on f/b porch.
            if(h >= HSYNC_BEGIN and h <= HSYNC_END) then
                hsync <= '0'; -- Active L
            end if;
        
            if(v >= VSYNC_BEGIN and v <= VSYNC_END) then
                vsync <= '0';
            end if;
        
		  end if;
    end process;
	 
	 
	 Hcount <= std_logic_vector(to_unsigned(h, 10));
    Vcount <= std_logic_vector(to_unsigned(v, 10));

end bhv;
