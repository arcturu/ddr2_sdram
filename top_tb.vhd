--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:23:54 06/22/2015
-- Design Name:   
-- Module Name:   /home/sseki/ise/ddr2/top_tb.vhd
-- Project Name:  ddr2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TOP
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY top_tb IS
END top_tb;
 
ARCHITECTURE behavior OF top_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TOP
    PORT(
         MCLK1 : IN  std_logic;
         RS_RX : IN  std_logic;
         RS_TX : OUT  std_logic;
         DQ : INOUT  std_logic_vector(63 downto 0);
         A : OUT  std_logic_vector(13 downto 0);
         DQS : INOUT  std_logic_vector(7 downto 0);
         XDQS : INOUT  std_logic_vector(7 downto 0);
         DM : OUT  std_logic_vector(7 downto 0);
         XCS : OUT  std_logic_vector(1 downto 0);
         BA : OUT  std_logic_vector(2 downto 0);
         XRAS : OUT  std_logic;
         XCAS : OUT  std_logic;
         XWE : OUT  std_logic;
         ODT : OUT  std_logic_vector(1 downto 0);
         CKE : OUT  std_logic_vector(1 downto 0);
         CK : OUT  std_logic_vector(1 downto 0);
         XCK : OUT  std_logic_vector(1 downto 0)
        );
    END COMPONENT;

--    component DDR2_SDRAM is
--        generic (
--            cycle : time
--        );
--        port (
--            DQ : inout std_logic_vector (63 downto 0);
--            A : in std_logic_vector (13 downto 0);
--            DQS : inout std_logic_vector (7 downto 0);
--            XDQS : inout std_logic_vector (7 downto 0);
--            DM : in std_logic_vector (7 downto 0);
--            XCS : in std_logic_vector (1 downto 0);
--            BA : in std_logic_vector (2 downto 0);
--            XRAS : in std_logic;
--            XCAS : in std_logic;
--            XWE : in std_logic;
--            ODT : in std_logic_vector (1 downto 0);
--            CKE : in std_logic_vector (1 downto 0);
--            CK : in std_logic_vector (1 downto 0);
--            XCK : in std_logic_vector (1 downto 0)
--        );
--    END COMPONENT;

    

   --Inputs
   signal MCLK1 : std_logic := '0';
   signal RS_RX : std_logic := '0';

	--BiDirs
   signal DQ : std_logic_vector(63 downto 0);
   signal DQS : std_logic_vector(7 downto 0);
   signal XDQS : std_logic_vector(7 downto 0);

 	--Outputs
   signal RS_TX : std_logic;
   signal A : std_logic_vector(13 downto 0);
   signal DM : std_logic_vector(7 downto 0);
   signal XCS : std_logic_vector(1 downto 0);
   signal BA : std_logic_vector(2 downto 0);
   signal XRAS : std_logic;
   signal XCAS : std_logic;
   signal XWE : std_logic;
   signal ODT : std_logic_vector(1 downto 0);
   signal CKE : std_logic_vector(1 downto 0);
   signal CK : std_logic_vector(1 downto 0);
   signal XCK : std_logic_vector(1 downto 0);
   -- No clocks detected in port list. Replace mclk1 below with 
   -- appropriate port name 
 
   constant mclk1_period : time := 14.52 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TOP PORT MAP (
          MCLK1 => MCLK1,
          RS_RX => RS_RX,
          RS_TX => RS_TX,
          DQ => DQ,
          A => A,
          DQS => DQS,
          XDQS => XDQS,
          DM => DM,
          XCS => XCS,
          BA => BA,
          XRAS => XRAS,
          XCAS => XCAS,
          XWE => XWE,
          ODT => ODT,
          CKE => CKE,
          CK => CK,
          XCK => XCK
        );

--   dram : DDR2_SDRAM GENERIC MAP (
--          cycle => mclk1_period / 4
--   ) PORT MAP (
--          DQ => DQ,
--          A => A,
--          DQS => DQS,
--          XDQS => XDQS,
--          DM => DM,
--          XCS => XCS,
--          BA => BA,
--          XRAS => XRAS,
--          XCAS => XCAS,
--          XWE => XWE,
--          ODT => ODT,
--          CKE => CKE,
--          CK => CK,
--          XCK => XCK
--  );

   -- Clock process definitions
   mclk1_process :process
   begin
		mclk1 <= '0';
		wait for mclk1_period/2;
		mclk1 <= '1';
		wait for mclk1_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for mclk1_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
