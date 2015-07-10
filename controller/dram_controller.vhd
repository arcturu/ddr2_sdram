library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DRAM_CONTROLLER is
    port (
        clk : in std_logic;
        clkh : in std_logic;
        addr : in std_logic_vector (13 downto 0);
        bank_addr : in std_logic_vector (2 downto 0);
        cmd : in std_logic_vector (3 downto 0);
        ready : out std_logic;
        valid : out std_logic;
        busy : out std_logic;
        din : in std_logic_vector (63 downto 0);
        dout : out std_logic_vector (63 downto 0);

        DQ : inout std_logic_vector (63 downto 0);
        A : out std_logic_vector (13 downto 0);
        DQS : inout std_logic_vector (7 downto 0);
        XDQS : inout std_logic_vector (7 downto 0);
        DM : out std_logic_vector (7 downto 0);
        XCS : out std_logic_vector (1 downto 0);
        BA : out std_logic_vector (2 downto 0);
        XRAS : out std_logic;
        XCAS : out std_logic;
        XWE : out std_logic;
        ODT : out std_logic_vector (1 downto 0);
        CKE : out std_logic_vector (1 downto 0);
        CK : out std_logic_vector (1 downto 0);
        XCK : out std_logic_vector (1 downto 0)
    );
end DRAM_CONTROLLER;

architecture struct of DRAM_CONTROLLER is
    constant NOP  : std_logic_vector (3 downto 0) := "0111";
    constant PALL : std_logic_vector (3 downto 0) := "0010";
    constant MR   : std_logic_vector (3 downto 0) := "0000";
    constant REF  : std_logic_vector (3 downto 0) := "0001";
    constant ACT  : std_logic_vector (3 downto 0) := "0011";
    constant READ : std_logic_vector (3 downto 0) := "0101";
    constant WRITE: std_logic_vector (3 downto 0) := "0100";
    constant CTR_WRITE : std_logic_vector (3 downto 0) := "0001";
    constant CTR_READ  : std_logic_vector (3 downto 0) := "0010";
    constant CTR_ACT   : std_logic_vector (3 downto 0) := "0011";
    signal st : std_logic_vector (4 downto 0) := "00000";
    signal dram_ready : std_logic := '0';
    signal dram_init_waiting : std_logic := '0';
    signal counter : std_logic_vector (15 downto 0) := (others => '0');
    signal command : std_logic_vector (3 downto 0) := "0111";
    signal write_go : std_logic := '0';
    signal read_go : std_logic := '0';
    signal dqsb : std_logic := '0';
    signal dqs_go : std_logic := '0';
    signal dqs_zero : std_logic := '0';
    signal dq_z : std_logic := '1';
    signal in_buf : std_logic_vector (63 downto 0);
    signal counter2 : std_logic_vector (3 downto 0) := "0000";
    signal dqs_counter : std_logic_vector (15 downto 0) := x"0000";
    type t_dqbuf is array (3 downto 0) of std_logic_vector (63 downto 0);
    signal dqbuf : t_dqbuf := (others => (others => '0'));
begin

    ready <= dram_ready;

    CK(1) <= clk;
    CK(0) <= clk;
    XCK(1) <= not clk;
    XCK(0) <= not clk;
    ODT <= "00";

    -- TODO temporary setting
    DM <= (others => '0');

    XCS(1) <= command(3);
    XCS(0) <= command(3);
    XRAS <= command(2);
    XCAS <= command(1);
    XWE <= command(0);

    dqsb <= clk when dqs_go = '1' else '0' when dqs_zero = '1' else 'Z';

    DQS(0) <= dqsb;
    DQS(1) <= dqsb;
    DQS(2) <= dqsb;
    DQS(3) <= dqsb;
    DQS(4) <= dqsb;
    DQS(5) <= dqsb;
    DQS(6) <= dqsb;
    DQS(7) <= dqsb;
    XDQS(0) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';
    XDQS(1) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';
    XDQS(2) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';
    XDQS(3) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';
    XDQS(4) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';
    XDQS(5) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';
    XDQS(6) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';
    XDQS(7) <= not dqsb when dqs_go = '1' or dqs_zero = '1' else 'Z';

    DQ <= in_buf when dq_z = '0' else (others => 'Z');

    -- FIXME just for debugging
    dout(15 downto 0) <= dqbuf(0)(15 downto 0);
    dout(31 downto 16) <= dqbuf(1)(15 downto 0);
    dout(47 downto 32) <= dqbuf(2)(15 downto 0);
