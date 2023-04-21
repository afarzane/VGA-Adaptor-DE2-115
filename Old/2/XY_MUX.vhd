LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY WORK;
USE WORK.ALL;

ENTITY XY_MUX IS
	
	PORT(
		
		en : IN std_logic;
		
		colour_sig : IN std_logic_vector(2 downto 0);
		
		X_CLEAR : IN unsigned(7 downto 0);
		Y_CLEAR : IN unsigned(6 downto 0);
		
		X_LINE : IN unsigned(7 downto 0);
		Y_LINE : IN unsigned(6 downto 0);
		
		
		colour_out : OUT std_logic_vector(2 downto 0);
		X_OUT : OUT std_logic_vector(7 downto 0);
		Y_OUT : OUT std_logic_vector(6 downto 0)
		
	);
	
END ENTITY;


ARCHITECTURE bhv OF XY_MUX IS
	
	

BEGIN
	
	PROCESS(en, X_LINE, Y_LINE, X_CLEAR, Y_CLEAR, colour_sig)
		
	BEGIN
	
		if(en = '0')then
			X_OUT <= std_logic_vector(X_LINE);
			Y_OUT <= std_logic_vector(Y_LINE);
			colour_out <= colour_sig;
		else
			X_OUT <= std_logic_vector(X_CLEAR);
			Y_OUT <= std_logic_vector(Y_CLEAR);
			colour_out <= "000";
		end if;
		
	END PROCESS;
		
		
END ARCHITECTURE;