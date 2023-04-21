-- TASK 4 WITH LINE ERASE

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

  signal x, xSig : std_logic_vector(7 downto 0) := (others => '0');
  signal y, ySig : std_logic_vector(6 downto 0) := (others => '0');
  signal colour : std_logic_vector(2 downto 0) := "000";
  signal plot   : std_logic := '0';
  
  type STATE is (SETSCREEN, CLEARX, CLEARY, INIT, INCRX, INCRY, DONE, DELAY, ERASE);
  signal current_state : STATE := SETSCREEN;
  signal delayCounter : unsigned(27 downto 0) := (others => '0');
  signal STARTINIT, INITDONE, ERASEDONE, STARTERASE, resetn, INITX, INITY, LOADY, LOADX, XDONE, YDONE, DELAYDONE, STARTDELAY: std_logic := '0';
  signal imon, ymon : integer := 0;
  
  -- For clearing screen
  signal INITX_clear, INITY_clear, LOADY_clear, LOADX_clear, XDONE_clear, YDONE_clear : std_logic := '0';
  signal CLEAR_EN : std_logic := '1';
	signal X_clear, X_line : unsigned(7 downto 0);
	signal Y_clear, y0_line : unsigned(6 downto 0);
	signal colour_sig : std_logic_vector(2 downto 0);
	
begin

  -- includes the vga adapter, which should be in your project 

  vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120") 
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => xSig,
             y         => ySig,
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
--  colour <= "100";
   OUTPUT_MUX : entity work.XY_MUX(bhv)
	PORT MAP(
		en => CLEAR_EN,
		colour_sig => colour_sig,
		X_CLEAR => X_clear,
		Y_CLEAR => Y_clear,
		X_LINE => X_line,
		Y_LINE => y0_line,
		colour_out => colour,
		X_OUT => xSig,
		Y_OUT => ySig
  );
  
  -- Clear Screen process
  process(CLOCK_50) --, current_state, XDONE)
  variable Y_cl : unsigned (6 downto 0);
  variable X_cl : unsigned (7 downto 0);
  begin
    if (rising_edge(CLOCK_50) and (current_state = SETSCREEN or current_state = CLEARX OR current_state = CLEARY)) then

      if (INITY_clear = '1') then
        Y_cl := "0000000";
      elsif (LOADY_clear = '1') then
        Y_cl := Y_cl + 1;
      end if;
      if (INITX_clear = '1') then
        X_cl := "00000000";
      elsif (LOADX_clear = '1') then
        X_cl := X_cl + 1;
      end if;
      YDONE_clear <= '0';
      XDONE_clear <= '0';
      if (to_integer(Y_cl) > 119) then
        YDONE_clear <= '1';
      end if;
      if (to_integer(X_cl) = 159) then
        XDONE_clear <= '1';
      end if;
		
      X_clear <= X_cl;
		Y_clear <= Y_cl;
		
     end if;
	  
  end process;
  
  -- Line creation process
  
  process(CLOCK_50, resetn)
  variable x0, x1 : unsigned (7 downto 0);
  variable y0, y1 : unsigned (6 downto 0);
  variable dx : signed (15 downto 0);
  variable dy : signed (15 downto 0);
  variable sx, sy : std_logic := '1';
  variable e2 : signed(31 downto 0);
  variable err : signed (15 downto 0);
  variable i : integer;
  
  variable Y : unsigned (6 downto 0);
  variable X : unsigned (7 downto 0);
