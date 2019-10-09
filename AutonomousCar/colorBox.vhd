library ieee;	   
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity colorBox is
 	port(
	clk50,
	accept 	 : in   std_logic := '0';
	input    : in   std_logic_vector(7 downto 0);
	output 	 : out  std_logic_vector(7 downto 0));
end colorBox;

architecture structural of colorBox is

component fp_to_binary is
	port(
	inputFP : in  std_logic_vector(31 downto 0);
	output  : out std_logic_vector(7 downto 0)
	); 
end component;


component binary_to_fp is   
	port(
		inputInteger     : in  std_logic_vector(15 downto 0) := (others => '0');
		output           : out std_logic_vector(31 downto 0) := (others => '0')
		);
end component;

component fp_multiplication is
	port(
	multiplicand : in  std_logic_vector(31 downto 0);
	product      : out std_logic_vector(31 downto 0)
	);
end component;

component fp_division is
	port(  
	clk50,
	reset,
	start                  : in  std_logic := '0';
	divisor, dividend    : in  std_logic_vector(31 downto 0) := (others => '0');
	quotient               : out std_logic_vector(31 downto 0) := (others => '0');
	finished               : out std_logic := '0'
	);
end component;

type arithematicStates is (Idle, Read_Data, Combine, Divide, Multiply, Result);

signal state, next_state : arithematicStates;
type inputArray is array(4 downto 1) of std_logic_vector(7 downto 0);
signal inputNumber     : inputArray := (others => (others => '0'));	 

signal number0,
       number1    		 : std_logic_vector(15 downto 0) := x"0000";
	   
	   
signal fppClear,
	   fppColor				: std_logic_vector(31 downto 0) := (others => '0');

type reg is array (1 downto 0) of std_logic;
signal ffAccept,
       ffAllow	  	  : reg := (others => '0');
signal allow,
	   start 	  	  : std_logic := '0';

signal results,
	   multiplicand   : std_logic_vector(31 downto 0) := (others => '0');
signal reset	 	  : std_logic := '0';

signal finished,
newInput   : std_logic := '0'; 

signal numberFP : std_logic_vector(31 downto 0) := x"00000000";	
signal i, iReg  : natural range 0 to 4;
signal decimal : std_logic_vector(7 downto 0);

begin
	
	 
	process(all)
	begin
	 
			if(reset = '1') then state <= Idle;
								      iReg <= 0;
		elsif(rising_edge(clk50)) then state <= next_state;
											    iReg <= i;
		end if;
		
	
	end process;
	
	
	process(all)
	begin
	--Default Values--
	i <= 0;
	start <= '0';
		case (state) is
			when Idle => 
			
							i <= iReg;
							if(newInput = '1') then next_state <= Read_Data;
							else 						   next_state <= Idle;
							end if;
	
			when Read_Data => 
			
							i <= iReg + 1;
							if(i = 4) then next_state <= Combine;
							else           next_state <= Idle;
							end if;
							
		    when Combine =>
							
							next_state <= Divide;
			
			when Divide => 
							start <= '1';
							
							if(finished = '1') then next_state <= Multiply;
							else                 next_state <= Divide;
							end if;
							
			when Multiply =>
		
						next_state <= Result;
						
			when Result =>
			
						if(accept = '1') then next_state <= Result;
						else                  next_state <= Idle;
						end if;
		end case;
	end process;
	
	
	
	--Rising Edge Detection---
	allow <= '1' when ffAllow(0) = '1' and ffAllow(1) = '0' else '0';
													   
	newInput <= '1' when ffAccept(0) = '1' and ffAccept(1) = '0' else '0';
	--------------------------	
	
	process(all)
	begin
		if(falling_edge(clk50)) then	
			if(state = Read_Data) then inputNumber(i) <= input;
			end if;
		end if;
	end process;	
	
	---------------------------
	process(all)
	begin
	--Reading Edges------
		if(falling_edge(clk50))then
		 	ffAllow(0) <= finished;
		  	ffAllow(1) <= ffAllow(0);
		end if;
		
		if(rising_edge(clk50)) then	   
			if(allow = '1') then multiplicand <= results;
			end if;
		end if;	 
		
		if(falling_edge(clk50)) then
			ffAccept(0) <= accept;
			ffAccept(1) <= ffAccept(0);
		end if;
	-------------------------------	
	end process;
	
	--Combining 8bit inputs into 16 bit words--
	   number0 <= inputNumber(2) & inputNumber(1);
	   number1 <= inputNumber(4) & inputNumber(3);	
	 ------------------------------------------ 
	 
		--Binary_to_fp----- 
	   b2f0 : binary_to_fp 		 port map(number0, fppClear);
	   b2f1 : binary_to_fp		 port map(number1, fppColor);
		-------------------
		
	   div  : fp_division  		 port map(clk50, reset, start, fppClear, fppColor, results, finished);
	   mult : fp_multiplication  port map(multiplicand, numberFP);
	   fp2b : fp_to_binary 		 port map(numberFP, output); 
	   
	   
	   
	   
end structural;