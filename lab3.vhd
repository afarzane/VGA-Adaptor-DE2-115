-- TASK BONUS: Triangles

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
  
  type STATE is (INIT, INCRX, INCRY, DONE, DELAY, ERASE, VERTICAL);
  signal current_state, next_state : STATE := INIT;
  signal delayCounter : unsigned(27 downto 0) := (others => '0');
  signal STARTINIT, INITDONE, ERASEDONE, STARTERASE, resetn, INITX, INITY, LOADY, LOADX, XDONE, YDONE, DELAYDONE, STARTDELAY, INIT_VERT, VERT_DONE : std_logic := '0';
	signal startX : integer := 0;
--	signal imon, ymon, xmon_var : integer := 0;

  -- singals for triangles
  signal setbtn : std_logic;
  signal base_len : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(40,8));--"01010000";

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
  resetn <= not KEY(3);
  setbtn <= not KEY(0);

  startX <= 80 - to_integer(unsigned(base_len)); -- X value determined by switch
  

  process(setbtn)
  begin
    if (setbtn = '1') then
      base_len <= SW(7 downto 0);
    end if;
  end process;
  
  process(CLOCK_50)
  variable base_pixel : integer;
  variable xmon : integer;


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
	
	variable Y_line : unsigned(6 downto 0);
  begin
    if rising_edge(CLOCK_50) then
      if (INITY = '1') then
			  i := 0;
			  base_pixel := 2;
        xmon := 0;
			
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
		
		  VERT_DONE <= '0';
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
        xmon := 0;
      elsif (LOADX = '1') then

        if (STARTDELAY /= '1' and STARTERASE /= '1') then
          if (base_pixel = 1) then
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
          end if;
        else
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
      end if;
		 
        DELAYDONE <= '0';
        ERASEDONE <= '0';
			
        -- X := X + 1; --** original
        
        if (STARTDELAY /= '1' and STARTERASE /= '1') then -- and INITDONE = '1') then
          if (base_pixel = 1) then
            base_pixel := 2;
            X := X + 1;
            xmon := xmon + 1;
          else
            base_pixel := base_pixel - 1;
          end if;
        else
            xmon := xmon + 1;
            X := X + 1;
        end if;
      end if;
			
      YDONE <= '0';
      XDONE <= '0';
		
		if ( STARTERASE = '1') then
			if (to_integer(X) = (159+1)) then
        Y := Y + 1;
        xmon := 0;
        X := "00000000";
			end if;
			
      if (to_integer(Y) = (119+1)) then
        ERASEDONE <= '1';
        Y := "0000000";
      end if;
      ySig <= std_logic_vector(Y);
    else
      -- ySig <= std_logic_vector(y0); --** original
