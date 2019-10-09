library ieee;	   
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity blackBox is
	port(
	clk50,
	accept 	 : in   std_logic := '0';
	input    : in   std_logic_vector(7 downto 0);
	output 	 : out  std_logic_vector(7 downto 0));
end blackBox;

architecture structural of blackBox is

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

type inputArray is array(1 downto 0) of std_logic_vector(7 downto 0);
signal inputNumber0,
	   inputNumber1     : inputArray := (others => (others => '0'));	 

signal number0,
       number1    		 : std_logic_vector(15 downto 0) := x"0000";
	   
	   
signal fppClear,
	   fppColor				: std_logic_vector(31 downto 0) := (others => '0');

type reg is array (1 downto 0) of std_logic;
signal ffDiv,
       ffMult	  	  : reg;
signal allow,
	   start 	  	  : std_logic := '0';

signal results,
	   multiplicand   : std_logic_vector(31 downto 0) := (others => '0');
signal reset	 	  : std_logic := '0';

signal finished,
newInput   : std_logic := '0'; 

signal numberFP : std_logic_vector(31 downto 0) := x"00000000";	

signal decimal : std_logic_vector(7 downto 0);
begin
	
	 
	
	allow <= '1' when ffMult(0) = '1' and ffMult(1) = '0' else '0';
													   
	newInput <= '1' when ffDiv(0) = '1' and ffDiv(1) = '0' else '0';
		
	process(all)
	variable counter : natural range 0 to 4;
	begin
	
		if(rising_edge(clk50))then
		 	ffMult(0) <= finished;
		  	ffMult(1) <= ffMult(0);
		end if;
		
		if(falling_edge(clk50)) then	   
			if(allow = '1') then multiplicand <= results;
								 start <= '0';
			end if;
		end if;	 
		
		if(falling_edge(clk50)) then
			ffDiv(0) <= accept;
			ffDiv(1) <= ffDiv(0);
		end if;
		
		if(rising_edge(clk50)) then
			if(newInput = '1') then
				if(counter < 2) then  inputNumber0(counter) <= input;  				   
				else                  inputNumber1(counter - 2) <= input;			  
				end if;	 
				counter := counter + 1;	
			end if;	
			if(counter = 4) then 
								 start <= '1'; 
								 counter := 0; 
			else                 start <= '0'; 
							     counter := counter;
			end if;
		end if;
	end process; 
	
	   number0 <= inputNumber0(1) & inputNumber0(0);
	   number1 <= inputNumber1(1) & inputNumber1(0);	
	   
	   
	   b2f0 : binary_to_fp 		port map(number0, fppClear);
	   b2f1 : binary_to_fp		port map(number1, fppColor);
	   mult : fp_multiplication port map(multiplicand, numberFP);
	   div  : fp_division  		port map(clk50, reset, start, fppClear, fppColor, results, finished);
	   fp2b : fp_to_binary 		port map(numberFP, decimal); 
	   
	   output <= std_logic_vector(unsigned(decimal));
	   
	   
end structural;