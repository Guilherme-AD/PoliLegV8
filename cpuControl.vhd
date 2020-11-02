-----------------------------------------------------------------
--PROCESSOR CONTROL UNIT (T5A4) - GUILHERME ALVARENGA DIAS - SD2
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
        