--      ymon <= to_integer(y0);
      -- testing
      if (base_pixel = 1) then
        -- ymon <= to_integer(to_unsigned(60,Y'length));
        ySig <= std_logic_vector(to_unsigned(60,Y'length));
      else
        -- ymon <= to_integer(y0);
        ySig <= std_logic_vector(y0);
      end if;
		end if;
		
		if (i = (14+1)) then
			YDONE <= '1';
      end if;
		
    if (to_integer(X) = 159) then
      XDONE <= '1';
      -- xmon := 0;
    end if;

    -- if (to_integer(X) = 159) then
    --   XDONE <= '1';
    --   -- xmon := 0;
    -- end if;
		
		
		if (STARTDELAY = '1') then
			if (delayCounter(26) = '1') then
				DELAYDONE <= '1';
				delayCounter <= (others => '0');
			else
				delayCounter <= delayCounter + 1;
			end if;
		end if;

		
		-- xSig <= std_logic_vector(X);
		
		if (STARTERASE = '1') then
			colour <= "000";
		elsif(INIT_VERT ='1') then
			colour <= std_logic_vector(to_unsigned(i mod 8, colour'length));
		elsif (xmon >= 80) or (xmon < startX) then
			colour <= "000";
--			colour <= std_logic_vector(to_unsigned(i mod 8, colour'length));
      else
			
			if(xmon = startX) then
				Y_line := y0;
			end if;
			
			colour <= std_logic_vector(to_unsigned(i mod 8, colour'length));
		end if;
		
		if (INIT_VERT = '1') then
			
			
			ySig <= std_logic_vector(Y_line);
			xSig <= std_logic_vector(to_unsigned(startX,xSig'length));
			
			if (Y_line < 60) then
				Y_line := Y_line + 1;
			elsif(Y_line > 60) then
				Y_line := Y_line - 1;
			elsif(Y_line = 60)then
				VERT_DONE <= '1';
			end if;
		
		else
			
			xSig <= std_logic_vector(to_unsigned(xmon,xSig'length));
		end if;
		
--		imon <= i;
--    xmon_var <= xmon;
	 
    -- startMon <= startX;
    -- ymon <= to_integer(Y);
    end if;
	 
	 
  end process;

  OUTPUT_LOGIC: process (CLOCK_50, current_state)
	BEGIN
  
		case current_state is
			
      when INIT =>
			INIT_VERT <= '0';
			STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '1';
			INITY <= '1';
      LOADX <= '0'; --*
			LOADY <= '1';
			PLOT <= '0';

      when INCRY =>
			INIT_VERT <= '0';
			STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '1';
			INITY <= '0';
      LOADX <= '0'; --*
			LOADY <= '1';
			PLOT <= '0';

      when INCRX =>
			INIT_VERT <= '0';
			STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '0';
			INITY <= '0';
			LOADY <= '0';
			LOADX <= '1';
			PLOT <= '1';
		
		WHEN VERTICAL =>
			STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '0';
			INITY <= '0';
			LOADY <= '0';
			LOADX <= '0';
			INIT_VERT <= '1';
			PLOT <= '1';
      
		when DELAY =>
			INIT_VERT <= '0';
			STARTDELAY <= '1';
			STARTERASE <= '0';
			INITX <= '1';
			INITY <= '0';
			LOADY <= '1';
			LOADX <= '0';
			PLOT <= '0';
		
		WHEN ERASE =>
			INIT_VERT <= '0';
			STARTDELAY <= '0';
			STARTERASE <= '1';
			INITX <= '0';
			INITY <= '0';
			LOADY <= '0';
			LOADX <= '1';
			PLOT <= '1';
		
      WHEN DONE =>
		INIT_VERT <= '0';
      STARTDELAY <= '0';
			STARTERASE <= '0';
			INITX <= '0';
			INITY <= '0';
			LOADY <= '0';
			LOADX <= '0';
			PLOT <= '0';
		end case;
  END PROCESS;

  NEXT_LOGIC: process (current_state, resetn, XDONE, YDONE, DELAYDONE, ERASEDONE, VERT_DONE)
  BEGIN
  
      case current_state is
        when INIT =>
		  
          next_state <= DELAY;
        
        when INCRY =>

			next_state <= INCRX;
	  
		when INCRX =>

			if (YDONE = '0' and XDONE = '1') then
				next_state <= VERTICAL;
			elsif (YDONE = '1') then
				next_state <= DONE;
			else
				next_state <= INCRX;
         end if;
			
			WHEN VERTICAL =>
				if (VERT_DONE = '1') then
					next_state <= DELAY;
				else
					next_state <= VERTICAL;
				end if;
			 
			WHEN DELAY =>
				
				if (DELAYDONE = '1') then
            next_state <= ERASE;
				else
					next_state <= DELAY;
				end if;
			
			WHEN ERASE =>
        
				if (ERASEDONE = '1') then
            next_state <= INCRY;
				else
					next_state <= ERASE;
				end if;
				
        WHEN DONE =>
          next_state <= INIT;
      end case;
  END PROCESS;
  
	PROCESS (CLOCK_50, resetn)
	BEGIN
		IF (resetn = '1') THEN
			current_state <= INIT;
		ELSIF (rising_edge(CLOCK_50)) THEN
			current_state <= next_state;
		END IF;
	END PROCESS;


end rtl;