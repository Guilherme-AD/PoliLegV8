------------------------------------------------------------------
--REGISTRADOR / COMPONENT (T3A1) - SD2
------------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity reg is
    generic(
        wordSize: natural := 64
    );
    port(
        clock: in bit;
        reset: in bit;
        load: in bit;
        d: in bit_vector(wordSize-1 downto 0);
        q: out bit_vector(wordSize-1 downto 0)
    );
end reg;

architecture reg_arc of reg is
    signal d_int: bit_vector(wordSize-1 downto 0);
    begin
        process (clock, reset, load) 
        begin
            if (reset = '1') then
                d_int <= (others => '0');
            elsif (rising_edge(clock) and load = '1') then
                d_int <= d;
            end if;
        end process;
        q <= d_int;
end architecture reg_arc;

--------------------------------------------------------------
--REGFILE / COMPONENT (T3A2) - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log2;

entity regfile is --REGISTER BANK (32 REGS / 64 BITS EACH - LEGV8 COMPLIANT)
    generic(
        regn: natural := 32;
        wordSize: natural := 64
    );
    port(
        clock: in bit;
        reset: in bit;
        regWrite: in bit;
        rr1, rr2, wr: in bit_vector(natural(ceil(log2(real(regn))))-1 downto 0);
        d: in bit_vector(wordSize-1 downto 0);
        q1, q2: out bit_vector(wordSize-1 downto 0) 
    );
end entity regfile;

architecture regfile_arc of regfile is
    --REG COMPONENT
    component reg is
        generic(
            wordSize: natural := 64
        );
        port(
            clock: in bit;
            reset: in bit;
            load: in bit;
            d: in bit_vector(wordSize-1 downto 0);
            q: out bit_vector(wordSize-1 downto 0)
        );
    end component reg;
    type ArrayRegisters is array(0 to regn-1) of bit_vector(wordSize-1 downto 0);
    signal outDataSignal: ArrayRegisters; --VETOR DE "WORDSIZE" BITS QUE LIGA OS "REGN-1" REGISTRADORES A SAIDA DE REGFILE
    signal dataSignal: ArrayRegisters; --VETOR DE "WORDSIZE" BITS QUE LIGA O D DO REGFILE A CADA UM DOS REGISTRADORES
    type WriteArray is array(0 to regn-1) of bit;
    signal writeSignal: WriteArray; --VETOR DE 1BIT QUE LIGA O SINAL REGWRITE A CADA UM DOS REGISTRADORES
    begin
        REG_GEN: for i in 0 to regn-2 generate
            REGX: reg 
            generic map(wordSize => wordSize) 
            port map(clock => clock, reset => reset, load => writeSignal(i), d => dataSignal(i), q => outDataSignal(i));
        end generate REG_GEN;
        
        REG0: reg --XZR
        generic map(wordSize => wordSize)
        port map(clock => clock, reset => '1', load => writeSignal(regn-1), d => dataSignal(regn-1), q => outDataSignal(regn-1));

        writeSignal(to_integer(unsigned(wr))) <= regWrite;
        dataSignal(to_integer(unsigned(wr))) <= d;
        q1 <= outDataSignal(to_integer(unsigned(rr1)));
        q2 <= outDataSignal(to_integer(unsigned(rr2)));
end architecture regfile_arc;

-----------------------------------------------------------------
--ALU (T5A2) / ADDER COMPONENT - SD2
-----------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity fulladder is
    port(
        a, b, cin: in bit;
        s, cout: out bit
    );
end entity fulladder;

architecture fulladder_arc of fulladder is
    signal internalSum: bit;
    begin
        internalSum <= a xor b;
        s <= internalSum xor cin;
        cout <= (a and b) or ((a or b) and cin);
end architecture fulladder_arc;
--------------------------------------------------------------
--ALU1BIT / COMPONENT (T5A2) - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity alu1bit is
    port(
        a, b, less, cin: in bit;
        result, cout, set, overflow: out bit;
        ainvert, binvert: in bit;
        operation: in bit_vector(1 downto 0)
    );
end entity alu1bit;

