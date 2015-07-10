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
        wdata : in std_logic_vector (63 downto 0);
        ready : out std_logic;
        valid : out std_logic;
        busy : out std_logic;
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
    signal dq_z : std_logic := '0';
    signal hoge : std_logic_vector (63 downto 0) := x"0123456789abcdef";
    signal counter2 : std_logic_vector (3 downto 0) := "0000";
    signal dqs_counter : std_logic_vector (15 downto 0) := x"0000";
    signal doutb : std_logic_vector (63 downto 0);
--    signal dqsf : std_logic_vector (7 downto 0) := (others => '0');
--    signal dqsf2 : std_logic_vector (7 downto 0) := (others => '0');
--    signal v : std_logic_vector (7 downto 0) := (others => '0');
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

    DQ <= hoge when dq_z = '0' else (others => 'Z');

    dout <= doutb;
    process (clkh)
    begin
        if rising_edge(clkh) then
--            dqsf2 <= dqsf;
--            if read_go = '1' then
--                if dqsf(0) /= dqsf2(0) then
--                    doutb(7 downto 0) <= DQ(7 downto 0);
--                    v(0) <= '1';
--                end if;
--                if dqsf(1) /= dqsf2(1) then
--                    doutb(15 downto 8) <= DQ(15 downto 8);
--                    v(1) <= '1';
--                end if;
--                if dqsf(2) /= dqsf2(2) then
--                    doutb(23 downto 16) <= DQ(23 downto 16);
--                    v(2) <= '1';
--                end if;
--                if dqsf(3) /= dqsf2(3) then
--                    doutb(31 downto 24) <= DQ(31 downto 24);
--                    v(3) <= '1';
--                end if;
--                if dqsf(4) /= dqsf2(4) then
--                    doutb(39 downto 32) <= DQ(39 downto 32);
--                    v(4) <= '1';
--                end if;
--                if dqsf(5) /= dqsf2(5) then
--                    doutb(47 downto 40) <= DQ(47 downto 40);
--                    v(5) <= '1';
--                end if;
--                if dqsf(6) /= dqsf2(6) then
--                    doutb(55 downto 48) <= DQ(55 downto 48);
--                    v(6) <= '1';
--                end if;
--                if dqsf(7) /= dqsf2(7) then
--                    doutb(63 downto 56) <= DQ(63 downto 56);
--                    v(7) <= '1';
--                end if;
--                if v = "11111111" then
--                    valid <= '1';
--                else
--                    valid <= '0';
--                end if;
--            end if;

--            doutb <= DQ;
--            doutb (7 downto 0) <= DQ (7 downto 0);
--            doutb (15 downto 8) <= doutb (7 downto 0);
--            doutb (23 downto 16) <= doutb (15 downto 8);
--            doutb (31 downto 24) <= doutb (23 downto 16);
--            doutb (63 downto 16) <= (others => '0');
            doutb (63 downto 8) <= DQ (63 downto 8);
            doutb (7 downto 0) <= dqs_counter (7 downto 0);
        end if;
    end process;

    process (clk)
    begin
        if falling_edge(clk) then
            if write_go = '1' then
                dqs_go <= '1';
            else
                dqs_go <= '0';
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if write_go = '1' then
                dqs_zero <= '1';
            else
                dqs_zero <= '0';
            end if;
        end if;
    end process;

--    process (clk)
--    begin
--        if rising_edge(clk) then
--            if read_go = '1' then
--                valid <= '1';
--            else
--                valid <= '0';
--            end if;
--        end if;
--    end process;

    process (DQS(0))
    begin
        if falling_edge(DQS(0)) then
            if read_go = '1' then
                dqs_counter <= std_logic_vector(unsigned(dqs_counter) + 1);
            end if;
        end if;
    end process;

