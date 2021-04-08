--------------------------------------------------------------
--RAM - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;

entity ram is
    generic(
        addressSize: natural := 4;
        wordSize: natural := 8
    );
    port(
        ck, wr: in bit;
        addr: in bit_vector(addressSize-1 downto 0);
        data_i: in bit_vector(wordSize-1 downto 0);
        data_o: out bit_vector(wordSize-1 downto 0)
    );
end entity ram;

architecture ram_arc of ram is
    type mem_type is array (0 to (2**addressSize-1)) of bit_vector(wordSize-1 downto 0);
    signal ramChip: mem_type;
    begin
        process (ck, wr, addr) is
        begin
            if (rising_edge(ck) and wr = '1') then
                ramChip(to_integer(unsigned(addr))) <= data_i;
                else if (wr = '0') then
                    data_o <= ramChip(to_integer(unsigned(addr)));
                end if;
            end if;
        end process;
end architecture ram_arc;
                
