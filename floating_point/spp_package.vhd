library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;


package SPP_package is

	
	procedure exponent_encoder (signal inputInteger  	  : in  std_logic_vector(15 downto 0); 	
								signal index 			  : out natural range 0 to 15;
								signal exponent			  : out std_logic_vector(7 downto 0));
										 
	procedure division_encoder (signal inputInteger : in  std_logic_vector(22 downto 0);
								signal index        : out natural range 0 to 23;
								signal divisor      : out std_logic_vector(23 downto 0));
	
	function product_significand(signal inputInteger : std_logic_vector(47 downto 0))
								 return std_logic_vector;

	function quotient_significand(signal inputInteger : std_logic_vector(23 downto 0))
								  return std_logic_vector;
	function add_bias(signal bias : std_logic)
					 return natural;
	function to_decimal(signal significand : std_logic_vector(22 downto 0);
							  signal index            : integer range 0 to 7)
							  return std_logic_vector;
				
--	function division(signal divisor, dividend : std_logic_vector(23 downto 0))
--			         return std_logic_vector;

	
end package;


package body SPP_package is

	procedure exponent_encoder (signal inputInteger 	  : in  std_logic_vector(15 downto 0);
										 signal index       		  : out natural range 0 to 15;
										 signal exponent			  : out std_logic_vector(7 downto 0)) is 
								
constant zero	 : std_logic_vector(15 downto 0) := (others => '0');								

begin									 
	if(inputInteger = zero) then exponent <= x"00";
										  index <= 0;
		
	else 
		for j in 15 downto 0 loop
		
			if(inputInteger(j) = '1') then exponent <= std_logic_vector(to_unsigned(j,8) + x"7F");
													 index    <= j;
													 exit;  
													 
			else                           exponent <= x"00";
												    index    <= j;
													 next;
			end if;
			
		end loop;
	end if;
	 
end procedure;

	procedure division_encoder (signal inputInteger : in  std_logic_vector(22 downto 0);
								signal index        : out natural range 0 to 23;
								signal divisor      : out std_logic_vector(23 downto 0)) is
					
			
variable input : std_logic_vector(23 downto 0) := x"000000";

begin
	

	input := '1'&inputInteger;
	
	for j in 0 to 23 loop
		
		if(input(j) = '1') then divisor <= std_logic_vector(to_signed(0, j)) & input(23 downto j); 
								index <= 23 - j;
								exit;  
		else					next;
		end if;
			
	end loop;
	
	
end procedure;


	function product_significand(signal inputInteger : std_logic_vector(47 downto 0))
								return std_logic_vector is	
	
begin
	 
		for j in 47 downto 0 loop
		
			if(inputInteger(j) = '1') then 
				   if(j = 0)  then return std_logic_vector(to_signed(0,23));
				elsif(j > 23) then return inputInteger(j-1 downto j-23);
				else               return inputInteger(j-1 downto 0) & std_logic_vector(to_signed(0, 23-(j)));
				end if;
				exit;  
			else	next;
			end if;
			
		end loop;
 		return std_logic_vector(to_signed(0,23));
end function;


function quotient_significand(signal inputInteger : std_logic_vector(23 downto 0))
								return std_logic_vector is	
	
begin
	 
		for j in 23 downto 0 loop
		
			if(inputInteger(j) = '1') then 
				if(j = 0)  then return std_logic_vector(to_signed(0,23));
				else            return inputInteger(j-1 downto 0) & std_logic_vector(to_signed(0, 23-(j)));
				end if;
				exit;  
			else	next;
			end if;
			
		end loop;
 		return std_logic_vector(to_signed(0,23));
end function;

   function add_bias(signal bias : std_logic)
   return natural is
begin
	
	if(bias = '0') then return 1;
	else                return 0;
	end if;
	
end function;

	function to_decimal(signal significand : std_logic_vector(22 downto 0);
								  signal index            : integer range 0 to 7)
								  return std_logic_vector is
								  
begin

	for i in 7 downto 0 loop
	
		if(i = index) then return std_logic_vector(to_unsigned(0,7 - i)) & '1' & significand(22 downto 23-i);
								 exit;
		else               next;
		end if;
	
	end loop;

  return std_logic_vector(to_unsigned(0, 8));
end function;
	--  function division(signal divisor, dividend : std_logic_vector(23 downto 0))
--	 	 				return std_logic_vector;
--begin
--	
--	  
--	
--end function;
	
end package body;