--    process (DQS(0))
--    begin
--        if rising_edge(DQS(0)) then
--            dqsf(0) <= not dqsf(0);
--        end if;
--    end process;
--
--    process (DQS(1))
--    begin
--        if rising_edge(DQS(1)) then
--            dqsf(1) <= not dqsf(1);
--        end if;
--    end process;
--
--    process (DQS(2))
--    begin
--        if rising_edge(DQS(2)) then
--            dqsf(2) <= not dqsf(2);
--        end if;
--    end process;
--
--    process (DQS(3))
--    begin
--        if rising_edge(DQS(3)) then
--            dqsf(3) <= not dqsf(3);
--        end if;
--    end process;
--
--    process (DQS(4))
--    begin
--        if rising_edge(DQS(4)) then
--            dqsf(4) <= not dqsf(4);
--        end if;
--    end process;
--
--    process (DQS(5))
--    begin
--        if rising_edge(DQS(5)) then
--            dqsf(5) <= not dqsf(5);
--        end if;
--    end process;
--
--    process (DQS(6))
--    begin
--        if rising_edge(DQS(6)) then
--            dqsf(6) <= not dqsf(6);
--        end if;
--    end process;
--
--    process (DQS(7))
--    begin
--        if rising_edge(DQS(7)) then
--            dqsf(7) <= not dqsf(7);
--        end if;
--    end process;

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
--                        dram_ready <= '1';
--                        busy <= '0';
                        command <= ACT;
                        BA <= "000";
                        A <= (others => '0');
                        counter <= x"0010";
                        dram_init_waiting <= '1';
                    when "01110" =>
                        command <= WRITE;
                        BA <= "000";
                        hoge <= x"0f0f0f0f0f0f0f0f";
                        A <= "00000000000010";
                        counter <= x"0001"; -- CAS latency - 1?
                        dram_init_waiting <= '1';
                    when "01111" =>
                        command <= NOP;
                        write_go <= '1';
                        counter <= x"0003";
                        dram_init_waiting <= '1';
                    when "10000" =>
                        command <= NOP;
                        write_go <= '0';
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "10001" =>
                        command <= WRITE;
                        hoge <= x"deadbeefcafecafe";
                        A <= "00000000000000";
                        counter <= x"0001"; -- CAS latency - 1?
                        dram_init_waiting <= '1';
                    when "10010" =>
                        command <= NOP;
                        write_go <= '1';
                        counter <= x"0003";
                        dram_init_waiting <= '1';
                    when "10011" =>
                        command <= NOP;
                        write_go <= '0';
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "10100" =>
                        command <= WRITE;
                        hoge <= x"4242424242424242";
                        A <= "00000000000100";
                        counter <= x"0001"; -- CAS latency - 1?
                        dram_init_waiting <= '1';
                    when "10101" =>
                        command <= NOP;
                        write_go <= '1';
                        counter <= x"0003";
                        dram_init_waiting <= '1';
                    when "10110" =>
                        command <= NOP;
                        write_go <= '0';
                        counter <= x"0000";
                        dram_init_waiting <= '1';
                    when "10111" =>
                        hoge <= (others => '0');
                        counter <= x"000f";
                        dram_init_waiting <= '1';
                    when "11000" =>
                        dq_z <= '1';
                        command <= READ; -- try changing this to NOP
                        A <= "00000000000100";
                        counter <= x"00ff"; -- CAS latency?
                        dram_init_waiting <= '1';
                        read_go <= '1';
                    when "11001" =>
                        valid <= '1';
                        command <= NOP;
                        st <= "11001";
                    when others => -- ??
                        command <= NOP;
                        st <= "00000";
                end case;
            end if;

--            if dram_ready = '1' then
--                if unsigned(rw_counter) < x"30" then
--                    rw_counter <= std_logic_vector(unsigned(rw_counter) + 1);
--                end if;
--                case rw_counter is
--                    when x"00" =>
--                        command <= ACT;
--                        BA <= "000";
--                        A <= (others => '0');
--                    when x"10" =>
--                        command <= WRITE;
--                        BA <= "000";
--                        A <= (others => '0');
--                    when x"13" =>
--                        write_go <= '1';
--                    when x"16" =>
--                        write_go <= '0';
--                        dq_z <= '1';
--                    when x"20" =>
--                        command <= READ;
--                        BA <= "000";
--                        A <= "00000000000000";
--                    when others =>
--                        command <= NOP;
--                end case;
--            end if;
        end if;
    end process;
end struct;
