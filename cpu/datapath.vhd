library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity datapath is
port (
    PCWrite, PCWriteCond : in std_logic;
    IorD, MemWrite, MemToReg, IRWrite, JumpAndLink, IsSigned : in std_logic;
    PCSource : in std_logic_vector(1 downto 0);
    ALUOp : in instruction; -- TODO determine width
    ALUSrcB : in std_logic_vector(1 downto 0);
    ALUSrcA : in std_logic;
    RegWrite, RegDst : in std_logic;
    
    inport_enable : in std_logic; -- This (and rst) will be assigned to buttons 
    switches : in std_logic_vector(9 downto 0);
    leds : out std_logic_vector(31 downto 0);
    IR_out_to_ctrl, IR_out_low : out instruction; -- Output from IR 
    
    clk, rst : in std_logic;

    -- Used to send data to VRAM
    vram_wren : out std_logic;
    vga_wraddr, vga_data : out std_logic_vector(11 downto 0);

    cpu_says_swap_buf : out std_logic;
    swap_complete : in std_logic
);
end datapath;


architecture bhv of datapath is

    -- Component declarations
    component reg
        generic (width : positive := 32);
        port(clk, rst, en : in  std_logic;
            input : in  std_logic_vector(width-1 downto 0);
            output : out std_logic_vector(width-1 downto 0));
    end component;

    component mux_2x1
        generic (width : positive := 32);
        port(
            input1, input2 : in  std_logic_vector(width-1 downto 0);
            sel : in  std_logic;
            output : out std_logic_vector(width-1 downto 0));
    end component;

    -------------------------------- Signal Declarations --------------------------------
    
    -- Program counter and memory signals
    signal sig_pc_enable : std_logic;
    signal sig_pc_input, sig_pc_output: std_logic_vector(31 downto 0);
    signal sig_mem_addr : std_logic_vector(31 downto 0);

    signal sig_memory_out : std_logic_vector(31 downto 0);

    -- Instruction register output
    signal sig_IR_out : std_logic_vector(31 downto 0);

    -- Memory data register
    signal sig_mem_data_reg_out : std_logic_vector(31 downto 0);

    -- Register file, rega/regb, and ALU input signals
    signal sig_RF_data0, sig_RF_data1 : std_logic_vector(31 downto 0);
    signal sig_RF_wr_data : std_logic_vector(31 downto 0);
    signal sig_RF_wr_addr : std_logic_vector(4 downto 0);
    
    signal sig_regA_out, sig_regB_out : std_logic_vector(31 downto 0);
    
    -- RegB mux input (sign extend, shift left 2) signals
    signal sig_regb_in_sign_ext, sig_regb_in_shift_l : std_logic_vector(31 downto 0);

    -- ALU signals
    signal sig_ALU_in0, sig_ALU_in1 : std_logic_vector(31 downto 0);
    signal sig_alu_OPSelect : instruction;  -- instruction type from work.common
    signal sig_alu_branch_taken : std_logic;
    signal sig_alu_result, sig_alu_result_hi : std_logic_vector(31 downto 0);

    -- Signal for branch taken mux concat/shift left input
    signal sig_branch_taken_mux_concat : std_logic_vector(31 downto 0);

    -- ALU output registers
    signal sig_alu_out_reg, sig_LO_reg, sig_HI_reg : std_logic_vector(31 downto 0);

    -- ALU Controller signals
    signal sig_alu_ctrl_LO_en, sig_alu_ctrl_HI_en : std_logic;
    signal sig_alu_ctrl_ALU_LO_HI : std_logic_vector(1 downto 0); -- for alu out reg mux sel

    -- ALU register mux output (goes back to the register file)
    signal sig_alu_reg_mux_out : std_logic_vector(31 downto 0);

    -- Resized switch inputs to memory data
    signal switches_resized : std_logic_vector(31 downto 0);

