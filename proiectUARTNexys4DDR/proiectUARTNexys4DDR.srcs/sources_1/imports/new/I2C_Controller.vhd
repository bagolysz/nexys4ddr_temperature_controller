library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity I2C_Controller is
    generic(
        input_frequency: integer := 100_000_000);
    port(
        Slv_Addr: in std_logic_vector(6 downto 0);
        Reg_Addr: in std_logic_vector(7 downto 0);
        Clk: in std_logic;
        Start: in std_logic;
        Rst: in std_logic;
        
        Data: out std_logic_vector(15 downto 0);
        Busy: out std_logic;
        Error: out std_logic;
        
        SDA: inout std_logic;
        SCL: inout std_logic);
end I2C_Controller;

architecture Behavioral of I2C_Controller is
    constant I2C_Frequency: integer := 100_000;
    
    -- signal Rst_Counter: std_logic := '0';
    -- signal End_Counter: std_logic := '1';

    signal Slv_reg: std_logic_vector(6 downto 0);
    signal Reg_reg: std_logic_vector(7 downto 0);
    signal Data_reg: std_logic_vector(15 downto 0);
    
    type control_fsm is (ready, begin_state, init, restart, wait1, data1, wait2, data2, ack_error);
    signal state: control_fsm := ready;
    
    signal I2C_Start: std_logic := '0';
    signal I2C_Data_in: std_logic_vector(7 downto 0);
    signal I2C_Addr: std_logic_vector(6 downto 0);
    signal I2C_RW: std_logic;
    signal I2C_Data_out: std_logic_vector(7 downto 0);
    signal I2C_Finish: std_logic;
    signal I2C_Ack_Error: std_logic;
    signal I2C_Rdy: std_logic;
    signal I2C_Request: std_logic;
begin

I2C:entity WORK.I2C_Master generic map (
       input_frequency => input_frequency,
       output_frequency => I2C_Frequency)
    port map(
       Data_in => I2C_Data_in,
       Addr => I2C_Addr,
       RW => I2C_RW,
       Start => I2C_Start,
       Clk => Clk, 
       Rst => Rst, 
       
       Data_out => I2C_Data_out,
       Finish => I2C_Finish,
       Request => I2C_Request,
       Rdy => I2C_Rdy,
       Ack_Error => I2C_Ack_Error,
       
       SDA => SDA,
       SCL => SCL);
       
I2C_Data_in <= Reg_reg when (state = init) else x"00";
I2C_Addr <= Slv_reg when (state = init or state = restart or state = data1) else "0000000";
I2C_RW <= '0' when (state = init) else '1';
I2C_Start <= '1' when (state = init or state = restart or state = data1) else '0';

Error <= I2C_Ack_Error;
Busy <= '0' when (state <= ready) else '1';
Data <= Data_reg;

-- timer
--process(Clk, Rst_Counter)
--    constant period: integer := input_frequency / I2C_Frequency;
--    variable counter: integer := period;
--begin
--    if (Rst_Counter = '1') then
--        counter := 0;
--        End_Counter <= '0';
--        Rst_Counter <= '0';
--    elsif (rising_edge(Clk)) then
--        if (counter < period) then
--            counter := counter + 1;
--        else
--            End_Counter <= '1';
--        end if;
--    end if;
--end process;

-- fsm for controlling I2C_Master
process(Clk, Rst)
begin
    if (Rst = '1') then
        state <= ready;
        Data_reg <= (others => '0');
    elsif (rising_edge(Clk)) then 
        if (I2C_Ack_Error = '1') then
            -- Rst_Counter <= '1';
            state <= ack_error;
        else
            case state is
                when ready =>
                    if (Start = '1') then
                        state <= begin_state;
                        Slv_reg <= Slv_Addr;
                        Reg_reg <= Reg_Addr;
                    end if;
                when begin_state =>
                    if (I2C_Rdy = '1') then
                        -- Rst_Counter <= '1';
                        state <= init;
                    end if;
                when init =>
                    if (I2C_Request = '1') then
                        state <= restart;
                    end if;                       
                when restart =>
                    if (I2C_Request = '0') then
                        state <= wait1;
                    end if;
                when wait1 =>
                    if (I2C_Request = '1') then
                        state <= data1;
                    end if;
                when data1 =>
                    if (I2C_Finish = '1' and I2C_Request = '0') then
                        state <= wait2;
                        -- Rst_Counter <= '1';
                        Data_reg(15 downto 8) <= I2C_Data_out;
                    end if;
                when wait2 =>
                    if (I2C_Request = '1') then
                        state <= data2;
                    end if;
                when data2 =>
                    if (I2C_Finish = '1' and I2C_Request = '0') then
                        state <= ready;
                        -- Rst_Counter <= '1';
                        Data_reg(7 downto 0) <= I2C_Data_out;
                    end if;
                when ack_error =>
--                    if (End_Counter = '1') then
--                        state <= ready;
--                    end if;
                    if (I2C_Rdy = '1') then
                        state <= ready;
                    end if;
                when others =>
                    state <= ready;
            end case;
        end if;
    end if;    
end process;

end Behavioral;
