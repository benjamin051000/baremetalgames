library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_lib.all;

entity double_frame_buf is
    port (
        clk, rst : in std_logic;
        readAddr, wrAddr, data : in std_logic_vector(11 downto 0);

        -- Ensures switching does not occur when CPU is writing.
        cpu_is_writing, video_on : in std_logic;
        vcount, hcount : in std_logic_vector(9 downto 0);

        q : out std_logic_vector(11 downto 0)
    );
end double_frame_buf;


architecture bhv of double_frame_buf is

    signal addr_a, addr_b, q_a, q_b : std_logic_vector(11 downto 0);
    signal wren_a, wren_b : std_logic;

    signal swap_frames : std_logic;

    -- State to keep track of which RAM is being written to. 'A' means A is being written to (and B is being read from) and vice versa.
    type flip is (A, B);
    signal state, next_state : flip;

begin

    -- Instantiate RAM
    U_RAM_A : entity work.vga_ram
        port map (
            clock => clk,
            address => addr_a,
            wren => wren_a,
            data => data,
            q => q_a
        );

    U_RAM_B : entity work.vga_ram
        port map (
            clock => clk,
            address => addr_b,
            wren => wren_b,
            data => data,
            q => q_b
        );

    
    -- Set the swap frames flag when we have finished drawing the frame, and only if the CPU is done writing the next frame.
    swap_frames <= '1' when to_integer(unsigned(vcount)) = 0 and to_integer(unsigned(hcount)) = H_MAX and cpu_is_writing = '0' else '0';
    
    
    -- Sequential process to handle state transition
    process (clk, rst)
    begin
        if (rst = '1') then
            state <= B; -- Start on B so there is only one empty frame.
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- Combinational process to determine outputs based on state and inputs
    process (state, readAddr, wrAddr, q_a, q_b, swap_frames, cpu_is_writing)
    begin

        next_state <= state;

        case state is
            when A =>
                -- Write to A, read from B
                addr_a <= wrAddr;
                wren_a <= cpu_is_writing;

                addr_b <= readAddr;
                wren_b <= '0';
                q <= q_b;  -- Buffer output (to RGB signals) comes from readAddr

                if (swap_frames = '1') then
                    next_state <= B;
                end if;


            when B =>
                -- Write to B, read from A
                addr_b <= wrAddr;
                wren_b <= cpu_is_writing;

                addr_a <= readAddr;
                wren_a <= '0';
                q <= q_a;

                if (swap_frames = '1') then
                    next_state <= A;
                end if;

            when others => null;
        end case;
    end process;
end bhv;