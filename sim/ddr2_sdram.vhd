library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DDR2_SDRAM is
    generic (
        cycle : time := 3.63 ns
    );
    port (
        DQ : inout std_logic_vector (63 downto 0);
        A : in std_logic_vector (13 downto 0);
        DQS : inout std_logic_vector (7 downto 0);
        XDQS : inout std_logic_vector (7 downto 0);
        DM : in std_logic_vector (7 downto 0);
        XCS : in std_logic_vector (1 downto 0);
        BA : in std_logic_vector (2 downto 0);
        XRAS : in std_logic;
        XCAS : in std_logic;
        XWE : in std_logic;
        ODT : in std_logic_vector (1 downto 0);
        CKE : in std_logic_vector (1 downto 0);
        CK : in std_logic_vector (1 downto 0);
        XCK : in std_logic_vector (1 downto 0)
    );
end DDR2_SDRAM;

architecture behaviour of DDR2_SDRAM is
    constant NOP  : std_logic_vector (3 downto 0) := "0111";
    constant PALL : std_logic_vector (3 downto 0) := "0010";
    constant MR   : std_logic_vector (3 downto 0) := "0000";
    constant REF  : std_logic_vector (3 downto 0) := "0001";
    constant ACT  : std_logic_vector (3 downto 0) := "0011";
    constant READ : std_logic_vector (3 downto 0) := "0101";
    constant WRITE: std_logic_vector (3 downto 0) := "0100";

    constant tWL : integer := 2;
    constant tRL : integer := 3;

--    type memtype is array (15 downto 0) of std_logic_vector (63 downto 0);
--    signal memory : memtype;
    signal st : std_logic_vector (3 downto 0) := "0000";
    signal command : std_logic_vector (3 downto 0);
begin
    command(3) <= XCS(1);
    command(3) <= XCS(0);
    command(2) <= XRAS;
    command(1) <= XCAS;
    command(0) <= XWE;

    process (CK(0))
    begin
        if rising_edge(CK(0)) then
            case command is
                when WRITE =>
                when READ =>
                    wait for (tRL - 1) * cycle;
                    DQS <= (others => '0');
                    XDQS <= (others => '1');
                    wait for cycle / 2;
                    DQS <= (others => '1');
                    XDQS <= (others => '0');
                    DQ <= x"0123456789abcdef";
                    wait for cycle / 2;
                    DQS <= (others => '0');
                    XDQS <= (others => '1');
                    DQ <= x"0123456789abcdee";
                    wait for cycle / 2;
                    DQS <= (others => '1');
                    XDQS <= (others => '0');
                    DQ <= x"0123456789abcded";
                    wait for cycle / 2;
                    DQS <= (others => '0');
                    XDQS <= (others => '1');
                    DQ <= x"0123456789abcdec";
                when others =>
                    DQS <= (others => 'Z');
                    XDQS <= (others => 'Z');
            end case;
        end if;
    end process;

end behaviour;