architecture alu1bit_arc of alu1bit is
    signal internalSum: bit;
    signal aInternal: bit;
    signal bInternal: bit;
    signal passB: bit;
    signal sToMux: bit;
    signal andInternal: bit;
    signal coutInternal: bit;
    signal orInternal: bit;
    component fulladder is
        port(
            a, b, cin: in bit;
            s, cout: out bit
        );
    end component fulladder;
    begin
        ADDER: fulladder port map(a => aInternal, b => bInternal, cin => cin, s => sToMux , cout => coutInternal); 
        
        aInternal <= a when (ainvert = '0') else
                    not(a);
        bInternal <= b when (binvert = '0') else
                    not(b);
        
        passB <= b;

        andInternal <= aInternal and bInternal;
        orInternal <= aInternal or bInternal;

        set <= sToMux;
        cout <= coutInternal;

        result <= sToMux when (operation = "10") else
                andInternal when (operation = "00") else
                orInternal when (operation = "01") else
                passB when (operation = "11");

        overflow <= cin xor coutInternal;
end architecture alu1bit_arc;

------------------------------------------------------------------
--COMPLETE ALU / COMPONENT (T5A2) - SD2
------------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity alu is
    generic(
        size: natural := 64
    );
    port(
        A, B: in bit_vector(size-1 downto 0);
        F: out bit_vector(size-1 downto 0);
        S: in bit_vector(3 downto 0);
        Z: out bit;
        Ov: out bit;
        Co: out bit
    );
end entity alu;

architecture alu_arc of alu is
    component alu1bit is
        port(
            a, b, less, cin: in bit;
            result, cout, set, overflow: out bit;
            ainvert, binvert: in bit;
            operation: in bit_vector(1 downto 0)
        );
    end component alu1bit;
    
    type cables is array (0 to size-1) of bit;
    signal carryCable: cables; --FIOS CONECTANDO OS COUT'S DA ALUi AOS CIN'S DA ALUi+1
    signal zeroCheck: cables; --VERIFICACAO DE ZERO
    signal ovfCheck: cables; --VERIFICACAO DE OVERFLOW
    
    signal check: bit_vector(size-1 downto 0); --AUXILIAR
    signal zeroComp: bit_vector(size-1 downto 0); --AUXILIAR

    signal subtraction: bit; --COLOCA CIN EM '1' NA PRIMEIRA ALU CASO A SUBTRACAO A-B ESTEJA SELECIONADA

    begin 

        ALU_GEN: for i in 0 to size-1 generate

            LOWERBIT: if i = 0 generate
                ALU0: alu1bit port map(A(0), B(0), zeroCheck(size-1), subtraction, check(0), carryCable(0), zeroCheck(0), ovfCheck(0), S(3), S(2), S(1 downto 0));
            end generate LOWERBIT;

            MIDBITS: if (i /= 0 and i /= (size-1)) generate
                ALUX: alu1bit port map(A(i), B(i), '0', carryCable(i-1), check(i), carryCable(i), zeroCheck(i), ovfCheck(i), S(3), S(2), S(1 downto 0));
            end generate MIDBITS;

            ENDBIT: if (i /= 0 and i = (size-1)) generate
                ALUF: alu1bit port map(A(size-1), B(size-1), '0', carryCable(size-2), check(size-1), carryCable(size-1), zeroCheck(size-1), ovfCheck(size-1), S(3), S(2), S(1 downto 0));
            end generate ENDBIT;

        end generate ALU_GEN;

        Ov <= ovfCheck(size-1);
        Co <= carryCable(size-1);

        F <= check; 

        zeroComp <= (others => '0');

        Z <= '1' when (check = zeroComp) else
            '0'; 

        subtraction <= (S(2) and S(1)) or (S(3) and S(2)) ; --CIN = 1 PARA SLT, SUB OU AND
end architecture alu_arc;

-----------------------------------------------------------------
--SIGNEXTEND / COMPONENT (T5A1) - SD2
-----------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity signExtend is 
    port(
        i: in bit_vector(31 downto 0);
        o: out bit_vector(63 downto 0)
    );
end entity signExtend;

architecture signExtend_arc of signExtend is
    signal iInternal: bit_vector(31 downto 0);
    signal concatenateB: bit_vector(37 downto 0); --EXTEND BRANCH
    signal concatenateCBZ: bit_vector(44 downto 0); --EXTEND CONDITIONAL BRANCH
    signal concatenateDATA: bit_vector(54 downto 0); --EXTEND D INTRUCTION
    begin
        concatenateB <= (others => '0');
        concatenateCBZ <= (others => '0');
        concatenateDATA <= (others => '0');
            --B
        o <= (concatenateB & i(25 downto 0)) when (i(31 downto 26) = "000101" and i(25) = '0') else
            (not(concatenateB) & i(25 downto 0)) when (i(31 downto 26) = "000101" and i(25) = '1') else
            --CBZ
            (concatenateCBZ & i(23 downto 5)) when (i(31 downto 24) = "10110100" and i(23) = '0') else
            (not(concatenateCBZ) & i(23 downto 5)) when (i(31 downto 24) = "10110100" and i(23) = '1') else
            --LDUR/STUR
            (concatenateDATA & i(20 downto 12)) when (i(31 downto 27) = "11111" and i(20) = '0') else
            (not(concatenateDATA) & i(20 downto 12)) when (i(31 downto 27) = "11111" and i(20) = '1');