--  variable next_clock : integer;

  begin
	
    if (rising_edge(CLOCK_50) and (current_state /= SETSCREEN or current_state /= CLEARX or current_state /= CLEARY)) then
      if (INITY = '1') then
			i := 1;
			
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
		  
        Y := "0000000";
      elsif (LOADY = '1') then
			if (STARTDELAY /= '1' and STARTERASE /= '1') then -- and INITDONE = '1') then
				i := i + 1;
			end if;
			
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
		 
			DELAYDONE <= '0';
			ERASEDONE <= '0';
			X := X + 1;
      end if;
		
      YDONE <= '0';
      XDONE <= '0';
		
		if ( STARTERASE = '1') then
				Y := Y + 1;
			if (to_integer(X) = 159) then
				ERASEDONE <= '1';
			end if;
		end if;
		
		
      
		
		if (i = 14) then
			YDONE <= '1';
      end if;
		
      if (to_integer(X) = 159) then
			XDONE <= '1';
      end if;
		
		
		if (STARTDELAY = '1') then
			if (delayCounter(26) = '1') then
				DELAYDONE <= '1';
				delayCounter <= (others => '0');
			else
				delayCounter <= delayCounter + 1;
			end if;
		end if;

		
		X_line <= X;
		y0_line <= y0;
		
		if (STARTERASE = '1') then
			colour_sig <= "000";
		else
			colour_sig <= std_logic_vector(to_unsigned(i mod 8, colour'length));
		end if;
		
		
    end if;
	 imon <= i;
	 ymon <= to_integer(Y);
  end process;

  resetn <= not KEY(3);

  OUTPUT_LOGIC: process (CLOCK_50, resetn, XDONE, YDONE, DELAYDONE, ERASEDONE, XDONE_clear, YDONE_clear)
	BEGIN
	
	IF (resetn = '1') THEN
			current_state <= SETSCREEN;
	elsif (rising_edge(CLOCK_50)) then
		
		case current_state is
		
		WHEN SETSCREEN =>
      -- Clear screen
			 CLEAR_EN <= '1';
			 INITX_clear <= '1';
			 INITY_clear <= '1';
			 LOADY_clear <= '1';
			 PLOT <= '0';
			 current_state <= CLEARX;
			 
		WHEN CLEARY =>
      -- STOP PLOTTING, RESET X to 0, INCREMENT Y by 1
			CLEAR_EN <= '1';
			INITX_clear <= '1';
			INITY_clear <= '0';
			LOADY_clear <= '1';
			PLOT <= '0';
        current_state <= CLEARX;
			
		WHEN CLEARX =>
			CLEAR_EN <= '1';
			INITX_clear <= '0';
			INITY_clear <= '0';
			LOADY_clear <= '0';
			LOADX_clear <= '1';
			PLOT <= '1';
			
			if (XDONE_clear = '0') then
					current_state <= CLEARX;
			 elsif (YDONE_clear = '0' and XDONE_clear = '1') then
					current_state <= CLEARY;
			 elsif (YDONE_clear = '1') then
					current_state <= INIT;
			 end if;
				
      when INIT =>
			CLEAR_EN <= '0';
			INITX_clear <= '0';
			INITY_clear <= '0';
			LOADY_clear <= '0';
			LOADX_clear <= '0';
			
			STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '1';
			INITY <= '1';
			LOADY <= '1';
			PLOT <= '1';
		
			current_state <= INCRX;
		
      when INCRY =>
			
			STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '1';
			INITY <= '0';
			LOADY <= '1';
			PLOT <= '0';
			current_state <= INCRX;
			
      when INCRX =>
			
			STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '0';
			INITY <= '0';
			LOADY <= '0';
			LOADX <= '1';
			PLOT <= '1';
			
			if (YDONE = '0' and XDONE = '1') then
				current_state <= DELAY;
			elsif (YDONE = '1') then
				current_state <= DONE;
			else
				current_state <= INCRX;
         end if;
			
      
		when DELAY =>
			
			STARTDELAY <= '1';
			STARTERASE <= '0';
			INITX <= '1';
			INITY <= '0';
			LOADY <= '1';
			LOADX <= '0';
			PLOT <= '1';
			
			if (DELAYDONE = '1') then
					current_state <= ERASE;
				else
					current_state <= DELAY;
				end if;
		
		WHEN ERASE =>
		
			STARTDELAY <= '0';
			STARTERASE <= '1';
			INITX <= '0';
			INITY <= '0';
			LOADY <= '0';
			LOADX <= '1';
			PLOT <= '1';
		
			if (ERASEDONE = '1') then
					current_state <= INCRY;
				else
					current_state <= ERASE;
				end if;
		
      WHEN DONE =>
			PLOT <= '0';
			current_state <= DONE;
			
		end case;
		
	end if;
  END PROCESS;

--  NEXT_LOGIC: process (current_state, resetn, XDONE, YDONE, DELAYDONE, ERASEDONE, XDONE_clear, YDONE_clear)
--  BEGIN
--  
--      case current_state is
--		  when SETSCREEN =>
--			 next_state <= CLEARX;
--			 
--		  when CLEARY =>
--			 next_state <= CLEARX;
--		  
--		  when CLEARX =>
--			 
--			 if (XDONE_clear = '0') then
--					next_state <= CLEARX;
--			 elsif (YDONE_clear = '0' and XDONE_clear = '1') then
--					next_state <= CLEARY;
--			 elsif (YDONE_clear = '1') then
--					next_state <= INIT;
--			 end if;
--			
--        when INIT =>
--		  
--          next_state <= INCRX;
--        
--        when INCRY =>
--
--			next_state <= INCRX;
--	  
--		when INCRX =>
--
--			if (YDONE = '0' and XDONE = '1') then
--				next_state <= DELAY;
--			elsif (YDONE = '1') then
--				next_state <= DONE;
--			else
--				next_state <= INCRX;
--         end if;
--			 
--			WHEN DELAY =>
--				
--				if (DELAYDONE = '1') then
--					next_state <= ERASE;
--				else
--					next_state <= DELAY;
--				end if;
--			
--			WHEN ERASE =>
--			
--				if (ERASEDONE = '1') then
--					next_state <= INCRY;
--				else
--					next_state <= ERASE;
--				end if;
--				
--        WHEN DONE =>
--          next_state <= DONE;
--      end case;
--  END PROCESS;
  
--	PROCESS (CLOCK_50, resetn, current_state)
--	BEGIN
--		IF (resetn = '1') THEN
--			current_state <= SETSCREEN;
--		ELSIF (rising_edge(CLOCK_50)) THEN
--			current_state <= next_state;
--		END IF;
--	END PROCESS;


end RTL;