library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;

entity clear_screen is
	port (
		clk : IN std_logic;
		resetb : IN std_logic;
		en : IN std_logic;
		
		x_counter : OUT unsigned(7 downto 0);
		y_counter : OUT unsigned(6 downto 0);
		colour : OUT unsigned(2 downto 0);
		
		cleared : OUT std_logic
	);
 
end entity;

architecture bhv of clear_screen is
	
	signal current_state, next_state : std_logic_vector (2 downto 0);
	signal PLOT, INITX, INITY, LOADY, LOADX, XDONE, YDONE : std_logic := '0';

begin


  process(clk, resetb, en)
  
		variable Y : unsigned (6 downto 0);
		variable X : unsigned (7 downto 0);
  begin
		
		if(resetb = '0') then
		
			Y := "00000000";
			X := "0000000";
			
	
		if (rising_edge(clk) and en = '1') then
			  
			if (INITY = '1') then
			  Y := "0000000";
			elsif (LOADY = '1') then
			  Y := Y + 1;
			end if;
			if (INITX = '1') then
			  X := "00000000";
			elsif (LOADX = '1') then
			  X := X + 1;
			end if;
			YDONE <= '0';
			XDONE <= '0';
			if (to_integer(Y) > 119) then
			  YDONE <= '1';
			end if;
			if (to_integer(X) = 159) then
			  XDONE <= '1';
			end if;
			x_counter <= Y;
			y_counter <= X;
			
     end if;

  end process;

  NEXTE_LOGIC : process (current_state, XDONE)
	BEGIN
  -- 
		CASE current_state IS
			WHEN "000" =>
      -- INITIALIZING STATE
			  INITX <= '1';
			  INITY <= '1';
			  LOADY <= '1';
			  PLOT <= '0';
			  colour <= "000";
			  next_state <= "010";

			WHEN "001" =>
      -- STOP PLOTTING, RESET X to 0, INCREMENT Y by 1
				INITX <= '1';
				INITY <= '0';
				LOADY <= '1';
        -- LOADX <= '0';
				PLOT <= '0';
        
				next_state <= "010";
			WHEN "010" =>

				INITX <= '0';
				INITY <= '0';
				LOADY <= '0';
				LOADX <= '1';
				PLOT <= '1';
				
				if (XDONE = '0') then
					next_state <= "010";
				elsif (YDONE = '0' and XDONE = '1') then
					next_state <= "001";
				elsif (YDONE = '1') then
					next_state <= "101";
				end if;
				
			WHEN "101" =>
      -- DONE. STOP PLOTTING
				PLOT <= '0';
				INITX <= '0';
				INITY <= '0';
				LOADY <= '0';
				LOADX <= '0';
			WHEN others =>
			  next_state <= "000";
		END CASE;
  END PROCESS;

  PROCESS (clk, resetb, en)
	BEGIN
		IF (resetb = '0') THEN
			current_state <= "000";
		ELSIF (falling_edge(clk) and en = '1') THEN
			current_state <= next_state;
		END IF;
	END PROCESS;

end architecture;