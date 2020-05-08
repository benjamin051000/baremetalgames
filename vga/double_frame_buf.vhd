library ieee;
use ieee.std_logic_1164.all;

entity double_frame_buf is
port(
    clk, rst : in std_logic;
    readAddr, wrAddr, data : in std_logic_vector(11 downto 0);

    -- Ensures switching does not occur when CPU is writing.
    cpu_is_writing, video_on : in std_logic;

    q : out  std_logic_vector(11 downto 0)
);
end double_frame_buf;


architecture bhv of double_frame_buf is
    
    signal addr_a, addr_b, q_a, q_b : std_logic_vector(11 downto 0);
    signal wren_a, wren_b : std_logic;

    -- State to keep track of which RAM is being written to. 'A' means A is being written to (and B is being read from) and vice versa.
    type flip is (A, B);

    signal state, next_state : flip;

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


        -- Sequential process to handle state transition
        process(clk, rst)
        begin
            if(rst = '1') then
                state <= A;
            elsif rising_edge(clk) then
                state <= next_state;
            end if;
        end process;

        -- Combinational process to determine outputs based on state and inputs
        process(state, readAddr, wrAddr, q_a, q_b, video_on, cpu_is_writing)
        begin
            -- addr_a <= readAddr;
            -- wren_a <= '0';
            -- addr_b <= wrAddr;
            -- wren_b <= '1';
            -- q <= q_a;
            next_state <= state;

            case state is
                when A =>
                    -- Write to A, read from B
                    addr_a <= wrAddr;
                    wren_a <= '1';

                    addr_b <= readAddr;
                    wren_b <= '0';
                    -- Buffer output (to RGB signals) comes from readAddr
                    q <= q_b;

                    -- Only switch RAMs when the CPU is done writing and there is a VSYNC signal.
                    if(video_on = '0' and cpu_is_writing = '0') then
                        next_state <= B;
                    end if;


                when B =>
                    -- Write to B, read from A
                    addr_b <= wrAddr;
                    wren_b <= '1';

                    addr_a <= readAddr;
                    wren_a <= '0';
                    q <= q_a;

                    if(video_on = '0' and cpu_is_writing = '0') then
                        next_state <= A;
                    end if;

                when others => null;
            end case;

        end process;

end bhv;