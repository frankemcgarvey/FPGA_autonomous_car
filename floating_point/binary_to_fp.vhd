library ieee;
use work.SPP_package.all;
use ieee.std_logic_1164.all;


entity binary_to_fp is   
	port(
		inputInteger     : in  std_logic_vector(15 downto 0) := (others => '0');
		output           : out std_logic_vector(31 downto 0) := (others => '0')
		);
end binary_to_fp;
																											


architecture structural of binary_to_fp is

component significand_generator is
	port(
			inputInteger : in  std_logic_vector(15 downto 0); 
			index        : in  natural range 0 to 15;
			significand  : out std_logic_vector(22 downto 0)
		 );
		 
end component;

signal exponent 	 : std_logic_vector(7 downto 0) := x"00"; 
signal significand : std_logic_vector(22 downto 0) := (others => '0');
signal index    	 : natural range 0 to 15;

begin


	
	
	 exponent_encoder(inputInteger, index, exponent);
	 
	 sgn: significand_generator port map(inputInteger, index, significand);
	 
	 output <= '0' & exponent & significand;
		
		
	



end structural;
---------------------------------------------------------------------
library ieee;
use work.SPP_package.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity significand_generator is
	port(
			inputInteger : in  std_logic_vector(15 downto 0); 
			index        : in  natural range 0 to 15;
			significand  : out std_logic_vector(22 downto 0)
		 );
		 
end significand_generator;


architecture behavioral of significand_generator is


constant zeroMantissa : std_logic_vector(22 downto 0) := (others => '0'); 
constant zero         : std_logic_vector(15 downto 0) := (others => '0');

begin

		process(all)
		begin
		if(inputInteger = zero) then significand <=  zeroMantissa;
		elsif(index = 0)		   then significand <= std_logic_vector(to_signed(0,23));		
		else   						     
				for i in 15 downto 1 loop
					if(i = (index)) then significand <= inputInteger(i-1 downto 0) & std_logic_vector(to_signed(0, 23-(i)));
												exit;
					
					else 						significand <= (others => '0');
												next;
					end if;
				end loop;
		end if;                                   
		end process;
										  

end behavioral;
---------------------------------------------------------------------
