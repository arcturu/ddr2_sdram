library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BUFF32 is
    port (
        din : in std_logic_vector (7 downto 0);
        vin : in std_logic;
        dout : out std_logic_vector (31 downto 0);
        vout : out std_logic
    );
end BUFF32;

architecture struct of BUFF32 is
    signal buff : std_logic_vector (31 downto 0);
    signal counter : std_logic_vector (2 downto 0) := "000";
begin
    dout <= buff;
    vout <= counter (2);

    process (vin)
    begin
        if rising_edge(vin) then
            if counter = "100" then
                counter <= "001";
                buff (7 downto 0) <= din;
            else
                counter <= std_logic_vector(unsigned(counter) + 1);
                buff <= buff (23 downto 0) & din;
            end if;
        end if;
    end process;
end struct;