end architecture signExtend_arc;

-----------------------------------------------------------------
--SHIFTLEFT2 / COMPONENT (T6A1) - SD2
-----------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity Shiftleft2 is
    port(
        shiftIN: in bit_vector(63 downto 0);
        clock: in bit;
        shiftOUT: out bit_vector(63 downto 0)
    );
end entity Shiftleft2;

architecture Shiftleft2_arc of Shiftleft2 is
    begin
        process (clock) is
            begin
                if falling_edge(clock) then --TESTE
                    shiftOUT <= shiftIN(61 downto 0) & "00";
                end if;
        end process;
end architecture Shiftleft2_arc;

-----------------------------------------------------------------
--PROCESSOR CONTROL UNIT (T5A4) - SD2
-----------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity controlunit is
    port(
        --To Datapath
        reg2loc: out bit;
        uncondbranch: out bit;
        branch: out bit;
        memRead: out bit;
        memToReg: out bit;
        aluOp: out bit_vector(1 downto 0);
        memWrite: out bit;
        aluSrc: out bit;
        regWrite: out bit;
        --From Datapath
        opcode: in bit_vector(10 downto 0)
    );
end entity controlunit;

architecture controlunit_arc of controlunit is --PARA SINAIS DONT CARE IREMOS SEMPRE DEIXAR O SINAL DEASSERTED
    begin
        --SINAIS DE CONTROLE 
        reg2loc <= '1' when (opcode = "11111000000") or (opcode(10 downto 3) = "10110100") or (opcode(10 downto 5) = "000101") else --DONT CARE PARA LDUR
                '0';

        uncondbranch <= '1' when (opcode(10 downto 5) = "000101") else
                    '0';

        branch <= '1' when (opcode(10 downto 3) = "10110100") else
                '0';

        memRead <= '1' when (opcode = "11111000010") else
                '0';

        memToReg <= '1' when (opcode = "11111000010") or (opcode(10 downto 3) = "101101100") else
                '0';
        
        aluOp <= "00" when (opcode = "11111000010") or (opcode = "11111000000") else --DONT CARE PARA INSTRUCOES BRANCH
                "01" when (opcode(10 downto 3) = "10110100") else
                "10";
        
        memWrite <= '1' when (opcode = "11111000000") else
                '0';
        
        aluSrc <= '1' when (opcode = "11111000000") or (opcode = "11111000010") else
                '0';

        regWrite <= '1' when (opcode = "11111000010") or (opcode = "10001011000") or (opcode = "11001011000") or (opcode = "10001010000") or (opcode = "10101010000") else
                '0';
         
end architecture controlunit_arc;

-----------------------------------------------------
--ALUCONTROL (T5A3) - SD2
-----------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity alucontrol is
    port(
        aluop: in bit_vector(1 downto 0);
        opcode: in bit_vector(10 downto 0);
        aluCtrl: out bit_vector(3 downto 0)
    );
end entity alucontrol;

architecture alucontrol_arc of alucontrol is
    begin
        aluCtrl <= "0010" when (aluop = "00") else
                "0111" when (aluop = "01") else
                "0010" when (aluop = "10" and opcode = "10001011000") else
                "0110" when (aluop = "10" and opcode = "11001011000") else
                "0000" when (aluop = "10" and opcode = "10001010000") else
                "0001" when (aluop = "10" and opcode = "10101010000") else
                "0000"; --SAIDA ARBITRARIA CASO INSTRUCAO B
end architecture alucontrol_arc;

-----------------------------------------------------------------
--DATAPATH (T6A1) - SD2
-----------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log2;

