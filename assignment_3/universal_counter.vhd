library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity universal_counter is
  port(
    downup :in std_logic;
    reset  :in std_logic;
    enable :in std_logic;
    load   :in std_logic;
    data   :in std_logic_vector(3 downto 0);
    clock  :in std_logic;

    over  :out std_logic;
    count :out std_logic_vector(3 downto 0)
  );
end universal_counter;

architecture single_process of universal_counter is
begin
  counting: process(clock)
    variable counter_state: std_logic_vector(3 downto 0);
    variable overflow_flag: std_logic;
  begin
    if (clock'event and clock = '1') then
      if reset = '1' then
        -- don't care about anything
        -- perform reset on outputs for count and overflow
        if downup = '0' then
          counter_state := "0000";
        else
          counter_state := "1111";
        end if;

        overflow_flag := '0';
      elsif enable = '1' then
        if load = '1' then
          -- load data from input
          -- set overflow to zero
          counter_state := data;
          overflow_flag := '0';
        else
          if downup = '0' then
            -- count up from 0 to 15
            if counter_state = "1111" then
              -- counter hit an overflow
              counter_state := "0000";
              overflow_flag := '1';
            else
              counter_state := std_logic_vector(unsigned(counter_state) + 1);
            end if;
          else
            -- count down from 15 to 0
            if counter_state = "0000" then
              -- counter hit an overflow
              counter_state := "1111";
              overflow_flag := '1';
            else
              counter_state := std_logic_vector(unsigned(counter_state) - 1);
            end if;
          end if;
        end if;
      end if;

      over  <= overflow_flag;
      count <= counter_state;
    end if;
  end process;
end single_process;

architecture two_processes of universal_counter is
  signal operation_mode: std_logic_vector(1 downto 0);
begin
  logic: process(enable, load, downup)
  begin
    if (enable = '0') then
      operation_mode <= "00";
    elsif (enable = '1' and load = '1') then
      operation_mode <= "01";
    elsif (enable = '1' and downup = '1') then
      operation_mode <= "10";
    elsif (enable = '1' and downup = '0') then
      operation_mode <= "11";
    end if;
  end process;

  registers: process(clock, reset)
    variable counter_state: std_logic_vector(3 downto 0);
    variable overflow_flag: std_logic;
  begin
    if reset = '1' then
      if downup = '0' then
        counter_state := "0000";
      else
        counter_state := "1111";
      end if;

      overflow_flag := '0';
    end if;

    if (clock'event and clock = '1') then
      if operation_mode = "11" then
        if counter_state = "1111" then
          counter_state := "0000";
          overflow_flag := '1';
        else
          counter_state := std_logic_vector(unsigned(counter_state) + 1);
        end if;
      elsif operation_mode = "10" then
        if counter_state = "0000" then
          counter_state := "1111";
          overflow_flag := '1';
        else
          counter_state := std_logic_vector(unsigned(counter_state) - 1);
        end if;
      elsif operation_mode = "01" then
        counter_state := data;
        overflow_flag := '0';
      else
        -- do nothing
        -- since enable = 0
      end if;

      over  <= overflow_flag;
      count <= counter_state;
    end if;
  end process;
end two_processes;
