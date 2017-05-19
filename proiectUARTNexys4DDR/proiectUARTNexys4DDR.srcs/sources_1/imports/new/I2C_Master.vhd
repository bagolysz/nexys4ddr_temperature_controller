library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity I2C_Master is
    generic(
        input_frequency: integer := 100_000_000;
        output_frequency: integer := 100_000);
    port(
        Data_in: in std_logic_vector(7 downto 0);
        Addr: in std_logic_vector(6 downto 0);
        RW: in std_logic;
        Start: in std_logic;
        Clk: in std_logic;
        Rst: in std_logic;
        
        Data_out: out std_logic_vector(7 downto 0);
        Finish: out std_logic;
        Request: out std_logic;
        Rdy: out std_logic;
        Ack_Error: out std_logic;
        
        SDA: inout std_logic;
        SCL: inout std_logic);
end I2C_Master;

architecture Behavioral of I2C_Master is
    constant PERIOD: integer := input_frequency / output_frequency;

    signal Data_reg: std_logic_vector(7 downto 0);
    signal Addr_RW_reg: std_logic_vector(7 downto 0);
    signal RW_reg: std_logic;
    
    signal Divided_Clk: std_logic:= '0';
    signal CE_r: std_logic:= '0';
    signal CE_f: std_logic:= '0';    
    
    signal SCL_Sel: integer := 1;    
    signal SDA_Sel: integer:= 1;
    signal Read_Write: std_logic:= '1';
    
--    signal Shift: std_logic := '0';
    signal Shift_reg: std_logic_vector(7 downto 0);    
    
    type fsm_states is (ready, start_bit, command, slv_ack1, rd, wr, slv_ack2, mstr_ack_rd, 
        mstr_ack_restart, mstr_nack, SDA1_SCL0, SDA1_SCL1, stop1, stop2);
    signal state: fsm_states := ready;
    signal Bit_Cnt: integer;
    
    signal Int_Ack_Error: std_logic := '0';
begin

Clock_Gen: process(Clk)
    variable counter: integer := 0;
begin
    if (rising_edge(clk)) then
        counter := counter + 1;
        if (counter < PERIOD / 2) then
            CE_r <= '0';
            CE_f <= '0';
            divided_clk <= '0';
        elsif (counter = PERIOD / 2) then
            CE_r <= '1';
            CE_f <= '0';
            divided_clk <= '1';
        elsif (counter < PERIOD) then
            CE_r <= '0';
            CE_f <= '0';
            divided_clk <= '1';
        elsif (counter = PERIOD) then
            CE_r <= '0';
            CE_f <= '1';
            divided_clk <= '0';
            counter := 0;
        end if;  
   end if;       
end process;

-- Mux SCL_Sel
process(Divided_Clk, SCL_Sel)
begin
    case SCL_Sel is
        when 0 =>
            SCL <= '0';
        when 1 =>
            SCL <= 'Z';
        when others =>
            if (Divided_Clk = '0') then
                SCL <= '0';
            else
                SCL <= 'Z';
            end if;
    end case;
end process;

-- Shift register
--process(Clk)
--begin
--    if (rising_edge(Clk) and CE_f = '1') then
--        if (Shift = '1') then
--            Shift_reg(7 downto 1) <= Shift_reg(6 downto 0);
--            Shift_reg(0) <= SDA;
--        end if;
--    end if;
--end process;

-- SDA_Sel mux
process(Shift_reg(7), SDA_Sel, Read_Write)
begin
    if (Read_Write = '1') then
        SDA <= 'Z';
    else
        case SDA_Sel is
            when 0 =>
                SDA <= '0';
            when 1 =>
                SDA <= 'Z';
            when others =>
                if (Shift_reg(7)) = '0' then
                    SDA <= '0';
                else
                    SDA <= 'Z';
                end if;
        end case;
    end if;
end process;

RW_reg <= Addr_RW_reg(0);

