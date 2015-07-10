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

    type t_mem is array (16383 downto 0) of std_logic_vector (63 downto 0);
    signal mem : t_mem;
    signal st : std_logic_vector (3 downto 0) := "0000";
    signal command : std_logic_vector (3 downto 0);
    type t_addr is array (2 downto 0) of std_logic_vector (13 downto 0);
    signal addr : t_addr;
    type t_e is array (2 downto 0) of std_logic;
    signal we : t_e;
begin
    command(3) <= XCS(1);
    command(3) <= XCS(0);
    command(2) <= XRAS;
    command(1) <= XCAS;
    command(0) <= XWE;

    addr(0) <= A;
    process (CK(0))
    begin
        if rising_edge(CK(0)) then
            addr(2) <= addr(1); addr(1) <= addr(0);
            we(2) <= we(1); we(1) <= we(0);
            case command is
                when WRITE =>
                    we(0) <= '1';
                when READ =>
                    we(0) <= '0';
            end case;
        end if;
    end process;

    process (CK(0))
    begin
        if rising_edge(CK(0)) then
            if we(2) = '1' then
                writing <= '1';
            else
                writing <= '0';
            end if;
        end if;
    end process;

    process (DQS(0))
    begin
        if writing = '1' and rising_edge(DQS(0)) or falling_edge(DQS(0)) then
            mem(to_integer(unsigned(addr(2)))) <= DQ;
        end if;
    end process;
end behaviour;
