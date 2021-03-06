library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_4x1 is
  generic (width : positive := 32);
  port(
    input1, input2, input3, input4 : in  std_logic_vector(width-1 downto 0);
    sel : in  std_logic_vector(1 downto 0);
    output : out std_logic_vector(width-1 downto 0)
  );
end mux_4x1;

architecture bhv of mux_4x1 is
begin
  process(input1, input2, input3, input4, sel)
  begin
    case sel is
      when "00" => output <= input1;
      when "01" => output <= input2;
      when "10" => output <= input3;
      when "11" => output <= input4;
      when others => null;
    end case;
  end process;
end bhv;
