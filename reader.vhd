library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity READER is
    generic (
        wtime : std_logic_vector (15 downto 0) := x"1ADB"
    );
    port (
        clk : in std_logic;
        RS_RX : in std_logic;
        v : out std_logic;
        data : out std_logic_vector (7 downto 0)
    );
end READER;

architecture struct of READER is
    signal st : std_logic_vector (1 downto 0) := "00";
    signal counter : std_logic_vector (15 downto 0);
    signal bits : std_logic_vector (3 downto 0) := x"0";
    signal buff : std_logic_vector (7 downto 0);
	 signal rs_rxb : std_logic := '1';
begin
    v <= '1' when bits = x"8" else '0';
    data <= buff;

    main : process (clk)
    begin
        if rising_edge (clk) then
            rs_rxb <= RS_RX;
            case st is
                when "00" => -- waiting for Low
                    if rs_rxb = '0' then
                        st <= "01";
                        counter <= '0' & wtime (15 downto 1);
                    end if;
                when "01" => -- read through first zero
                    counter <= std_logic_vector(unsigned(counter) - 1);
                    if counter = x"0000" then
                        st <= "10";
                        counter <= wtime;
                        bits <= x"0";
                    end if;
                when "10" => -- read and save
                    counter <= std_logic_vector(unsigned(counter) - 1);
                    if counter = x"0000" then
                        bits <= std_logic_vector(unsigned(bits) + 1);
                        if bits = x"8" then
                            st <= "00";
                        else
                            buff <= rs_rxb & buff (7 downto 1);
                            counter <= wtime;
                        end if;
                    end if;
                when others =>
                    st <= "00";
            end case;
        end if;
    end process;
end struct;
