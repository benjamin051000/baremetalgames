library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity ALU is
generic(WIDTH : natural := 32);
port(
    in_a, in_b : in std_logic_vector(WIDTH-1 downto 0);
    shift : in std_logic_vector(4 downto 0); -- From IR (for shift instructions)
    opselect : in instruction; -- From common.vhd

    -- result_hi is the upper 32 bits of the mult instr.
    result, result_hi : out std_logic_vector(WIDTH-1 downto 0);
    branch_taken : out std_logic
);
end ALU;


architecture bhv of ALU is

begin

    process(in_a, in_b, shift, opselect)
        variable temp_mult : std_logic_vector(WIDTH*2 - 1 downto 0);
    begin

        -- Default values for outputs
        result_hi <= (others => '0');
        result <= (others => '0');
        branch_taken <= '0';

        case opselect is

            -- add operations
            when ins_ADDU | ins_ADDIU =>
                result <= std_logic_vector(unsigned(in_a) + unsigned(in_b));

            -- subtract operations
            when ins_SUBU | ins_SUBIU =>
                result <= std_logic_vector(unsigned(in_a) - unsigned(in_b));
            
            -- multiply operations
            when ins_MULT =>
                temp_mult := std_logic_vector(signed(in_a) * signed(in_b));
                
                result_hi <= temp_mult(WIDTH*2-1 downto WIDTH);
                result <= temp_mult(WIDTH-1 downto 0);

            when ins_MULTU =>
                temp_mult := std_logic_vector(unsigned(in_a) * unsigned(in_b));
                
                result_hi <= temp_mult(WIDTH*2-1 downto WIDTH);
                result <= temp_mult(WIDTH-1 downto 0);
            
            -- and
            when ins_AND | ins_ANDI =>
                result <= in_a and in_b;
            
            -- or
            when ins_OR | ins_ORI =>
                result <= in_a or in_b;
            
            -- xor
            when ins_XOR | ins_XORI =>
                result <= in_a xor in_b;
            
            -- shift right logical
            when ins_srl =>
                -- unsigned is a logical shift
                result <= std_logic_vector( shift_right(unsigned(in_b), to_integer(unsigned(shift))) );

            -- shift left logical
            when ins_sll =>
                result <= std_logic_vector( shift_left(unsigned(in_b), to_integer(unsigned(shift))) );

            -- shift right arithmetic
            when ins_sra =>
                -- signed is arithmetic shift
                result <= std_logic_vector( shift_right(signed(in_b), to_integer(unsigned(shift))) );
            
            -- set less than (signed)
            when ins_slt | ins_slti =>
                if(signed(in_a) < signed(in_b)) then
                    result <= (0 => '1', others => '0');  -- TODO should this be 1, or all 1s?
                else
                    result <= (others => '0');
                end if;

            -- set less than (unsigned)
            when ins_sltiu | ins_sltu =>
                if(unsigned(in_a) < unsigned(in_b)) then
                    result <= (0 => '1', others => '0');
                else
                    result <= (others => '0');
                end if;

            -- branch equal
            when ins_beq =>
                if(in_a = in_b) then
                    branch_taken <= '1';
                else
                    branch_taken <= '0';
                end if;
            
            -- branch not equal
            when ins_bne =>
                if(in_a /= in_b) then
                    branch_taken <= '1';
                else
                    branch_taken <= '0';
                end if;
            
            -- branch less than or equal to zero
            when ins_blez =>
                if(to_integer(signed(in_a)) <= 0) then
                    branch_taken <= '1';
                else
                    branch_taken <= '0';
                end if;
            
            -- branch greater than zero
            when ins_bgtz =>
                if(to_integer(signed(in_a)) > 0) then
                    branch_taken <= '1';
                else
                    branch_taken <= '0';
                end if;
            
            -- branch less than zero
            when ins_bltz =>
                if(to_integer(signed(in_a)) < 0) then
                    branch_taken <= '1';
                else
                    branch_taken <= '0';
                end if;

            -- branch greater than or equal to zero
            when ins_bgez =>
                if(to_integer(signed(in_a)) >= 0) then
                    branch_taken <= '1';
                else
                    branch_taken <= '0';
                end if;

            -- Pass inputA through (for JAL)
            when ins_passA =>
                result <= in_a;

            -- Jump register
            when ins_jr =>
                result <= in_a; -- passthrough a

            when others => null;
        end case;
    
    end process;

end bhv;