begin

    ------------------------------- Program Counter Logic -------------------------------

    sig_pc_enable <= PCWrite or (PCWriteCond and sig_alu_branch_taken);

    U_PC : reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => sig_pc_enable,
        input => sig_pc_input,
        output => sig_pc_output
    );


    U_PC_OUT_MUX : mux_2x1
    generic map (width => 32)
    port map (
        input1 => sig_pc_output,
        input2 => sig_alu_out_reg,
        sel => IorD,
        output => sig_mem_addr
    );

    -------------------------------- Memory Logic ---------------------------------

    U_MEMORY : entity work.memory
    generic map (width => 32)
    port map(
        addr => sig_mem_addr,
        inputData => switches_resized,
        memWrite => MemWrite,
        inportEn => inport_enable, 
        inportEnSel => switches(9), -- Leftmost switch
        writeData => sig_regB_out,
        clk => clk,
        rst => rst,
        outportData => leds,
        readData => sig_memory_out,

        writing_to_vram => vram_wren,
        vga_wraddr => vga_wraddr,
        vga_data => vga_data,
        
        cpu_says_swap_buf => cpu_says_swap_buf,
        swap_complete => swap_complete
    );

    
    switches_resized <= std_logic_vector(resize(unsigned(switches(8 downto 0)), 32));


    -- Instruction register
    U_IR : reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => IRWrite,
        input => sig_memory_out,
        output => sig_IR_out
    );

    -- Feedback to controller
    IR_out_to_ctrl <= sig_IR_out(31 downto 26);
    IR_out_low <= sig_IR_out(5 downto 0);


    -- Memory data register
    U_MEM_DATA_REG : reg -- TODO verify all these ports are correct.
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => '1',
        input => sig_memory_out,
        output => sig_mem_data_reg_out
    );

    -------------------------------- Register File Logic --------------------------------

    -- Register file write address mux
    U_RF_WR_ADDR_MUX : mux_2x1
    generic map (width => 5)
    port map (
        input1 => sig_IR_out(20 downto 16),
        input2 => sig_IR_out(15 downto 11),
        sel => RegDst,
        output => sig_RF_wr_addr
    );

    -- Register file write data mux
    U_RF_WR_DATA_MUX : mux_2x1
    generic map (width => 32)
    port map (
        input1 => sig_alu_reg_mux_out,
        input2 => sig_mem_data_reg_out,
        sel => MemToReg,
        output => sig_RF_wr_data
    );

    -- Register file
    U_REG_FILE : entity work.register_file(async_read)
    port map(
        clk => clk,
        rst => rst,
        rd_addr0 => sig_IR_out(25 downto 21),
        rd_addr1 => sig_IR_out(20 downto 16),
        wr_addr => sig_RF_wr_addr, -- Titled "Write register" in datasheet schematic
        wr_data => sig_RF_wr_data,
        rd_data0 => sig_RF_data0,
        rd_data1 => sig_RF_data1,
        JandL => JumpAndLink,
        wr_en => RegWrite
    );

    -------------------------------- ALU Input Logic --------------------------------

    -- ALU Register A
    U_REG_A : reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => '1', -- TODO verify this enable signal
        input => sig_RF_data0,
        output => sig_regA_out
    );

    -- ALU Register B
    U_REG_B : reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => '1',
        input => sig_RF_data1,
        output => sig_regB_out
    );


    U_REG_A_MUX : mux_2x1
    generic map (width => 32)
    port map (
        input1 => sig_pc_output,
        input2 => sig_regA_out,
        sel => ALUSrcA,
        output => sig_ALU_in0
    );

    -- Logic for sign extension of IR[15..0] and left shift by 2
    process(sig_IR_out, IsSigned)
    begin
        -- Generate sign-extended signal
        if(IsSigned = '0') then
            sig_regb_in_sign_ext <= std_logic_vector( resize(unsigned(sig_IR_out(15 downto 0)), 32) );
        else
            sig_regb_in_sign_ext <= std_logic_vector( resize(signed(sig_IR_out(15 downto 0)), 32) );
        end if;
    end process;

    -- Generate left-shifted signal
    sig_regb_in_shift_l <= std_logic_vector( shift_left(unsigned(sig_regb_in_sign_ext), 2) );


    U_REG_B_MUX : entity work.mux_4x1
    generic map (width => 32)
    port map (
        input1 => sig_regB_out,
        input2 => std_logic_vector(to_unsigned(4, 32)),
        input3 => sig_regb_in_sign_ext,
        input4 => sig_regb_in_shift_l,
        sel => ALUSrcB,
        output => sig_ALU_in1
    );

    -------------------------------- ALU Output Logic --------------------------------

    U_ALU : entity work.alu
    generic map (width => 32)
    port map (
        in_a => sig_ALU_in0,
        in_b => sig_ALU_in1,
        shift => sig_IR_out(10 downto 6),
        opselect => sig_alu_OPSelect,
        
        result => sig_alu_result,
        result_hi => sig_alu_result_hi,
        branch_taken => sig_alu_branch_taken
    );


    -- Logic to concatenate and shift IR left for the branch taken mux
    sig_branch_taken_mux_concat <= sig_pc_output(31 downto 28) & sig_IR_out(25 downto 0) & "00";


    U_ALU_BRANCH_TAKEN_MUX : entity work.mux_3x1
    generic map (width => 32)
    port map (
        input1 => sig_alu_result,
        input2 => sig_alu_out_reg,
        input3 => sig_branch_taken_mux_concat,
        sel => PCSource,
        output => sig_pc_input
    );


    -- ALU output registers
    U_ALU_OUT_REG : reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => '1',
        input => sig_alu_result,
        output => sig_alu_out_reg
    );

    U_ALU_LO_REG : reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => sig_alu_ctrl_LO_en,
        input => sig_alu_result,
        output => sig_LO_reg
    );

    U_ALU_HI_REG : reg
    generic map (width => 32)
    port map (
        clk => clk,
        rst => rst,
        en => sig_alu_ctrl_HI_en,
        input => sig_alu_result_hi,
        output => sig_HI_reg
    );

    -- Mux connecting all the ALU output registers together
    U_ALU_REG_MUX : entity work.mux_3x1
    generic map (width => 32)
    port map (
        input1 => sig_alu_out_reg,
        input2 => sig_LO_reg,
        input3 => sig_HI_reg,
        sel => sig_alu_ctrl_ALU_LO_HI,
        output => sig_alu_reg_mux_out
    );

    -- ALU controller
    U_ALU_CTRL : entity work.alu_controller
    port map (
        IR => sig_ir_out(5 downto 0),
        ALUOp => ALUOp,
        
        IR_20_16 => sig_IR_out(20 downto 16),

        OPSelect => sig_alu_OPSelect,
        HI_en => sig_alu_ctrl_HI_en,
        LO_en => sig_alu_ctrl_LO_en,
        ALU_LO_HI => sig_alu_ctrl_ALU_LO_HI
    );

end bhv;