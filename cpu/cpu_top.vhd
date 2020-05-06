library ieee;
use ieee.std_logic_1164.all;
use work.common.all;

entity cpu_top is
port(
    clk, rst : in std_logic;
    inport_enable : in std_logic; -- This (and rst) will be assigned to buttons 
    switches : in std_logic_vector(9 downto 0);
    leds : out std_logic_vector(31 downto 0)
);
end cpu_top;


architecture bhv of cpu_top is
    
    signal sig_PCWrite, sig_PCWriteCond : std_logic;
    signal sig_IorD, sig_MemWrite, sig_MemToReg, sig_IRWrite, sig_JumpAndLink, sig_IsSigned : std_logic;
    signal sig_PCSource : std_logic_vector(1 downto 0);
    signal sig_ALUOp : instruction;
    signal sig_ALUSrcB : std_logic_vector(1 downto 0);
    signal sig_ALUSrcA : std_logic;
    signal sig_RegWrite, sig_RegDst : std_logic;
    signal sig_IR_in, sig_IR_in_low : instruction; -- Opcode from IR (31..26)
    
    
begin

    -- Instantiate controller
    U_CONTROLLER : entity work.controller
    port map (
        PCWrite => sig_PCWrite, 
        PCWriteCond => sig_PCWriteCond,
        IorD => sig_IorD,
        MemWrite => sig_MemWrite,
        MemToReg => sig_MemToReg,
        IRWrite => sig_IRWrite,
        JumpAndLink => sig_JumpAndLink,
        IsSigned => sig_IsSigned,
        PCSource => sig_PCSource,
        ALUOp => sig_ALUOp,
        ALUSrcB => sig_ALUSrcB,
        ALUSrcA => sig_ALUSrcA,
        RegWrite => sig_RegWrite,
        RegDST => sig_RegDst,
        IR_in => sig_IR_in,
        IR_in_low => sig_IR_in_low,
        clk => clk,
        rst => rst
    );

    U_DATAPATH : entity work.datapath
    port map (
        PCWrite => sig_PCWrite, 
        PCWriteCond => sig_PCWriteCond,
        IorD => sig_IorD,
        MemWrite => sig_MemWrite,
        MemToReg => sig_MemToReg,
        IRWrite => sig_IRWrite,
        JumpAndLink => sig_JumpAndLink,
        IsSigned => sig_IsSigned,
        PCSource => sig_PCSource,
        ALUOp => sig_ALUOp,
        ALUSrcB => sig_ALUSrcB,
        ALUSrcA => sig_ALUSrcA,
        RegWrite => sig_RegWrite,
        RegDST => sig_RegDst,
        IR_out_to_ctrl => sig_IR_in,
        IR_out_low => sig_IR_in_low,
        clk => clk,
        rst => rst,

        inport_enable => inport_enable,
        switches => switches,
        leds => leds
    );



end bhv;