--    dout(63 downto 48) <= dqbuf(3)(15 downto 0);
    dout(63 downto 48) <= dqs_counter;

    process (clkh)
    begin
        if rising_edge(clkh) then
            dqbuf(3) <= DQ;
            dqbuf(2) <= dqbuf(3);
            dqbuf(1) <= dqbuf(2);
            dqbuf(0) <= dqbuf(1);
        end if;
    end process;

    process (clk) -- to make DQS for writing
    begin
        if falling_edge(clk) then
            if write_go = '1' then
                dqs_go <= '1';
            else
                dqs_go <= '0';
            end if;
        end if;
    end process;

    process (clk) -- to make DQS's initial falling down
    begin
        if rising_edge(clk) then
            if write_go = '1' then
                dqs_zero <= '1';
            else
                dqs_zero <= '0';
            end if;
        end if;
    end process;

    process (DQS(0))
    begin
        if rising_edge(DQS(0)) then
            if read_go = '1' then
                dqs_counter <= std_logic_vector(unsigned(dqs_counter) + 1);
            end if;
        end if;
    end process;

    dram_init : process (clk)
    begin
        if falling_edge(clk) then
            if dram_init_waiting = '1' then
                command <= NOP;
                counter <= std_logic_vector(unsigned(counter) - 1);
                if counter = x"0000" then
                    st <= std_logic_vector(unsigned(st) + 1);
                    dram_init_waiting <= '0';
                end if;
            else
                case st is
                    when "00000" => -- initial state
                        dram_ready <= '0';
                        valid <= '0';
                        read_go <= '0';
                        CKE <= "00";
                        busy <= '1';
                        counter <= x"EA60"; -- 60000
                        dram_init_waiting <= '1';
                    when "00001" => -- clock enable and issue nop
                        CKE <= "11";
                        command <= NOP;
                        counter <= x"00ff";
                        dram_init_waiting <= '1';
                    when "00010" => -- issue PALL
                        command <= PALL;
                        A(10) <= '1';
                        counter <= x"00ff";
                        dram_init_waiting <= '1';
                    when "00011" => -- init EMR(2)
                        command <= MR;
                        BA <= "010";
                        A <= (others => '0');
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "00100" => -- init EMR(3)
                        command <= MR;
                        BA <= "011";
                        A <= (others => '0');
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "00101" => -- enable DLL
                        command <= MR;
                        BA <= "001";
                        A <= (others => '0');
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "00110" => -- reset DLL
                        command <= MR;
                        BA <= "000";
                        A <= "00000100000000";
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "00111" => -- precharge all
                        command <= PALL;
                        A(10) <= '1';
                        counter <= x"00ff";
                        dram_init_waiting <= '1';
                    when "01000" => -- auto reflesh 2 times
                        command <= REF;
                        counter <= x"00ff";
                        dram_init_waiting <= '1';
                    when "01001" => -- auto reflesh 2 times
                        command <= REF;
                        counter <= x"00ff";
                        dram_init_waiting <= '1';
                    when "01010" => -- set mode register
                        command <= MR;
                        BA <= "000";
                        A <= "00100001010010";
                        counter <= x"00C8";
                        dram_init_waiting <= '1';
                    when "01011" => -- set OCD default
                        command <= MR;
                        BA <= "001";
                        A <= "00001110000000";
                        counter <= x"00C8";
                        dram_init_waiting <= '1';
                    when "01100" => -- OCD exit
                        command <= MR;
                        BA <= "001";
                        A <= (others => '0');
                        counter <= x"00ff";
                        dram_init_waiting <= '1';
                    when "01101" => -- ready
                        command <= NOP;
                        dram_ready <= '1';
                        case cmd is
                            when CTR_WRITE =>
                                st <= "01110"; -- DRAM_WRITE;
                                busy <= '1';
                            when CTR_READ =>
                                st <= "10011"; -- DRAM_READ;
                                busy <= '1';
                            when CTR_ACT =>
                                st <= "10101";
                                busy <= '1';
                            when others =>
                                busy <= '0';
                        end case;
                    when "01110" => -- DRAM_WRITE =>
                        command <= WRITE;
                        BA <= bank_addr;
                        A <= addr;
                        in_buf <= din;
                        counter <= x"0001";
                        dram_init_waiting <= '1';
                    when "01111" => -- start DQS
                        command <= NOP;
                        dq_z <= '0';
                        write_go <= '1';
                        counter <= x"0003";
                        dram_init_waiting <= '1';
                    when "10000" => -- end DQS
                        command <= NOP;
                        write_go <= '0';
                        counter <= x"0000";
                        dram_init_waiting <= '1';
                    when "10001" => -- flush buffer
                        command <= NOP;
                        in_buf <= (others => '0');
                        counter <= x"0004"; -- TODO: wait for tWR ??
                        dram_init_waiting <= '1';
                    when "10010" =>
                        command <= NOP;
                        dq_z <= '1';
                        busy <= '0';
                        st <= "01101"; -- ready
                    when "10011" => -- DRAM_READ =>
                        command <= READ;
                        BA <= bank_addr;
                        A <= addr;
                        dq_z <= '1';
                        read_go <= '1';
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "10100" =>
                        command <= NOP;
                        valid <= '1';
                        st <= "01101";
                        busy <= '0';
                    when "10101" => -- DRAM_ACT =>
                        command <= ACT;
                        BA <= bank_addr;
                        A <= addr;
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "10110" =>
                        st <= "01101";
                        busy <= '0';
                    when others => -- ??
                        command <= NOP;
                        st <= "00000";
                end case;
            end if;
        end if;
    end process;
end struct;
