--------------------------------------------------------------
--1BIT FULL-ADDER - GUILHERME ALVARENGA DIAS - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity fa_1bit is
    port (
      A,B : in bit;       -- adends
      CIN : in bit;       -- carry-in
      SUM : out bit;      -- sum
      COUT : out bit      -- carry-out
      );
  end entity fa_1bit;
  
  architecture sum_minterm of fa_1bit is
  -- Canonical sum solution (sum of minterms)
  begin
    -- SUM = m1 + m2 + m4 + m7
    SUM <= (not(CIN) and not(A) and B) or
           (not(CIN) and A and not(B)) or
           (CIN and not(A) and not(B)) or
           (CIN and A and B);
    -- COUT = m3 + m5 + m6 + m7
    COUT <= (not(CIN) and A and B) or
            (CIN and not(A) and B) or
            (CIN and A and not(B)) or
            (CIN and A and B);
  end architecture sum_minterm;
--------------------------------------------------------------
--8BIT FULL-ADDER - GUILHERME ALVARENGA DIAS - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity fa_8bit is
    port (
      A,B  : in  bit_vector(7 downto 0);
      CIN  : in  bit;
      SUM  : out bit_vector(7 downto 0);
      COUT : out bit
      );
  end entity;
  
  architecture ripple of fa_8bit is
  -- Ripple adder solution
  
    --  Declaration of the 1-bit adder.  
    component fa_1bit
      port (
        A, B : in  bit;   -- adends
        CIN  : in  bit;   -- carry-in
        SUM  : out bit;   -- sum
        COUT : out bit    -- carry-out
      );
    end component fa_1bit;
  
    signal x,y :   bit_vector(7 downto 0);
    signal s :     bit_vector(7 downto 0);
    signal cin0 :  bit;
    signal cout0 : bit;  
    signal cout1 : bit;
    signal cout2 : bit;
    signal cout3 : bit;
    signal cout4 : bit;  
    signal cout5 : bit;
    signal cout6 : bit;
    signal cout7 : bit;
    
  begin
    
    -- Components instantiation
    ADDER0: entity work.fa_1bit port map (
      A => x(0),
      B => y(0),
      CIN => cin0,
      SUM => s(0),
      COUT => cout0
      );
  
    ADDER1: entity work.fa_1bit port map (
      A => x(1),
      B => y(1),
      CIN => cout0,
      SUM => s(1),
      COUT => cout1
      );
  
    ADDER2: entity work.fa_1bit port map (
      A => x(2),
      B => y(2),
      CIN => cout1,
      SUM => s(2),
      COUT => cout2
      );  
  
    ADDER3: entity work.fa_1bit port map (
      A => x(3),
      B => y(3),
      CIN => cout2,
      SUM => s(3),
      COUT => cout3
      );
  
    ADDER4: entity work.fa_1bit port map (
      A => x(4),
      B => y(4),
      CIN => cout3,
      SUM => s(4),
      COUT => cout4
      );
  
    ADDER5: entity work.fa_1bit port map (
      A => x(5),
      B => y(5),
      CIN => cout4,
      SUM => s(5),
      COUT => cout5
      );
  
    ADDER6: entity work.fa_1bit port map (
      A => x(6),
      B => y(6),
      CIN => cout5,
      SUM => s(6),
      COUT => cout6
      );  
  
    ADDER7: entity work.fa_1bit port map (
      A => x(7),
      B => y(7),
      CIN => cout6,
      SUM => s(7),
      COUT => cout7
      );
  
    x <= A;
    y <= B;
    cin0 <= CIN;
    SUM <= s;
    COUT <= cout7;
    
  end architecture ripple;
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
--REGISTER BANK (T3A2) - GUILHERME ALVARENGA DIAS - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log2;

entity regfile is 
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

--------------------------------------------------------------
--REGISTER W/ CALC (T3A3) - GUILHERME ALVARENGA DIAS - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log2;

