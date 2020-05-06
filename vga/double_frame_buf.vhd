library ieee;
use ieee.std_logic_1164.all;

entity double_frame_buf is
port(
    clk : in std_logic;
    readAddr, wrAddr, data : in std_logic_vector(11 downto 0);

    -- Ensures switching does not occur when CPU is writing.
    cpu_is_writing : in std_logic;

    q : out  std_logic_vector(11 downto 0)
);
end double_frame_buf;


architecture bhv of double_frame_buf is
    
    signal addr_a, addr_b, q_a, q_b : std_logic_vector(11 downto 0);
    signal wren_a, wren_b : std_logic;

    -- State to keep track of which RAM is being written to. When '1', A is written to. When '0', B is written to.
    signal flip : std_logic := '1'; -- TODO remove default value


begin

	-- Instantiate RAM
	U_RAM_A : entity work.vga_ram
        port map (
            address => addr_a,
            clock => clk,
            q => q_a,
            -- Used for input from CPU
            wren => wren_a,
            data => data
        );

    U_RAM_B : entity work.vga_ram
        port map (
            address => addr_b,
            clock => clk,
            q => q_b,
            -- Used for input from CPU
            wren => wren_b,
            data => data
        );


        -- TODO: Implement switching logic (state machine)
        addr_a <= readAddr;
        wren_a <= '0';

        addr_b <= wrAddr;
        wren_b <= '1';

        -- This will not work, replace with state machine
        q <= q_a when flip = '1' and cpu_is_writing = '0' else q_b;
        
end bhv;