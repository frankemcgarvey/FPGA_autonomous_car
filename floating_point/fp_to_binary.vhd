library ieee;
use work.SPP_package.all;		   
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity fp_to_binary is
	port(
	inputFP : in  std_logic_vector(31 downto 0) := (others => '0');
	output  : out std_logic_vector(7 downto 0)	:= x"00"
	); 
end fp_to_binary;


architecture dataflow of fp_to_binary is
signal exponent 		: std_logic_vector(7 downto 0) := x"00";
signal significand 		: std_logic_vector(22 downto 0) := (others => '0');
signal decimalSpot      : integer range 0 to 7 := 0;

begin

	exponent 	<= inputFP(30 downto 23);
	significand <= inputFP(22 downto 0);
	
	decimalSpot <= to_integer(unsigned(exponent)) - 127 when to_integer(unsigned(exponent)) > 126 and to_integer(unsigned(exponent)) < 135 else 0;
	 
	output <=  x"00" when exponent = x"00" else to_decimal(significand, decimalSpot);
	
	

end dataflow;