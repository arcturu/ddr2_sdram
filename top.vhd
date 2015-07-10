library ieee;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP is
    generic (
--        wtime : std_logic_vector (15 downto 0) := x"1ADB" -- 9600
--        wtime : std_logic_vector (15 downto 0) := x"0D7C" -- 19200
--        wtime : std_logic_vector (15 downto 0) := x"06BF" -- 38400
--        wtime : std_logic_vector (15 downto 0) := x"0245" -- 115200 xxx
--        wtime : std_logic_vector (15 downto 0) := x"7018" -- 9600 @ 266MHz
        wtime : std_logic_vector (15 downto 0) := x"0958" -- 115200 @ 266MHz
    );
    port (
        MCLK1 : in std_logic;
        RS_RX : in std_logic;
        RS_TX : out std_logic;

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
end TOP;

architecture behaviour of TOP is
    component CLK4 is
        port (
            CLKIN_IN : in std_logic;
            RST_IN : in std_logic;
            CLKFX_OUT : out std_logic;
            CLKIN_IBUFG_OUT : out std_logic;
            CLK0_OUT : out std_logic;
            LOCKED_OUT : out std_logic
        );
    end component;
    component CLK90 is
        port (
            CLKIN_IN : in std_logic;
            RST_IN : in std_logic;
            CLK90_OUT : out std_logic;
            LOCKED_OUT : out std_logic
        );
    end component;
    component SENDER64 is
        generic (
            wtime : std_logic_vector (15 downto 0)
        );
        port (
            clk : in std_logic;
            go : in std_logic;
            data : in std_logic_vector (63 downto 0);
            busy : out std_logic;
            RS_TX : out std_logic
        );
    end component;
    component DRAM_CONTROLLER is
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
    end component;
--    component READER is
--        generic (
--            wtime : std_logic_vector (15 downto 0)
--        );
--        port (
--            clk : in std_logic;
--            RS_RX : in std_logic;
--            v : out std_logic;
--            data : out std_logic_vector (7 downto 0)
--        );
--    end component;
--    component BUFF32 is
--        port (
--            din : in std_logic_vector (7 downto 0);
--            vin : in std_logic;
--            dout : out std_logic_vector (31 downto 0);
--            vout : out std_logic
--        );
--    end component;
    signal NOP   : std_logic_vector (3 downto 0) := "0000";
    signal WRITE : std_logic_vector (3 downto 0) := "0001";
    signal READ  : std_logic_vector (3 downto 0) := "0010";
    signal ACT   : std_logic_vector (3 downto 0) := "0011";
    signal clk : std_logic;
    signal clkh : std_logic;
    signal sender_go : std_logic := '0';
    signal sender_busy : std_logic;
    signal sender_data : std_logic_vector (63 downto 0);
    signal dram_command : std_logic_vector (3 downto 0) := x"f";
    signal dram_ready : std_logic := '0';
    signal dram_valid : std_logic;
    signal dram_busy : std_logic;
    signal dram_addr : std_logic_vector (13 downto 0);
    signal dram_ba : std_logic_vector (2 downto 0);
    signal dram_in : std_logic_vector (63 downto 0);
    signal send_stop : std_logic := '0';
--    signal reader_data : std_logic_vector (7 downto 0);
--    signal reader_data32 : std_logic_vector (31 downto 0);
--    signal reader_valid : std_logic;
--    signal reader_valid32 : std_logic;
--    signal reader_valid322 : std_logic;
    signal st : std_logic_vector (3 downto 0) := x"0";
    signal dram_out : std_logic_vector (63 downto 0);
begin
    clock_quadruple : CLK4 port map (
        CLKIN_IN => MCLK1,
        RST_IN => '0',
        CLKFX_OUT => clk
    );
    clock_shift : CLK90 port map (
        CLKIN_IN => clk,
        RST_IN => '0',
        CLK90_OUT => clkh
    );

    dram_ctl : DRAM_CONTROLLER port map (
        clk, clkh, dram_addr, dram_ba, dram_command,
        dram_ready, dram_valid, dram_busy, dram_in, dram_out,
        DQ, A, DQS, XDQS, DM, XCS, BA, XRAS, XCAS, XWE, ODT, CKE, CK, XCK
    );

    sender1 : SENDER64 generic map (wtime) port map (
        clk => clk,
        go => sender_go,
        data => sender_data,
        busy => sender_busy,
        RS_TX => RS_TX
    );

    process (clk)
    begin
        if rising_edge(clk) then
--            reader_valid322 <= reader_valid32;
            if dram_valid = '1' and sender_go = '0' and send_stop = '0' then
                sender_go <= '1';
                sender_data <= dram_out;
                send_stop <= '1';
            else
                sender_go <= '0';
            end if;
            if dram_ready = '1' and dram_busy = '0' then
                case st is
                    when x"0" =>
                        dram_command <= ACT;
                        dram_addr <= "00000000000000";
                        dram_ba <= "000";
                        st <= x"1";
                    when x"1" =>
                        dram_command <= WRITE;
                        dram_addr <= "00000000000000";
                        dram_ba <= "000";
                        dram_in <= x"deadcafebeefcafe";
                        st <= x"2";
                    when x"2" =>
                        dram_command <= WRITE;
                        dram_addr <= "00000000000100";
                        dram_ba <= "000";
                        dram_in <= x"0123456789abcdef";
                        st <= x"3";
                    when x"3" =>
                        dram_command <= READ;
                        dram_addr <= "00000000000100";
                        dram_ba <= "000";
                        st <= x"4";
                    when others =>
                        dram_command <= NOP;
                end case;
            else
                dram_command <= NOP;
            end if;

--            if dram_ready = '1' and sender_busy = '0' then
--                if reader_valid32 = '1' and reader_valid322 = '0' then
--                    case reader_data32 (31 downto 28) is
--                        when x"0" => -- write
--                            write_go <= '1';
--                        when x"1" => -- read
--                            read_go <= '1';
--                        when x"2" => -- write -> read
--                            wr_go <= '1';
--                        when x"3" => -- read -> write
--                            rw_go <= '1';
--                        when others =>
--                    end case;
--                end if;
--            end if;
        end if;
    end process;

--    reader1 : READER generic map (wtime) port map (
--        clk => clk,
--        RS_RX => RS_RX,
--        v => reader_valid,
--        data => reader_data
--    );
--    buff1 : BUFF32 port map (
--        din => reader_data,
--        vin => reader_valid,
--        dout => reader_data32,
--        vout => reader_valid32
--    );
        

end behaviour;