entity datapath is
    port(
        --Common
        clock: in bit;
        reset: in bit;
        --From Control Unit
        reg2loc: in bit;
        pcsrc: in bit;
        memToReg: in bit;
        aluCtrl: in bit_vector(3 downto 0);
        aluSrc: in bit;
        regWrite: in bit;
        --To Control Unit:
        opcode: out bit_vector(10 downto 0); 
        zero: out bit;
        --Instruction Memory Interface
        imAddr: out bit_vector(63 downto 0); 
        imOut: in bit_vector(31 downto 0); 
        --Data Memory Interface
        dmAddr: out bit_vector(63 downto 0); 
        dmIn: out bit_vector(63 downto 0); 
        dmOut: in bit_vector(63 downto 0)
    );
end entity datapath;

architecture datapath_arc of datapath is --REGFILE, ALU, SIGNEXTEND, SHIFTLEFT2
    --REGISTER / PROGRAM COUNTER
    component reg is
        generic(
            wordSize: natural := 64
        );
        port(
            clock: in bit;
            reset: in bit;
            load: in bit;
            d: in bit_vector(wordSize-1 downto 0);
            q: out bit_vector(wordSize-1 downto 0)
        );
    end component;
    --SHIFTLEFT2
    component Shiftleft2 is
        port(
            shiftIN: in bit_vector(63 downto 0);
            clock: in bit;
            shiftOUT: out bit_vector(63 downto 0)
        );
    end component Shiftleft2;
    --ALU W/ BRANCH
    component alu is
        generic(
            size: natural := 64
        );
        port(
            A, B: in bit_vector(size-1 downto 0);
            F: out bit_vector(size-1 downto 0);
            S: in bit_vector(3 downto 0);
            Z: out bit;
            Ov: out bit;
            Co: out bit
        );
    end component alu;
    --SIGNEXTEND
    component signExtend is 
    port(
        i: in bit_vector(31 downto 0);
        o: out bit_vector(63 downto 0)
    );
    end component signExtend;
    --REGFILE 
    component regfile is 
    generic(
        regn: natural := 32;
        wordSize: natural := 64
    );
    port(
        clock: in bit;
        reset: in bit;
        regWrite: in bit;
        rr1, rr2, wr: in bit_vector(natural(ceil(log2(real(regn))))-1 downto 0);
        d: in bit_vector(wordSize-1 downto 0);
        q1, q2: out bit_vector(wordSize-1 downto 0) 
    );
    end component regfile;
    --PC
    signal instruction_int: bit_vector(31 downto 0);
    signal instructionAddress: bit_vector(63 downto 0);
    signal nextAddress: bit_vector(63 downto 0);
    signal addressPlus4: bit_vector(63 downto 0);
    signal addressBranch: bit_vector(63 downto 0);
    --REGFILE 
    signal regMux: bit_vector(4 downto 0);
    signal readData1: bit_vector(63 downto 0);
    signal readData2: bit_vector(63 downto 0);
    signal memToRegMux: bit_vector(63 downto 0);
    --ALU
    signal ALUSrcMux: bit_vector(63 downto 0);
    signal ALUResult: bit_vector(63 downto 0);
    --SIGNEXTEND
    signal signExtToALU: bit_vector(63 downto 0);
    --SHIFTLEFT2
    signal shiftToPC: bit_vector(63 downto 0);
    begin
        --OUT SIGNALS
        instruction_int <= imOut;
        opcode <= imOut(31 downto 21);
        imAddr <= instructionAddress;
        --PROGRAM COUNTER
        PC: reg
        generic map(64)
        port map(clock, reset, '1', nextAddress, instructionAddress);
        ALU4: alu
        generic map(64)
        port map(instructionAddress, "0000000000000000000000000000000000000000000000000000000000000100", addressPlus4, "0010", open, open);
        ALUB: alu
        generic map(64)
        port map(instructionAddress, shiftToPC, addressBranch, "0010", open, open);
        nextAddress <= addressPlus4 when (pcsrc = '0') else
                            addressBranch;
        --REGFILE
        REGBANK: regfile
        generic map(32, 64)
        port map(clock, reset, regWrite, instruction_int(9 downto 5), regMux, instruction_int(4 downto 0), memToRegMux, readData1, readData2);
        regMux <= instruction_int(20 downto 16) when (reg2loc = '0') else
                instruction_int(4 downto 0);
        memToRegMux <= ALUResult when (memToReg = '0') else
                    dmOut;
        dmIn <= readData2;
        --ULA
        ALUMAIN: alu
        generic map(64)
        port map(readData1, ALUSrcMux, ALUResult, aluCtrl, zero, open, open);
        ALUSrcMux <= readData2 when (aluSrc = '0') else
                    signExtToALU;
        dmAddr <= ALUResult;

        --SIGNEXTEND
        SIGNEXT: signExtend
        port map(instruction_int, signExtToALU);

        --SHIFTLEFT2
        SHIFTLEFT: Shiftleft2
        port map(signExtToALU, clock, shiftToPC);
