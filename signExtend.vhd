------------------------------------------------------
--SIGNEXTEND (T5A1) - GUILHERME ALVARENGA DIAS - SD2
------------------------------------------------------
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


            

