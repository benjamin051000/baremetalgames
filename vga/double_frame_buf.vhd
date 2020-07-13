library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vga_lib.all;

entity double_frame_buf is
    port (
        clk, rst : in std_logic;
        -- readAddr: Address read from front buffer that goes to monitor.
        -- wrAddr: Address CPU writes data to in back buffer.
        -- data: data from CPU written into back buffer at wrAddr.
        readAddr, wrAddr, wrData : in std_logic_vector(11 downto 0);

        -- When the CPU is writing to the back buffer, set this flag.
        back_buf_wren : in std_logic;

        -- Signal from CPU when the back buffer is ready to be swapped. At the end of the draw, swap buffers.
        cpu_says_swap_buf : in std_logic;
        -- Once buffers have been swapped, use swap_complete to alert the cpu that it is ready to start writing to the new back buffer.
        swap_complete : out std_logic;
        
        -- Used to tell when the frame is done being drawn.
        video_on : in std_logic;
        vcount, hcount : in std_logic_vector(9 downto 0);

        -- Data coming from readAddr going to the monitor.
        readData : out std_logic_vector(11 downto 0)
    );
end double_frame_buf;


architecture bhv of double_frame_buf is

    signal addr_a, addr_b, readData_a, readData_b : std_logic_vector(11 downto 0);
    signal wren_a, wren_b : std_logic;

    -- Signals to tell when to swap frames, and when to alert cpu it's done.
    signal swap_frames, swap_complete_temp : std_logic;
    

    -- State to keep track of which RAM is being written to. 'A' means A is being written to (and B is being read from) and vice versa.
    type flip is (A, B);
    signal state, next_state : flip;

begin

    -- Instantiate RAM
    U_RAM_A : entity work.frame_buffer_ram
        generic map(name => "./a.mif")
        port map (
            clock => clk,
            address => addr_a,
            wren => wren_a,
            data => wrData,
            q => readData_a
        );

    U_RAM_B : entity work.frame_buffer_ram
        generic map(name => "./b.mif")
        port map (
            clock => clk,
            address => addr_b,
            wren => wren_b,
            data => wrData,
            q => readData_b
        );

    
    
    
    swap_complete <= swap_complete_temp;

    -- Sequential process to remember if swap_frames was asserted
    -- Set the swap frames flag when we have finished drawing the frame, and only if the CPU is done writing the next frame.
    process(clk, rst)
    begin
        if(rst = '1') then
            swap_frames <= '0';
        elsif rising_edge(clk) then
            -- Remember what the CPU tells us to do.
            if(video_on = '0' and cpu_says_swap_buf = '1') then
                swap_frames <= '1';
            end if;
            
            -- After the swap, reset it.
            if(swap_complete_temp = '1') then
                swap_frames <= '0';
            end if;
        end if;
    end process;
    
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
    process (state, readAddr, wrAddr, readData_a, readData_b, swap_frames, back_buf_wren)
    begin
        next_state <= state;
        swap_complete_temp <= '0';

        case state is
            when A =>
                -- Cpu writes to A, vga reads from B
                addr_a <= wrAddr;
                wren_a <= back_buf_wren;

                addr_b <= readAddr;
                wren_b <= '0';
                readData <= readData_b;  -- Buffer output (to RGB signals) comes from readAddr

                if (swap_frames = '1') then
                    next_state <= B;
                    -- On the next cycle, tell the CPU the swap was done.
                    swap_complete_temp <= '1';
                end if;


            when B =>
                -- Cpu writes to B, vga reads from A
                addr_b <= wrAddr;
                wren_b <= back_buf_wren;

                addr_a <= readAddr;
                wren_a <= '0';
                readData <= readData_a;

                if (swap_frames = '1') then
                    next_state <= A;
                    -- On the next cycle, tell the CPU the swap was done.
                    swap_complete_temp <= '1';
                end if;

            when others => null;
        end case;
    end process;
end bhv;