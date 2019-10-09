library ieee; 
use ieee.numeric_std.all;
use work.SPP_package.all;
use ieee.std_logic_1164.all;

entity fp_division is
	port(  
	clk50,
	reset,
	start                  : in  std_logic := '0';
	divisor, dividend    : in  std_logic_vector(31 downto 0) := (others => '0');
	quotient               : out std_logic_vector(31 downto 0) := (others => '0');
	finished               : out std_logic := '0'
	);
end fp_division;


architecture FSM of fp_division is

signal exponentDivisor,
	   exponentDividend     : std_logic_vector(7 downto 0) := x"00";  


--state variables--

type divisionStates is (StartUp, Idle, CheckZero, Shift, Compare, Subtract, Normalize, Done);
signal State, next_State : divisionStates := StartUp;

-------------------	  

   

signal i, iReg : natural range 0 to 100;

signal qBit          : std_logic := '0';	 
signal qStream 	     : std_logic_vector(24 downto 0) := (others => 'Z');

signal shiftReg      : std_logic_vector(24 downto 0) := (others => '0');

signal dividendReg   : std_logic_vector(23 downto 0) := (others => '0');
signal divisorReg	 : std_logic_vector(23 downto 0) := (others => '0');
--signal divisor       : std_logic_vector(31 downto 0) := (others => '0');											    
signal quotientReg   : std_logic_vector(31 downto 0) := (others => '0');

signal bias          : std_logic := '0'; 

signal decimalSpot   : natural range 0 to 23;
begin
	
--Concurrent--

--divisor <= divisorIn;
--------------
		 
	  process(clk50, reset)
	begin
		
		if(reset = '1') 	      then State <= Idle;	
									   iReg <= 0;
		elsif(rising_edge(clk50)) then State <= next_State;	 
									   iReg <= i;
		end if;
	
		
	end process;
	
	
	process(all)

	begin
		
	qBit <= '0';
	i <= iReg;
	finished <= '0';
	
		case(State) is
			
			when StartUp => 
				next_State <=  Idle;
			when Idle =>					
			
			   i <= 0;
				if(start = '1') then next_State <= CheckZero;
				else	 		     next_State <= Idle;
				end if;
			
			when CheckZero =>
			
				if(exponentDivisor = x"00"  or exponentDividend = x"00" ) then next_State <= Done;
				else                                                	next_state <= Shift;
				end if;
				
			when Shift =>	
			
				i <= iReg + 1;
				next_State <= Compare;
				
			when Compare =>
			
				if(divisorReg > shiftReg(23 downto 0)) then 
					qBit <= '0'; 
					if(i = (decimalSpot + add_bias(bias) + 24)) then next_State <= Normalize;
					else          		     next_State <= Shift;
					end if;
					
				else                       qBit <= '1';
										   next_State <= Subtract;
				end if;
			
			when Subtract =>
				
				if(i = (decimalSpot + add_bias(bias) + 24)) then next_State <= Normalize;
				else                     next_State <= Shift;
				end if;
					
			when Normalize => 	 						
								next_State <= Done;
				  
			when Done =>
			
				finished   <= '1';
			   
				 
		
				if(start = '0') then next_State <= Idle;	  
				else                 next_State <= Done;
				end if; 	
				
		end case;
		
	end process;
	 
	
	process(all)
	begin
		
		if(reset = '1') then dividendReg 		<= (others => '0');
							 divisorReg  		<= (others => '0');
							 shiftReg    		<= (others => '0');
							 exponentDivisor	<= (others => '0');
							 exponentDividend	<= (others => '0');
							 qStream  		    <= (others => '0');
							 quotientReg 		<= (others => '0');												   										
							 
		elsif(falling_edge(clk50)) then 
			if(state = Idle) then dividendReg		  <= '1' & dividend(22 downto 0);
								  division_encoder(divisor(22 downto 0), decimalSpot, divisorReg);
								  exponentDivisor  	  <= divisor(30 downto 23);
								  exponentDividend 	  <= dividend(30 downto 23);
								  shiftReg 			  <= (others => '0');	
								  
			elsif(state = CheckZero) then quotientReg <= (others => '0');
			elsif(state = Shift) 	 then 
				if(i < 25) then shiftReg <= shiftReg(23 downto 0) & dividendReg(24-i);
				else            shiftReg <= shiftReg(23 downto 0) & '0';
				end if;
			elsif(state = Compare)   then qStream <= qStream(23 downto 0) & qBit;
				if(i = (decimalSpot + 1)) then bias <= qBit;
				end if;
			elsif(state = Subtract)  then shiftReg(23 downto 0) <= std_logic_vector(unsigned(shiftReg(23 downto 0)) - unsigned(divisorReg));
			elsif(state = Normalize) then 
				quotientReg(31) <= '0';	
				
				if(bias = '0') then quotientReg(30 downto 23) <= std_logic_vector((unsigned(exponentDividend) - unsigned(exponentDivisor)) + x"7E");
				else 				    quotientReg(30 downto 23) <= std_logic_vector((unsigned(exponentDividend) - unsigned(exponentDivisor)) + x"7F");
				end if;	 
				
			    quotientReg(22 downto 0) <= qStream(22 downto 0); 
			elsif(state = Done) then  quotient <= quotientReg;
									  qStream  		    <= (others => '0');
									  shiftReg    		<= (others => '0');
			end if;
		end if;
	end process;
end FSM;