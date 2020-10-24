-----------------------------------------------------------------
--ALU (T4A1) / ADDER COMPONENT - GUILHERME ALVARENGA DIAS - SD2
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
----------------------------------------------------------
--ALU (T4A1) / COMPONENT - GUILHERME ALVARENGA DIAS - SD2
----------------------------------------------------------
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
        
        andInternal <= aInternal and bInternal;
        orInternal <= aInternal or bInternal;

        set <= sToMux;
        cout <= coutInternal;

        result <= sToMux when (operation = "10") else
                andInternal when (operation = "00") else
                orInternal when (operation = "01") else
                less when (operation = "11");

        overflow <= cin xor coutInternal;
end architecture alu1bit_arc;
-----------------------------------------------
--ALU (T4A2) - GUILHERME ALVARENGA DIAS - SD2
-----------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity alu is
    generic(
        size: natural := 10
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

