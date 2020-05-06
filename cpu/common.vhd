library ieee;
use ieee.std_logic_1164.all;

package common is

    subtype instruction is std_logic_vector(5 downto 0); -- TODO may need to add range

    constant c_r_type : instruction := "000000";

    -- R-type constants
    constant ins_ADDU : instruction := "100001";
    constant ins_SUBU : instruction := "100011";
    constant ins_MULT : instruction := "011000";
    constant ins_MULTU : instruction := "011001";
    constant ins_AND : instruction := "100100";
    constant ins_OR : instruction := "100101";
    constant ins_XOR : instruction := "100110";
    constant ins_srl : instruction := "000010";
    constant ins_sll : instruction := "000000";
    constant ins_sra : instruction := "000011";

    constant ins_slt : instruction := "101010";
    constant ins_sltu : instruction := "101011";

    constant ins_mfhi : instruction := "010000";
    constant ins_mflo : instruction := "010010";
    
    constant ins_jr : instruction := "001000"; -- Jump register (r-type)
    
    -- I-type constants
    constant ins_ADDIU : instruction := "001001";
    constant ins_SUBIU : instruction := "010000"; -- not in MIPS
    constant ins_ANDI : instruction := "001100";
    constant ins_ORI : instruction := "001101";
    constant ins_XORI : instruction := "001110";
    constant ins_slti : instruction := "001010";
    constant ins_sltiu : instruction := "001011";


    -- Load/store instructions
    constant ins_load : instruction := "100011";
    constant ins_store : instruction := "101011";


    -- Jump/branch instructions
    constant ins_beq : instruction := "000100";
    constant ins_bne : instruction := "000101";
    constant ins_blez : instruction := "000110";
    constant ins_bgtz : instruction := "000111";

    constant ins_bltz_OR_bgez : instruction := "000001"; -- Same as bgez
    constant ins_bgez : instruction := "010101"; -- Used for bgez/bltz in alu ctrl (these two have random vals) (DO NOT USE THESE ANYWHERE ELSE (?))
    constant ins_bltz : instruction := "011101";

    constant ins_j : instruction := "000010";
    constant ins_jal : instruction := "000011";
    -- ins_jr is with r-type

    -- For JAL: Pass inputA through
    constant ins_passA : instruction := "111000";

end common;