--fsm states switching
process(Clk, Rst)
begin
    if (Rst = '1') then
        state <= ready;
        Int_Ack_Error <= '0';
    elsif (rising_edge(Clk)) then
        case state is
            when ready =>
                if (CE_r = '1') then
                    if (Start = '1') then
                        state <= start_bit;                       
                        Addr_RW_reg <= Addr & RW;
                        Data_reg <= Data_in;
                    end if;
                end if;
            when start_bit =>
                if (CE_f = '1') then
                    Int_Ack_Error <= '0';
                    state <= command;
                    Bit_Cnt <= 7;
                    Shift_reg <= Addr_RW_reg;
                end if;
            when command =>
                if (CE_f = '1') then
                    if (Bit_Cnt = 0) then
                        state <= slv_ack1;
                    end if;
                    Bit_Cnt <= Bit_Cnt - 1;
                    -- shift
                    Shift_reg(7 downto 1) <= Shift_reg(6 downto 0);
                    Shift_reg(0) <= SDA;
                end if;
            when slv_ack1 =>
                if (CE_f = '1') then
                    if (SDA /= '0') then
                        Int_Ack_Error <= '1';
                        state <= stop1;
                    else
                        if (RW_reg = '0') then
                            state <= wr;
                            Shift_reg <= Data_reg;
                        else
                            state <= rd;
                        end if;
                        Bit_Cnt <= 7;
                    end if;
                end if;
            when rd =>
                if (CE_f = '1') then
                    if (Bit_Cnt = 0) then
                        if (Start = '1') then
                            if (RW = '1' and Addr = Addr_RW_reg(7 downto 1)) then
                                state <= mstr_ack_rd;
                            else
                                state <= mstr_ack_restart;
                                Addr_RW_reg <= Addr & RW;
                                Data_reg <= Data_in;
                            end if;
                        else
                            state <= mstr_nack;
                        end if;
                    end if;
                    Bit_Cnt <= Bit_Cnt - 1;
                    -- shift
                    Shift_reg(7 downto 1) <= Shift_reg(6 downto 0);
                    Shift_reg(0) <= SDA;
                end if;
            when wr =>
                if (CE_f = '1') then
                    if (Bit_Cnt = 0) then
                        state <= slv_ack2;
                    end if;
                    Bit_Cnt <= Bit_Cnt - 1;
                    -- shift
                    Shift_reg(7 downto 1) <= Shift_reg(6 downto 0);
                    Shift_reg(0) <= SDA;
                end if;
            when slv_ack2 =>
                if (CE_f = '1') then
                    if (SDA /= '0') then
                        Int_Ack_Error <= '1';
                        state <= stop1;
                    else
                        if (Start = '1') then
                            if (RW = '0' and Addr = Addr_RW_reg(7 downto 1)) then
                                state <= wr;
                                Bit_Cnt <= 7;
                                Data_reg <= Data_in;
                                Shift_reg <= Data_in;
                            else
                                state <= SDA1_SCL0;
                                Addr_RW_reg <= Addr & RW;
                                Data_reg <= Data_in;
                            end if;
                        else
                            state <= stop1;
                        end if;
                    end if;
                end if;
            when mstr_ack_rd =>
                if (CE_f = '1') then
                    state <= rd;
                    Bit_Cnt <= 7;
                end if;
            when mstr_ack_restart =>
                if (CE_f = '1') then
                    state <= SDA1_SCL0;
                end if;
            when mstr_nack =>
                if (CE_f = '1') then
                    state <= stop1;
                end if;
            when SDA1_SCL0 =>
                if (CE_r = '1') then
                    state <= SDA1_SCL1;
                end if;
            when SDA1_SCL1 =>
                if (CE_r = '1') then
                    state <= start_bit;
                end if;
            when stop1 =>
                if (CE_r = '1') then
                    state <= stop2;
                end if;
            when stop2 =>
                if (CE_f = '1') then
                    state <= ready;
                end if;
            when others =>
                state <= ready;
        end case;
    end if;
end process;

Ack_Error <= Int_Ack_Error;
Finish <= '1' when (state = slv_ack2 or state = mstr_ack_rd or state = mstr_ack_restart or state = mstr_nack) else '0';
Request <= '1' when ((state = rd and Bit_Cnt = 0) or state = slv_ack2) else '0';
Data_out <= Shift_reg;
Rdy <= '1' when (state = ready) else '0';

--Shift <= '1' when (state = command or state = rd or state = wr) else '0';
SCL_Sel <= 0 when (state = SDA1_SCL0 or state = stop1) else
           1 when (state = ready or state = start_bit or state = SDA1_SCL1 or state = stop2) else 2;
Read_Write <= '1' when (state = slv_ack1 or state = rd or state = slv_ack2) else '0';
SDA_Sel <= 0 when (state = start_bit or state = mstr_ack_rd or state = stop1 or 
                   state = stop2 or state = mstr_ack_restart) else 
           1 when (state = ready or state = SDA1_SCL0 or state = SDA1_SCL1 or state = mstr_nack) else 2;

end Behavioral;
