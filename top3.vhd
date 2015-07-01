library ieee;
library unisim;
use unisim.vcomponents.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP is
    generic (
        wtime : std_logic_vector (15 downto 0) := x"1ADB"
    );
    port (
        MCLK1 : in std_logic;
        RS_RX : in std_logic;
        RS_TX : out std_logic;
        ZD     : inout std_logic_vector (31 downto 0);
        ZA     : out   std_logic_vector (19 downto 0);
        XWA    : out   std_logic;
        XE1    : out   std_logic;
        E2A    : out   std_logic;
        XE3    : out   std_logic;
        XGA    : out   std_logic;
        XZCKE  : out   std_logic;
        ADVA   : out   std_logic;
        XLBO   : out   std_logic;
        ZZA    : out   std_logic;
        XFT    : out   std_logic;
        XZBE   : out   std_logic_vector (3 downto 0);
        ZCLKMA : out   std_logic_vector (1 downto 0)
    );
end TOP;

architecture behaviour of TOP is
    signal ZD2 : std_logic_vector (31 downto 0);
    signal ZD3 : std_logic_vector (31 downto 0);
    signal RA : std_logic_vector (3 downto 0);
    signal RA2 : std_logic_vector (3 downto 0);
    signal RA3 : std_logic_vector (3 downto 0);
    signal LD : std_logic;
    signal LD2 : std_logic;
    signal LD3 : std_logic;
    signal clk : std_logic;
    signal iclk : std_logic;
    signal sender_go : std_logic := '0';
    signal sender_busy : std_logic;
    signal sender_data : std_logic_vector (31 downto 0);
    signal reader_valid : std_logic;
    signal reader_data : std_logic_vector (7 downto 0);
    signal reader_data32 : std_logic_vector (31 downto 0);
    signal reader_data32_valid : std_logic := '0';
    signal reader_data32_valid2 : std_logic := '0';
    type regs is array (15 downto 0) of std_logic_vector (31 downto 0);
    signal registers : regs := (others => (others => '1'));
    component SENDER32 is
        generic (
            wtime : std_logic_vector (15 downto 0)
        );
        port (
            clk : in std_logic;
            go : in std_logic;
            data : in std_logic_vector (31 downto 0);
            busy : out std_logic;
            RS_TX : out std_logic
        );
    end component;
    component READER is
        generic (
            wtime : std_logic_vector (15 downto 0)
        );
        port (
            clk : in std_logic;
            RS_RX : in std_logic;
            v : out std_logic;
            data : out std_logic_vector (7 downto 0)
        );
    end component;
    component BUFF32 is
        port (
            din : in std_logic_vector (7 downto 0);
            vin : in std_logic;
            dout : out std_logic_vector (31 downto 0);
            vout : out std_logic
        );
    end component;
begin
    ib : IBUFG port map (
        i => MCLK1,
        o => iclk
    );
    bg : BUFG port map (
        i => iclk,
        o => clk
    );

