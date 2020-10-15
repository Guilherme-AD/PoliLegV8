--------------------------------------------------------------
--REGISTRADOR (T3A1) - GUILHERME ALVARENGA DIAS - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity reg is
    generic(
        wordSize: natural := 4
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

