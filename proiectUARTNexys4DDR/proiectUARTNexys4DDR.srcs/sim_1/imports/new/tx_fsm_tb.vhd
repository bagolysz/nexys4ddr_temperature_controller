----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/10/2017 02:43:20 PM
-- Design Name: 
-- Module Name: tx_fsm_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tx_fsm_tb is
end tx_fsm_tb;

architecture Behavioral of tx_fsm_tb is

constant CLK_PERIOD: TIME := 10 ns;

signal Clk: std_logic;
signal TX_data: std_logic_vector(7 downto 0);
signal TX_en: std_logic := '0';
signal Baud_en: std_logic := '0';
signal Rst: std_logic := '0';
signal TX, TX_ready : std_logic;

begin

    DUT: entity WORK.TX_FSM port map
            (Clk => Clk,
             TX_data => TX_data,
             TX_en => TX_en,
             Baud_en => Baud_en,
             Rst => Rst,
             TX => TX,
             TX_ready => TX_ready);
             
    gen_test: process
        variable data : std_logic_vector(7 downto 0) := "10101100";
    begin
        -- reset the FSM
        Rst <= '1';
        wait for CLK_PERIOD;
        Rst <= '0';
        wait for CLK_PERIOD;
        
        -- initialize data which has to be transmitted
        TX_data <= data;
        -- set BAUD_en = '1'
        Baud_en <= '1';
        -- start the transmission with TX_enable
        TX_en <= '1';
        wait for CLK_PERIOD;
        TX_en <= '0';
        
        wait;
    end process;

    gen_clk: process
    begin
        Clk <= '0';
        wait for CLK_PERIOD/2;
        Clk <= '1';
        wait for CLK_PERIOD/2;
    end process;


end Behavioral;
