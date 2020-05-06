library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity REG is
  generic (width : positive := 32);
  port(clk, rst, en : in  std_logic;
       input : in  std_logic_vector(width-1 downto 0);
       output : out std_logic_vector(width-1 downto 0));
end REG;

architecture bhv of REG is
begin
  process(clk, rst)
  begin
    if rst = '1' then
      output <= (others => '0');
    elsif (rising_edge(clk)) then
      if (en = '1') then
        output <= input;
      end if;
    end if;
  end process;
end bhv;
