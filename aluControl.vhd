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
