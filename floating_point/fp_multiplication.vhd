library ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;
use work.SPP_package.all;

entity fp_multiplication is
	port(
	multiplicand : in  std_logic_vector(31 downto 0) := x"41c58d50";
	product      : out std_logic_vector(31 downto 0)
	);
end fp_multiplication;


architecture dataflow of fp_multiplication is  


signal exponent		   	 : std_logic_vector(7 downto 0) := x"00";
signal sign     		       : std_logic := '0';
signal significand	       : std_logic_vector(22 downto 0) := (others => '0');	  
signal results              : std_logic_vector(47 downto 0) := (others => '0');	

constant twohundredfiftyfive : unsigned(23 downto 0) := x"FF0000";

constant zero : std_logic_vector(22 downto 0) := (others => '0');
begin
		
	sign     	<= multiplicand(31);
	exponent		<= multiplicand(30 downto 23);
	significand	<= multiplicand(22 downto 0);

	results <= std_logic_vector(unsigned('1' & significand) * twohundredfiftyfive);
	
	
	product(31) 		  <= sign;	 
	
	product(30 downto 23) <= (others => '0') when exponent = x"00" else
							 std_logic_vector(unsigned(exponent) + x"08") when results(47) = '1' else
							 std_logic_vector(unsigned(exponent) + x"07");
							 
	product(22 downto 0) <= (others => '0') when exponent = x"00" else
							 product_significand(results);


	
	
end dataflow;