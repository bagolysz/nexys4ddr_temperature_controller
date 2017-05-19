----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/01/2017 12:14:28 AM
-- Design Name: 
-- Module Name: rx_fsm - Behavioral
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

entity RX_FSM is
    port(Clk: in std_logic;
         RX_data : out std_logic_vector(7 downto 0);
         Baud_en: in std_logic;
         Rst: in std_logic;
         RX: in std_logic;
         RX_ready: out std_logic);
end RX_FSM;

architecture Behavioral of RX_FSM is

type RX_STATE is (idle, start, data, stop, waiting);
signal state: RX_STATE := idle;
signal bit_cnt: integer := 0;
signal baud_cnt: integer := 0;

begin
    -- descriere tranzitii intre stari
    process (Clk, Rst, Baud_en)
    begin
        if Rst = '1' then
            state <= idle;
        elsif rising_edge(Clk) then
            if Baud_en = '1' then
                case state is
                    when idle =>
                        if RX = '0' then
                            state <= start;
                        else 
                            state <= idle;
                        end if;
                        baud_cnt <= 0;
                        bit_cnt <= 0;
                    when start =>
                        if RX = '1' then 
                            state <= idle;
                        elsif baud_cnt = 7 then
                            state <= data;
                        else
                            state <= start;
                            baud_cnt <= baud_cnt + 1;
                        end if;
                    when data =>
                        if baud_cnt = 15 then
                            if bit_cnt = 8 then
                                state <= stop;
                            else
                                state <= data;
                                RX_data(bit_cnt) <= RX;
                                bit_cnt <= bit_cnt + 1;
                            end if;
                            baud_cnt <= 0;
                        else 
                            state <= data;
                            baud_cnt <= baud_cnt + 1;
                        end if;
                    when stop =>
                        if baud_cnt = 15 then 
                            state <= waiting;
                            baud_cnt <= 0;
                        else 
                            state <= stop;
                            baud_cnt <= baud_cnt + 1;
                        end if;
                    when waiting =>
                        if baud_cnt = 7 then
                            state <= idle;
                            baud_cnt <= 0;
                        else 
                            state <= waiting;
                            baud_cnt <= baud_cnt + 1;
                        end if;
                 end case;
             end if;
        end if;
                     
    end process;
    
    -- descriere valorilor semnalelor de iesire in functie de stare
    RX_ready <= '1' when state = waiting else '0';
    

end Behavioral;
