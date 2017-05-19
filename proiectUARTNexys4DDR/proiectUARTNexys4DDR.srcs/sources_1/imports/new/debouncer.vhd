----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2017 11:07:04 AM
-- Design Name: 
-- Module Name: debouncer - Behavioral
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

entity debouncer is
    port(Clk: in std_logic;
         Btn_in: in std_logic;
         Btn_out: out std_logic);
end debouncer;

architecture Behavioral of debouncer is

signal Q1, Q2, Q3 : std_logic;

begin

    process(Clk)
    begin
        if rising_edge(clk) then
            Q1 <= Btn_in;
            Q2 <= Q1;
            Q3 <= Q2;            
        end if;
    end process;

    Btn_out <= Q1 and Q2 and (not Q3);

end Behavioral;
