library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity controller is
port (
    PCWrite, PCWriteCond : out std_logic;
    IorD, MemWrite, MemToReg, IRWrite, JumpAndLink, IsSigned : out std_logic;
    PCSource : out std_logic_vector(1 downto 0);
    ALUOp : out instruction;
    ALUSrcB : out std_logic_vector(1 downto 0);
    ALUSrcA : out std_logic;
    RegWrite, RegDst : out std_logic;
    
    IR_in, IR_in_low : in instruction; -- Opcode from IR (31..26) as well as (5..0)
    
    clk, rst : in std_logic
);
end entity;

architecture bhv of controller is

    type controller_states is (ins_fetch, ins_fetch_2, ins_decode, Rtype_ex, Rtype_complete, Jump_complete, mem_addr_compute, mem_access_rd, mem_access_rd_2, mem_access_wr, mem_rd_complete, branch1, branch_complete, Itype_ex, Itype_complete, halt, jump_and_link, jump_and_link_2);

    signal state, next_state : controller_states;

begin

    -- Sequential process
    process(clk, rst)
    begin
        if (rst = '1') then
            null;
        elsif (rising_edge(clk)) then
            state <= next_state;
        end if;
    end process;


    -- Combinational process
    process(IR_in, IR_in_low, state)
    begin
        -- Default values
        
        MemWrite <= '0';
        IsSigned <= '0';
        MemToReg <= '0';

        RegWrite <= '0';
        RegDst <= '0';
        
        PCSource <= "00";
        PCWrite <= '0';
        PCWriteCond <= '0';
        
        ALUOp <= (others => '0');
        ALUSrcB <= "00"; -- '4' (so it always has a value)
        ALUSrcA <= '1';
        
        IRWrite <= '0';
        IorD <= '0';
        JumpAndLink <= '0';

        case state is

            -- 0. Instruction Fetch
            when ins_fetch =>
                -- Read from memory & store into IR
                -- MemRead <= '1'; (not necessary)
                IorD <= '0';
                IRWrite <= '0'; -- Since mem isn't ready yet

                -- Increment PC by 4.
                ALUSrcA <= '0'; -- From PC
                ALUSrcB <= "01"; -- 4
                ALUOp <= ins_ADDU;
                PCWrite <= '1';
                PCSource <= "00"; -- ALU out

                next_state <= ins_fetch_2;

            when ins_fetch_2 =>
                -- Read from memory & store into IR
                -- MemRead <= '1'; (not necessary)
                IorD <= '0';
                IRWrite <= '1';

                -- Increment PC by 4.
                ALUSrcA <= '0'; -- From PC
                ALUSrcB <= "01"; -- 4
                ALUOp <= ins_ADDU; 
                
                PCSource <= "00"; -- ALU out
                
                next_state <= ins_decode;



            -- 1.Instruction decode/register fetch
            when ins_decode =>
                
                case IR_in is  -- TODO add branch/jump decode
                    when c_r_type =>
                        next_state <= Rtype_ex;
                    
                    when ins_load | ins_store =>
                        next_state <= mem_addr_compute;

                    when "111111" =>
                        next_state <= halt;

                    -- jump to address
                    when ins_j =>
                        next_state <= Jump_complete;

                    -- jump and link
                    when ins_jal =>
                        next_state <= jump_and_link;

                    -- All the branch instructions
                    when ins_beq | ins_bne | ins_blez | ins_bgtz | ins_bltz_OR_bgez =>
                        next_state <= branch1;

                    -- other I-types
                    when others => -- TODO Make more robust at some point?
                        next_state <= Itype_ex;
                end case;  


            -- 6. (Op = R-type) Execution
            when Rtype_ex =>
                ALUSrcA <= '1'; -- Set regA as input
                ALUSrcB <= "00"; -- Set regB as input
                ALUOp <= c_r_type; -- ALU controller specifies function

                -- Check if it's a jump reigster, or just finish out the r-type.
                if (unsigned(IR_in_low) = unsigned(ins_jr)) then
                    PCWrite <= '1';
                    PCSource <= "00";
                    
                    next_state <= ins_fetch;
                else
                    next_state <= Rtype_complete;
                end if;

            
            -- 7. R-type completion
            when Rtype_complete =>
                RegDST <= '1'; -- destination reg address
                RegWrite <= '1';
                MemtoReg <= '0';

                next_state <= ins_fetch;


            -- I-type: execute instruction
            when Itype_ex => 
                ALUSrcA <= '1'; -- Set regA as input
                ALUSrcB <= "10"; -- Set 15..0 as input
                ALUOp <= IR_in; -- Send instruction to ALU controller
                next_state <= Itype_complete;

            -- I-type: Write to register file
            when Itype_complete =>
                RegDST <= '0'; -- rt is 20..16
                RegWrite <= '1';
                MemtoReg <= '0';

                next_state <= ins_fetch;

            
            -- 2. Memory address computation
            when mem_addr_compute => 
                ALUSrcA <= '1'; -- input regA
                ALUSrcB <= "10"; -- input from IR 15..0 (no shl)
                IsSigned <= '0'; -- Zero-extend address.
                ALUOp <= ins_ADDU; 

                if(unsigned(IR_in) = unsigned(ins_load)) then
                    next_state <= mem_access_rd;  -- Read
                else
                    next_state <= mem_access_wr; -- Write
                end if;


            -- 3. (Op = "LW") Memory access (load word)
            when mem_access_rd =>
                IorD <= '1';

                next_state <= mem_access_rd_2;

            -- Mem access read 2 (delay state)
            when mem_access_rd_2 =>
                -- Wait 1 state for RAM
                next_state <= mem_rd_complete;
            
            
            -- 4. Memory read completion step
            when mem_rd_complete =>
                -- Write to the register
                RegDst <= '0';
                RegWrite <= '1';
                MemToReg <= '1'; -- Send memory data reg to reg file

                next_state <= ins_fetch;


            -- 5. (Op = "SW") Memory access (store word)
            when mem_access_wr =>
                MemWrite <= '1';
                IorD <= '1';

                next_state <= ins_fetch;


            -- First branch stage
            when branch1 =>
                ALUSrcA <= '0';
                IsSigned <= '1';
                ALUSrcB <= "11"; -- Sign-ext and SHL by 2
                ALUOp <= ins_ADDU;
                -- This will store the program counter's branch location in ALUOut

                next_state <= branch_complete;

            -- 8. Branch completion
            when branch_complete =>
                ALUSrcA <= '1'; -- Input from regA
                ALUSrcB <= "00"; -- Input from regB
                PCWriteCond <= '1';
                PCSource <= "01";
                ALUOp <= IR_in;
                -- If branch_taken is asserted, new location in ALUOut will be written to PC

                next_state <= ins_fetch;
            
            
            -- 9. Jump Completion
            when Jump_complete =>
                PCWrite <= '1';
                PCSource <= "10"; -- from IR 25..0

                next_state <= ins_fetch;

            
            -- Jump and link
            when jump_and_link =>

                -- Save current program count (which was incremented in ins_fetch)
                ALUSrcA <= '0'; -- From PC
                ALUOp <= ins_passA;

                -- This will be stored in ALUOut on the next cycle.
                next_state <= jump_and_link_2;


            when jump_and_link_2 =>

                -- Write to reg 31 (via jump and link signal) from ALUOut
                ALUOp <= ins_passA; -- To ensure alu out mux passes ALUOut
                MemToReg <= '0';
                JumpAndLink <= '1';

                -- Link complete. Now we can jump.
                PCWrite <= '1';
                PCSource <= "10";

                next_state <= ins_fetch;
                

            when halt =>
                next_state <= halt;
                

            when others => 
                next_state <= state;
        end case;
        
    end process;

end bhv;