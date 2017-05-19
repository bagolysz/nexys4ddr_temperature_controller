----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2017 10:55:01 AM
-- Design Name: 
-- Module Name: baud_rate_generator - Behavioral
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

entity baud_rate_generator is
    port (Clk: in std_logic;
          TX_baud_rate: out std_logic;
          RX_baud_rate: out std_logic);
end baud_rate_generator;

architecture Behavioral of baud_rate_generator is

begin
    -- generare semnal de baud rate pentru transmisie
    -- transmitem datele la rata de 9600 => la un clock de 100MHz numaram 10416 tacti
    gen_baud_tx: process(clk)
        variable count: integer range 0 to 10415 :=0;
    begin
        if (rising_edge(clk)) then
            if count = 10415 then
                TX_baud_rate <= '1';
                count := 0;
            else 
                TX_baud_rate <= '0';
                count := count + 1;
            end if;
         end if;
    end process gen_baud_tx;
    
    -- generare semnal de baud rate pentru transmisie
    -- data transmisia se face la 9600 bit/s => receptia trebuie efectuata la rate de 16*9600 => la un clock de 100MHz numaram 651 tacti
    gen_baud_rx: process(clk)
        variable count: integer range 0 to 650 := 0;
    begin
        if rising_edge(clk) then
            if count = 650 then 
                RX_baud_rate <= '1';
                count := 0;
             else 
                RX_baud_rate <= '0';
                count := count + 1;
             end if;
        end if;
    end process gen_baud_rx;

end Behavioral;
