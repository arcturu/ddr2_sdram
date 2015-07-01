library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SENDER32 is
    generic (
        wtime : std_logic_vector (15 downto 0) := x"1ADB"
    );
    port (
        clk : in std_logic;
        go : in std_logic;
        data : in std_logic_vector (31 downto 0);
        busy : out std_logic;
        RS_TX : out std_logic
    );
end SENDER32;

architecture struct of SENDER32 is
    signal buff : std_logic_vector (31 downto 0);
    signal sender_go : std_logic;
    signal sender_data : std_logic_vector (7 downto 0);
    signal sender_busy : std_logic;
    signal st : std_logic_vector (1 downto 0) := "00";
    signal counter : std_logic_vector (1 downto 0) := "00";
    component SENDER is
        generic (
            wtime : std_logic_vector (15 downto 0)
        );
        port (
            clk : in std_logic;
            go : in std_logic;
            data : in std_logic_vector (7 downto 0);
            busy : out std_logic;
            RS_TX : out std_logic
        );
    end component;
begin
    sender1 : SENDER generic map (wtime) port map (
        clk => clk,
        go => sender_go,
        data => sender_data,
        busy => sender_busy,
        RS_TX => RS_TX
    );

    busy <= '0' when st = "00" else '1';
    sender_data <= buff (31 downto 24);
    
    process (clk)
    begin
        if rising_edge(clk) then
            case st is
                when "00" =>
                    sender_go <= '0';
                    if go = '1' then
                        buff <= data;
                        counter <= "11";
                        st <= "01";
                    end if;
                when "01" =>
                    if sender_busy = '0' then
                        st <= "10";
                        sender_go <= '1';
                    else
                        sender_go <= '0';
                    end if;
                when "10" =>
                    buff <= buff (23 downto 0) & x"00";
                    counter <= std_logic_vector(unsigned(counter) - 1);
                    if counter = "00" then
                        st <= "00";
                    else
                        st <= "01";
                    end if;
                when others =>
                    st <= "00";
            end case;
        end if;
    end process;
end struct;
