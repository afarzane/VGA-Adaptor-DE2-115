library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;

entity lab3 is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab3;

architecture rtl of lab3 is

 --Component from the Verilog file: vga_adapter.v

  component vga_adapter
    generic(RESOLUTION : string);
    port (resetn                                       : in  std_logic;
          clock                                        : in  std_logic;
          colour                                       : in  std_logic_vector(2 downto 0);
          x                                            : in  std_logic_vector(7 downto 0);
          y                                            : in  std_logic_vector(6 downto 0);
          plot                                         : in  std_logic;
          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
  end component;

  signal x      : std_logic_vector(7 downto 0);
  signal y      : std_logic_vector(6 downto 0);
  signal colour : std_logic_vector(2 downto 0);
  signal current_state, next_state : std_logic_vector (3 downto 0);
  signal PLOT, INITX, INITY, LOADY, LOADX, XDONE, YDONE, INIT_var, LOAD_var: std_logic := '0';
  signal resetn : std_logic;
 
  signal counterX : unsigned(7 downto 0) := (others => '0');
  signal counterY, y0mon : unsigned(6 downto 0) := (others => '0');
  signal imon : integer;

  
	-- Task 4 counter signals
	signal counter_en : std_logic := '0';
	signal counter_done : std_logic := '0';
	
	-- Clear Screen signals
	signal init_clear : std_logic := '0';
--	signal cleared : std_logic := '0';
  
   -- grey function
  function grey(i : integer) return std_logic_vector is
        variable code : std_logic_vector(2 downto 0);
    begin
        case i is
          when 0 => code := "000";
          when 1 => code := "001";
          when 2 => code := "010";
          when 3 => code := "011";
          when 4 => code := "100";
          when 5 => code := "101";
          when 6 => code := "110";
          when others => code := "111";
        end case;
        return code;
  end function;

begin

  -- includes the vga adapter, which should be in your project
  
  vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120") 
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => x,
             y         => y,
             plot      => plot,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);


  -- rest of your code goes here, as well as possibly additional files
  resetn <= not KEY(3);
  x <= std_logic_vector(counterX);
  y <= std_logic_vector(counterY);
  colour <= grey(0 mod 8) WHEN init_cleared = '1' else grey(imon mod 8);

  -- Counter connections
  delay_counter : entity work.counter_delay(bhv)
		port map(
			clk => CLOCK_50,
			resetb => KEY(3),
			counter_en => counter_en,
			counter_out => counter_done
		);
  
  
  process(CLOCK_50, init_clear)
  variable x0, x1 : unsigned (7 downto 0);
  variable y0, y1 : unsigned (6 downto 0);
  variable dx : signed (15 downto 0);
  variable dy : signed (15 downto 0);
  variable sx, sy : std_logic := '1';
  variable e2 : signed(31 downto 0);
  variable err : signed (15 downto 0);
  variable i, ix : integer;

  variable Y : unsigned (6 downto 0);
  variable X : unsigned (7 downto 0);
  begin
    if (rising_edge(CLOCK_50) and init_clear = '0') then

			if (INITY = '1') then
			  Y := "0000000";
			  i := 0;
			  ix := 1;

			elsif (LOADY = '1') then
			  Y := Y + 1;
			end if;

			if (LOAD_var = '1') then 
			  i := i + 1;
			  x0 := "00000000";
			  x1 := "10011111";
			  y0 := to_unsigned(i*8,y0'length);
			  y1 := to_unsigned(120-(i*8),y0'length);

			  if (x0 < x1) then
				 sx := '1';
				 dx := signed("00000000"&(x1-x0));
			  else
				 sx := '0';
				 dx := signed("00000000"&(x0 - x1));
			  end if;

			  if (y0 < y1) then
				 sy := '1';
				 dy := -signed(resize((y1-y0), dy'length));
			  else
				 sy := '0';
				 dy := -signed(resize((y0-y1), dy'length));
			  end if;
			  err := dx+dy;
			end if;

			if (INITX = '1') then
			  X := "00000000";
			elsif (LOADX = '1') then
				 e2 := err*2;
				 if (e2 > dy) then
					err := err + dy;
					if sx = '1' then
					  x0 := x0 + 1;
					else
					  x0 := x0 - 1;
					end if;
				 end if;

				 if (e2 < dx) then
					err := err + dx;
					if sy = '1' then
					  y0 := y0 + 1;
					else
					  y0 := y0 - 1;
					end if;
				 end if;
			  X := X + 1;
			end if;
			YDONE <= '0';
			XDONE <= '0';
			-- delayDone <= '0';
			if (to_integer(Y) = 119) then
			  ix := ix + 1;
			  Y := "0000000";
			end if;
			if (to_integer(X) = 159) then
			  XDONE <= '1';
			end if;

			if (i = 16) then
			  YDONE <= '1';
			end if;


			if current_state = "0101" then
			  counterY <= "0000000";
			  counterX <= "00000000";
			  imon <= 0;
			  y0mon <= "0000000";
			else
			  imon <= i;
			  y0mon <= y0;
			  counterY <= y0;
			  counterX <= X;
			end if;

    end if;
  end process;

 NEXTE_LOGIC : process (current_state, XDONE, delayDone,counter_en)
	BEGIN
 
		CASE current_state IS
			WHEN "0000" =>
			-- INITIALIZING STATE
				counter_en <= '0';
				LOAD_var <= '1';
				INITX <= '1';
				INITY <= '1';
				LOADY <= '1';
				PLOT <= '0';
				next_state <= "0010";

			WHEN "0001" =>
			-- STOP PLOTTING, RESET X to 0, INCREMENT Y by 1
				counter_en <= '0';
				LOAD_var <= '1';

				INITX <= '1';
				INITY <= '0';
				LOADY <= '1';
				PLOT <= '0';
        
				next_state <= "0010";
			WHEN "0010" =>
        -- Set X
				counter_en <= '0';
				LOAD_var <= '0';

				INITX <= '0';
				INITY <= '0';
				LOADY <= '0';
				LOADX <= '1';
				PLOT <= '1';

				next_state <= "0011";
      
			WHEN "0011" =>
			-- Increment X
				if (YDONE = '1') then
					next_state <= "0110";
				
				elsif (YDONE = '0' and XDONE = '1') then
					next_state <= "0100";
				end if;
			
			WHEN "0100" =>
			-- Delay State
				LOADX <= '0';
				LOADY <= '0';
				PLOT <= '0';
				LOAD_var <= '0';
				INITX <= '0';
				INITY <= '0';
				counter_en <= '1';
				if(counter_done = '1')then
					next_state <= "0101";
				else
					next_state <= "0100";
				end if;
			
			WHEN "0101" =>
			-- Clear Screen
				LOADX <= '0';
				LOADY <= '0';
				PLOT <= '0';
				LOAD_var <= '0';
				INITX <= '0';
				INITY <= '0';
				
				init_clear <= '1';
				
		
			WHEN "0110" =>
			-- DONE. CLEAR SCREEN
				LOADX <= '0';
				LOADY <= '0';
				PLOT <= '0';
				LOAD_var <= '0';
				INITX <= '0';
				INITY <= '0';
			when others =>
				next_state <= "0101";
				
			
				
		END CASE;
  END PROCESS;

  PROCESS (CLOCK_50, resetn)
	BEGIN
		IF (resetn = '1') THEN
			current_state <= "0000";
		ELSIF (rising_edge(CLOCK_50)) THEN
			current_state <= next_state;
		END IF;
	END PROCESS;

end rtl;