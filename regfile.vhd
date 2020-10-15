--------------------------------------------------------------
--REGISTRADOR (T3A1) - GUILHERME ALVARENGA DIAS - SD2
--------------------------------------------------------------
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
--REGISTRADOR (T3A2) - GUILHERME ALVARENGA DIAS - SD2
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

        

