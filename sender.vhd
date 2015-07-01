library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SENDER is
    generic (
        wtime : std_logic_vector (15 downto 0) := x"1ADB"
    );
    port (
        clk : in std_logic;
        go : in std_logic;
        data : in std_logic_vector (7 downto 0);
        busy : out std_logic;
        RS_TX : out std_logic
    );
end SENDER;

architecture struct of SENDER is
    signal st : std_logic_vector (1 downto 0) := "00";
    signal buff : std_logic_vector (9 downto 0) := (others => '1');
    signal counter : std_logic_vector (15 downto 0);
    signal sent : std_logic_vector (3 downto 0) := "0000";
begin
    RS_TX <= buff (0);
    busy <= '0' when st = "00" else '1';
    main : process (clk)
    begin
        if rising_edge (clk) then
            case st is
                when "00" => -- ready
                    if go = '1' then
                        buff <= '1' & data & '0';
                        st <= "01";
                        counter <= wtime;
                        sent <= x"a";
                    end if;
                when "01" => -- sending a bit
                    counter <= std_logic_vector(unsigned(counter) - 1);
                    if counter = x"0000" then
                        st <= "10";
                        sent <= std_logic_vector(unsigned(sent) - 1);
                    end if;
                when "10" => -- sent 1 bit
                    buff <= '1' & buff (9 downto 1);
                    counter <= wtime;
                    if sent = x"0" then
                        st <= "00"; -- sent 10 bits
                    else
                        st <= "01";
                    end if;
                when others => -- ??
                    st <= "00";
            end case;
        end if;
    end process;
end struct;
