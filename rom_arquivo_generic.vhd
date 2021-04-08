--------------------------------------------------------------
--ROM ARQUIVO (GENERIC) - SD2
--------------------------------------------------------------
library IEEE;
use IEEE.numeric_bit.all;
use std.textio.all;

entity rom_arquivo_generica is
    generic(
        addressSize: natural := 4;
        wordSize: natural := 8;
        datFileName: string := "rom.dat"
    );
    port(
        addr: in bit_vector(addressSize-1 downto 0);
        data: out bit_vector(wordSize-1 downto 0)
    );
end entity rom_arquivo_generica;

architecture rom_arquivo_generica_arc of rom_arquivo_generica is
    type mem_type is array (0 to (2**addressSize-1)) of bit_vector(wordSize-1 downto 0);
    --ROTINA DE LEITURA DE MEMORIA
    impure function rom_init return mem_type is
        file archive: text open read_mode is datFileName;
        variable line_read: line;
        variable rom_data: mem_type;
    begin
        for i in 0 to (2**addressSize-1) loop
            readline(archive, line_read);
            read(line_read, rom_data(i));
        end loop;

        return rom_data;
    end;
    --FIM DA ROTINA
    signal rom: mem_type := rom_init;
    begin
        data <= rom(to_integer(unsigned(addr)));
end architecture rom_arquivo_generica_arc;
