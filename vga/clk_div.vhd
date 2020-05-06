library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity clk_div is
    generic(clk_in_freq  : natural;
            clk_out_freq : natural);
    port (
        clk_in  : in  std_logic;
        clk_out : out std_logic;
        rst     : in  std_logic);
end clk_div;

architecture bhv of clk_div is
    signal count : natural;
    -- The highest count to reach before asserting clk_out to match the expected clk frequency.
    constant TOP : natural := clk_in_freq / clk_out_freq;
begin

    process(clk_in, rst)
    begin -- Sequential process
        if(rst = '1') then
            count <= 0;

        elsif(rising_edge(clk_in)) then
            count <= count + 1;

            if(count = TOP) then
                count <= 1;
            end if;
        end if;
    end process;

    clk_out <= '1' when count = TOP else '0';
    
end bhv;
