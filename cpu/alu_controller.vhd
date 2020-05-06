library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity alu_controller is
port (
    IR : in std_logic_vector(5 downto 0);
    ALUOp : in instruction;
    IR_20_16 : in std_logic_vector(20 downto 16); -- from IR for bltz and bgez

    OPSelect : out instruction;
    HI_en, LO_en : out std_logic;
    ALU_LO_HI : out std_logic_vector(1 downto 0)
);
end alu_controller;


architecture bhv of alu_controller is
begin

    process(IR, ALUOp, IR_20_16)
    begin

        OPselect <= (others => '0');
        HI_en <= '0';
        LO_en <= '0';
        ALU_LO_HI <= "00";

        case ALUOp is

            -- R-type instructions
            when c_r_type =>
                OPSelect <= IR;
                
                -- If it's a multiply, enable LO and HI regs.
                if(unsigned(IR) = unsigned(ins_MULT) or unsigned(IR) = unsigned(ins_MULTU)) then
                    HI_en <= '1';
                    LO_en <= '1';
                
                -- If move from hi/lo, change mux.
                elsif(unsigned(IR) = unsigned(ins_mflo)) then
                    ALU_LO_HI <= "01";
                elsif(unsigned(IR) = unsigned(ins_mfhi)) then
                    ALU_LO_HI <= "10";
                end if;


            -- For branch < 0 or branch >= 0
            when ins_bltz_OR_bgez =>
                if (to_integer(unsigned(IR_20_16)) = 1) then
                    OPSelect <= ins_bgez;
                else
                    OPSelect <= ins_bltz;
                end if;


            -- Otherwise, use the ALUOp instruction.
            when others =>
                OPSelect <= ALUOp;

        end case;

    end process;

end bhv;
