----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2017 10:54:41 AM
-- Design Name: 
-- Module Name: main_unit - Behavioral
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

entity main_unit is
    port(Clk: in std_logic;
         rst_in: in std_logic;
         Seg: out std_logic_vector(7 downto 0);
         led_tx_ready: out std_logic;
         led_rx_ready: out std_logic;
         led: out std_logic_vector(9 downto 0);
         busy: out std_logic;
         error: out std_logic;
         An: out std_logic_vector(7 downto 0);
         TX: out std_logic;
         RX: in std_logic;
         SDA: inout std_logic;
         SCL: inout std_logic); 
end main_unit;

architecture Behavioral of main_unit is

signal baud_rate_rx: std_logic := '0';
signal start_transmission, baud_rate_tx, rst, tx_ready, rx_ready, tx_en, rst_ssd : std_logic :='0';
signal start_connection: std_logic := '0';

signal ssd_data: std_logic_vector(31 downto 0);
signal current_temperature: std_logic_vector(15 downto 0) := (others => '0');

signal send_data_buffer: std_logic_vector(15 downto 0);
signal send_data: std_logic_vector(7 downto 0);
signal received_byte: std_logic_vector(7 downto 0);

type FSM_STATE is (idle, byte1, waitByte1, waitBetween, byte2, waitByte2);
signal state : FSM_STATE := idle;

begin
    debounce_reset: entity WORK.debouncer port map(Clk => clk, Btn_in => rst_in, Btn_out => rst);
    
    temp_sensor: entity WORK.I2C_Controller generic map(input_frequency => 100_000_000)
                                            port map (
                            Slv_Addr => "1001011",
                            Reg_Addr => x"00",
                            Clk => clk,
                            Start => start_connection,
                            Rst => Rst,
                            Data => current_temperature,
                            Busy => busy,
                            Error => error,
                            SDA => SDA,
                            SCL => SCL);
    
    baud_rate: entity WORK.baud_rate_generator port map(
                Clk => clk,
                TX_baud_rate => baud_rate_tx,
                RX_baud_rate => baud_rate_rx);
    
    tx_fsm: entity WORK.TX_FSM port map(
            Clk => clk,
            TX_data => send_data,
            TX_en => tx_en,
            Baud_en => baud_rate_tx,
            Rst => rst,
            TX => TX,
            TX_ready => tx_ready);
            
    rx_fsm: entity WORK.RX_FSM port map(
            Clk => clk,
            RX_data => received_byte,
            Baud_en => baud_rate_rx,
            Rst => Rst,
            RX => RX,
            RX_ready => rx_ready);
    
    ssd: entity WORK.displ7seg port map(
            Clk => clk,
            Rst => rst,
            Data => ssd_data,
            Seg => Seg,
            An => An);
    
    led_tx_ready <= tx_ready;
    led_rx_ready <= rx_ready;
    ssd_data <= received_byte&"00000000"&current_temperature;
            
    -- processes to generate start_transmission signal every second to constantly send info to PC every 5 seconds
    process(clk)
        variable count: integer := 0;
    begin
        if rising_edge(clk) then
            if count = 199999999 then
                start_connection <= '1';
                count := 0;
            else
                start_connection <= '0';
                count := count + 1;
            end if;
        end if;
    end process;
    
    -- FSM to transmit 2 separate bytes
            process(clk)
            begin
                if rising_edge(clk) then
                    if rst = '1' then
                        state <= idle;
                    else
                        case (state) is
                            when idle =>
                                if start_connection = '1' then
                                    state <= byte1;
                                end if;
                            when byte1 =>
                                if baud_rate_tx = '1' then
                                    state <= waitByte1;
                                end if;
                            when waitByte1 =>
                                if tx_ready = '1' AND baud_rate_tx = '1' then
                                    state <= waitBetween;
                                end if;
                            when waitBetween =>
                                if baud_rate_tx = '1' then
                                    state <= byte2;
                                end if;
                            when byte2 =>
                                if baud_rate_tx = '1' then
                                    state <= waitByte2;
                                end if;
                            when waitByte2 =>
                                if tx_ready = '1' AND baud_rate_tx = '1' then
                                    state <= idle;
                                end if;
                        end case;
                   end if;
               end if;
            end process;
            
    start_transmission <= '1' when state = byte1 or state = byte2 else '0';
    send_data <= current_temperature(15 downto 8) when state = idle or state = byte1 or state = waitByte1 else 
                 current_temperature(7 downto 0);
    
    process(clk, baud_rate_tx, start_transmission)
    begin
        if rising_edge(clk) then
            if baud_rate_tx = '1' then
                tx_en <= '0';
            elsif start_transmission = '1' then
                tx_en <= '1';
            end if;
        end if;
    end process;
    
    -- process to decide wheter the heater or air conditioner has to be activated based on the received data command
        process(clk)
            variable count: integer := 0;
        begin
            if rising_edge(clk) then
            case received_byte(1 downto 0) is
                when "10" =>
                    -- heating
                    led(9 downto 0) <= "1111111111";
                when "01" =>
                    -- air conditioner
                    if count < 29999999 then
                        count := count + 1;
                        led(9 downto 0) <= "1111111111";
                    elsif count < 59999999 then
                        count := count + 1;
                        led(9 downto 0) <= "0000000000";
                    else
                        count := 0;
                    end if;
               when others =>
                    led(9 downto 0) <= "0000000001";
            end case;
            end if;
            
        end process;
    
end Behavioral;