end architecture datapath_arc;
                        
-----------------------------------------------------------------
--CONTROL UNIT (T6A1) - SD2
-----------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity polilegsc is
    port(
        clock, reset: in bit;
        --DATA MEMORY
        dmem_addr: out bit_vector(63 downto 0);
        dmem_dati: out bit_vector(63 downto 0);
        dmem_dato: in bit_vector(63 downto 0);
        dmem_we: out bit;
        --INSTRUCTION MEMORY
        imem_addr: out bit_vector(63 downto 0);
        imem_data: in bit_vector(31 downto 0)
    );
end entity;

architecture polilegsc_arc of polilegsc is
    --CONTROL UNIT
    component controlunit is
        port(
            --To Datapath
            reg2loc: out bit;
            uncondbranch: out bit;
            branch: out bit;
            memRead: out bit;
            memToReg: out bit;
            aluOp: out bit_vector(1 downto 0);
            memWrite: out bit;
            aluSrc: out bit;
            regWrite: out bit;
            --From Datapath
            opcode: in bit_vector(10 downto 0)
        );
    end component controlunit;
    --ALU CONTROL UNIT
    component alucontrol is
        port(
            aluop: in bit_vector(1 downto 0);
            opcode: in bit_vector(10 downto 0);
            aluCtrl: out bit_vector(3 downto 0)
        );
    end component alucontrol;
    --DATAPATH
    component datapath is
        port(
            --Common
            clock: in bit;
            reset: in bit;
            --From Control Unit
            reg2loc: in bit;
            pcsrc: in bit; --CUSTOM
            memToReg: in bit;
            aluCtrl: in bit_vector(3 downto 0);
            aluSrc: in bit;
            regWrite: in bit;
            --To Control Unit:
            opcode: out bit_vector(10 downto 0); 
            zero: out bit;
            --Instruction Memory Interface
            imAddr: out bit_vector(63 downto 0); 
            imOut: in bit_vector(31 downto 0); 
            --Data Memory Interface
            dmAddr: out bit_vector(63 downto 0); 
            dmIn: out bit_vector(63 downto 0); 
            dmOut: in bit_vector(63 downto 0)
        );
    end component datapath;

    --CONNECTION SIGNALS
    signal reg2locWIRE: bit;
    signal memToRegWIRE: bit;
    signal regWriteWIRE: bit;
    signal aluCtrlWIRE: bit_vector(3 downto 0);
    signal aluOpWIRE: bit_vector(1 downto 0);
    signal aluSrcWIRE: bit;
    signal uncondbranchWIRE: bit;
    signal branchWIRE: bit;
    signal opcodeWIRE: bit_vector(10 downto 0);
    signal zeroWIRE: bit;
    signal pcsrcWIRE: bit;

    begin
        CONTROL: controlunit
        port map(
            reg2loc => reg2locWIRE,
            uncondbranch => uncondbranchWIRE,
            branch => branchWIRE,  
            memRead => open, 
            memToReg => memToRegWIRE,
            aluOp => aluOpWIRE,
            memWrite => dmem_we,
            aluSrc => aluSrcWIRE,
            regWrite => regWriteWIRE,
            opcode => opcodeWIRE
        );

        DATA: datapath
        port map(
            clock => clock,
            reset => reset,
            --From Control Unit
            reg2loc => reg2locWIRE,
            pcsrc => pcsrcWIRE,
            memToReg => memToRegWIRE,
            aluCtrl => aluCtrlWIRE,
            aluSrc => aluSrcWIRE,
            regWrite => regWriteWIRE,
            --To Control Unit:
            opcode => opcodeWIRE,
            zero => zeroWIRE,
            --Instruction Memory Interface
            imAddr => imem_addr,
            imOut => imem_data,
            --Data Memory Interface
            dmAddr => dmem_addr,
            dmIn => dmem_dati,
            dmOut => dmem_dato
        );

        --LOGICA ADICIONAL PARA FLUXO DO PC
        pcsrcWIRE <= (uncondbranchWIRE or (branchWIRE and zeroWIRE));

        ALUCTRL: alucontrol
        port map(
            aluop => aluOpWIRE,
            opcode => opcodeWIRE,
            aluCtrl => aluCtrlWIRE
        );
end architecture polilegsc_arc;





