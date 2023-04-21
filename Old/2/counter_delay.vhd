library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;

entity counter_delay is
	port (
		clk : IN std_logic;
		resetb : IN std_logic;
		counter_en : IN std_logic;
		
		counter_done : OUT std_logic
	);
 
end entity;

architecture bhv of counter_delay is

	

begin


	process(clk, resetb, counter_en)
	
		variable count_value : integer := 1;
	
	begin
	
		if(resetb = '1' or counter_en = '0') then
			count_value := 1;
			counter_done <= '0';
		elsif (rising_edge(clk) and counter_en = '1') then
			
			if(count_value = 3)then
				count_value := 1;
				counter_done <= '1';
			else
				count_value := count_value + 1;
				counter_done <= '0';
			end if;
			
		end if;
		
	end process;


end architecture;