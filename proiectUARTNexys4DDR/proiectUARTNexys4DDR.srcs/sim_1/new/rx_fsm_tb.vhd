----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/08/2017 03:18:14 PM
-- Design Name: 
-- Module Name: rx_fsm_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rx_fsm_tb is
end rx_fsm_tb;

architecture Behavioral of rx_fsm_tb is

constant CLK_PERIOD: TIME := 10 ns;

signal Clk: std_logic;
signal RX_data: std_logic_vector(7 downto 0);
signal Baud_en: std_logic := '0';
signal Rst: std_logic := '0';
signal RX, RX_ready : std_logic;

begin

    DUT: entity WORK.RX_FSM port map
            (Clk => Clk,
             RX_data => RX_data,
             Baud_en => Baud_en,
             Rst => Rst,
             RX => RX,
             RX_ready => RX_ready);
             
    gen_test: process
    begin
        -- reset the FSM
        Rst <= '1';
        wait for CLK_PERIOD;
        Rst <= '0';
        wait for CLK_PERIOD;
        
        -- set BAUD_en = '1'
        Baud_en <= '1';
        RX <= '1';
        wait for CLK_PERIOD;
        
        -- start a new reception
        RX <= '0';
        wait for 8*CLK_PERIOD;
        
        -- receive the transmitted bits;
        RX <= '0';
        wait for 16*CLK_PERIOD;
        RX <= '0';
        wait for 16*CLK_PERIOD;
        RX <= '1';
        wait for 16*CLK_PERIOD;
        RX <= '1';
        wait for 16*CLK_PERIOD;
        RX <= '0';
        wait for 16*CLK_PERIOD;
        RX <= '1';
        wait for 16*CLK_PERIOD;
        RX <= '0';
        wait for 16*CLK_PERIOD;
        RX <= '1';
        wait for 16*CLK_PERIOD;
     
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