entity calc is
    port(
        clock: in bit;
        reset: in bit;
        instruction: in bit_vector(15 downto 0);
        overflow: out bit;
        q1: out bit_vector(15 downto 0)
    );
end calc;

architecture calc_arc of calc is
    --REGISTER BANK
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
    --8 BIT FULL-ADDER
    component fa_8bit is
        port (
          A,B  : in  bit_vector(7 downto 0);
          CIN  : in  bit;
          SUM  : out bit_vector(7 downto 0);
          COUT : out bit
          );
      end component;
    --SIGNALS
    signal REG_OR_I: bit_vector(15 downto 0);
    signal ADDRESS_BUS: bit_vector(4 downto 0);
    signal WRITE_WIRE: bit;
    signal DATA_BUS: bit_vector(15 downto 0);
    signal OPER1_BUS: bit_vector(4 downto 0);
    signal Q1_BUS: bit_vector(15 downto 0); --OPER1
    signal Q2_BUS: bit_vector(15 downto 0); --OPER2
    signal Q1_ADDR_BUS: bit_vector(4 downto 0);
    signal Q2_ADDR_BUS: bit_vector(4 downto 0);
    signal ALU0_TO_ALU1_WIRE: bit;
    begin
        REGBANK: regfile
        generic map(32, 16)
        port map(clock, reset, WRITE_WIRE, Q1_ADDR_BUS, Q2_ADDR_BUS, ADDRESS_BUS, DATA_BUS, Q1_BUS, Q2_BUS);

        ALU0: fa_8bit
        port map(A => Q1_BUS(7 downto 0), B => REG_OR_I(7 downto 0), CIN => '0', SUM => DATA_BUS(7 downto 0), COUT => ALU0_TO_ALU1_WIRE);

        ALU1: fa_8bit
        port map(A => Q1_BUS(15 downto 8), B => REG_OR_I(15 downto 8), CIN => ALU0_TO_ALU1_WIRE, SUM => DATA_BUS(15 downto 8), COUT => open);

        process (clock, reset, instruction) is 
        begin
            if (instruction(15) = '1') then --ADD INSTRUCTION
                Q1_ADDR_BUS <= instruction(9 downto 5);
                Q2_ADDR_BUS <= instruction(14 downto 10);
                REG_OR_I <= Q2_BUS;
                ADDRESS_BUS <= instruction(4 downto 0);
                WRITE_WIRE <= '1';
                if((Q1_BUS(15) = '0' and Q2_BUS(15) = '0') and DATA_BUS(15) = '1') then --OVERFLOW CHECKS
                    overflow <= '1';
                elsif ((Q1_BUS(15) = '1' and Q2_BUS(15) = '1') and DATA_BUS(15) = '0') then
                    overflow <= '1';
                else
                    overflow <= '0';
                end if;
            
            elsif (instruction(15) = '0') then --ADDI INSTRUCTION
                Q1_ADDR_BUS <= instruction(9 downto 5);
                Q2_ADDR_BUS <= instruction(14 downto 10);
                if (Q2_ADDR_BUS(4) = '1') then --CONCATENATING IMMEDIATE VALUE
                    REG_OR_I <= "11111111111" & Q2_ADDR_BUS;
                elsif (Q2_ADDR_BUS(4) = '0') then
                    REG_OR_I <= "00000000000" & Q2_ADDR_BUS;
                end if;
                ADDRESS_BUS <= instruction(4 downto 0);
                WRITE_WIRE <= '1';
                if((Q1_BUS(15) = '0' and REG_OR_I(15) = '0') and DATA_BUS(15) = '1') then --OVERFLOW CHECKS
                    overflow <= '1';
                elsif ((Q1_BUS(15) = '1' and REG_OR_I(15) = '1') and DATA_BUS(15) = '0') then
                    overflow <= '1';
                else
                    overflow <= '0';
                end if;
            end if;
        end process;
        q1 <= Q1_BUS;
end architecture calc_arc;