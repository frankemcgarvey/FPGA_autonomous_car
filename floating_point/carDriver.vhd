library ieee;	  
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


entity carDriver is	
	generic(
	switchingFreq    : natural := 100_000;
	clkFreq          : natural := 50_000_000
	);
	port(
	clk50         : in   std_logic := '0';
	input0,
	input1 	     : in   std_logic_vector(7 downto 0) := (others => '0');      
	direction     : out  std_logic_vector(7 downto 0) := (others => '0');   
	pmw           : out  std_logic_vector(3 downto 0) := (others => '0')
	);
end carDriver;

architecture dataflow of carDriver is 

constant busFreq : natural := clkFreq/(switchingFreq);
type directions is(Forward, Backward);

signal bias : directions;	

signal reset : std_logic := '0';
signal CD    : std_logic := '0';
signal changeDirection : std_logic  := '0';
signal width0, width1 : natural range 0 to busFreq;

signal waiting, allow : std_logic := '0';

constant forwards  : std_logic_vector(7 downto 0) := x"55";  

begin	
								
	direction <= forwards;
	
	width0 <= 0 when unsigned(input0) > 114 else
				 300;
				 
	width1 <= 0 when unsigned(input1) > 114 else
				 300;
	
	process(all) 
	variable counter0,
				counter1     : natural range 0 to busFreq;
	begin		
		
		
		if(rising_edge(clk50)) then	
									if(reset = '1') then counter0 := 0;
																counter1 := 0;
									else				 
										counter0 := counter0 + 1;	  
										counter1 := counter1 + 1; 
										if(counter0 = busFreq) then counter0 := 0;
										end if;
										if(counter1 = busFreq) then counter1 := 0;
										end if;	   
										
									end if;
		end if;
		
		if(counter0 < width0) then pmw(1 downto 0) <= "11";
		else                       pmw(1 downto 0) <= "00";
		end if;
		
		if(counter1 < width1) then pmw(3 downto 2) <= "11";
		else                       pmw(3 downto 2) <= "00";
		end if;
	
	end process;
								
end dataflow;