-- sram setting
    XE1 <= '0';
    E2A <= '1';
    XE3 <= '0';
    XGA <= '0';
    XZCKE <= '0';
    ADVA <= '0';
    XLBO <= '1';
    ZZA <= '0';
    XFT <= '1';
    XZBE <= "0000";
    ZCLKMA (0) <= clk;
    ZCLKMA (1) <= clk;

    sender1 : SENDER32 generic map (wtime) port map (
        clk => clk,
        go => sender_go,
        data => sender_data,
        busy => sender_busy,
        RS_TX => RS_TX
    );

    reader1 : READER generic map (wtime) port map (
        clk => clk,
        RS_RX => RS_RX,
        v => reader_valid,
        data => reader_data
    );

    buff321 : BUFF32 port map (
        din => reader_data,
        vin => reader_valid,
        dout => reader_data32,
        vout => reader_data32_valid
    );

    decode_and_exec : process (clk)
        variable buff : std_logic_vector (31 downto 0);
        variable inst : std_logic_vector (31 downto 0);
    begin
        if rising_edge(clk) then
            reader_data32_valid2 <= reader_data32_valid;
            -- These memory access operations are potentially hazardous
            -- but runs fine without any nops because operations are input
            -- as slow as rs232c's baud rate.
            ZD <= ZD2; ZD2 <= ZD3; -- ZD pipelining
            RA3 <= RA2; RA2 <= RA;
            LD3 <= LD2; LD2 <= LD;
            registers(0) <= (others => '0'); -- must be zero
            if LD3 = '1' then -- load (2 clocks before) FIXME: hazardous
                ZD <= (others => 'Z');
                registers(to_integer(unsigned(RA3))) <= ZD;
            end if;
            if (reader_data32_valid ='1' and reader_data32_valid2 = '0') then
                inst := reader_data32;
                case inst (31 downto 24) is
                    -- "00000000" => nop
                    when "00001000" => -- add
                        registers(to_integer(unsigned(inst (23 downto 20)))) <=
                            std_logic_vector(
                                signed(registers(to_integer(unsigned(inst (19 downto 16))))) +
                                signed(registers(to_integer(unsigned(inst (15 downto 12))))));
                        LD <= '0';
                        XWA <= '1';
                        sender_go <= '0';
                    when "00001001" => -- addi
                        registers(to_integer(unsigned(inst (23 downto 20)))) <=
                            std_logic_vector(
                                signed(registers(to_integer(unsigned(inst (19 downto 16))))) +
                                signed(inst (15 downto 0)));
                        LD <= '0';
                        XWA <= '1';
                        sender_go <= '0';
                    when "00001011" => -- addui
                        registers(to_integer(unsigned(inst (23 downto 20)))) <=
                            std_logic_vector(
                                unsigned(registers(to_integer(unsigned(inst (19 downto 16))))) +
                                unsigned(inst (15 downto 0)));
                        LD <= '0';
                        XWA <= '1';
                        sender_go <= '0';
                    when "00010000" => -- sub
                        registers(to_integer(unsigned(inst (23 downto 20)))) <=
                            std_logic_vector(
                                signed(registers(to_integer(unsigned(inst (19 downto 16))))) -
                                signed(registers(to_integer(unsigned(inst (15 downto 12))))));
                        LD <= '0';
                        XWA <= '1';
                        sender_go <= '0';
                    when "00010001" => -- subi
                        registers(to_integer(unsigned(inst (23 downto 20)))) <=
                            std_logic_vector(
                                signed(registers(to_integer(unsigned(inst (19 downto 16))))) -
                                signed(inst (15 downto 0)));
                        LD <= '0';
                        XWA <= '1';
                        sender_go <= '0';
                    when "00011000" => -- shift left logically
                        buff := registers(to_integer(unsigned(inst (19 downto 16))));
                        if inst(0) = '1' then
                            buff := buff (30 downto 0) & '0';
                        end if;
                        if inst(1) = '1' then
                            buff := buff (29 downto 0) & "00";
                        end if;
                        if inst(2) = '1' then
                            buff := buff (27 downto 0) & x"0";
                        end if;
                        if inst(3) = '1' then
                            buff := buff (23 downto 0) & x"00";
                        end if;
                        if inst(4) = '1' then
                            buff := buff (15 downto 0) & x"0000";
                        end if;
                        if unsigned(inst(15 downto 5)) > 0 then
                            buff := (others => '0');
                        end if;
                        registers(to_integer(unsigned(inst (23 downto 20)))) <= buff;
                    when "00100000" => -- store
                        ZD3 <= registers(to_integer(unsigned(inst (23 downto 20))));
                        ZA <= inst (19 downto 0);
                        LD <= '0';
                        XWA <= '0';
                        sender_go <= '0';
                    when "00101000" => -- load
                        ZA <= inst (19 downto 0);
                        RA <= inst (23 downto 20);
                        LD <= '1';
                        XWA <= '1';
                        sender_go <= '0';
                    when "00110000" => -- send
                        sender_data <= registers(to_integer(unsigned(inst (23 downto 20))));
                        LD <= '0';
                        XWA <= '1';
                        sender_go <= '1';
                    when others => -- nop
                        LD <= '0';
                        XWA <= '1';
                        sender_go <= '0';
                end case;
            else
                XWA <= '1';
                sender_go <= '0';
            end if;
        end if;
    end process;
end behaviour;
