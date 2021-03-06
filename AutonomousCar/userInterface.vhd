library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity userInterface is
	port(
			clk50,
			busy,	  --Indicicates if the i2c_master is busy
			reset,
		   statusInput  : in    std_logic := '0';
			WR, RD       : out   std_logic := '0'; --Starts the i2c_master fsm
			dout, --Data for the slave
			regOut 	    : out   std_logic_vector(7 downto 0) := (others => '0'); --Address of the slave's register
			reRead       : out   natural range 0 to 7
			);
end userInterface;



architecture FSM of userInterface is

signal machineTimer : std_logic := '0';

 
--States--

type UIstates is (StartUp, Initialize, Read0, Read1, Read2, Write0, Write1, Hold);

signal prev_State, next_State : UIstates := StartUp;
--==============--	

signal byteCounter : natural range 0 to 10 := 0;

begin

	process(clk50, reset)
	begin
		
		if(reset = '1') 	      then prev_State <= StartUp;
		elsif(rising_edge(clk50)) then prev_State <= next_State;
		end if;
		
		if(rising_edge(clk50)) then 
			
			   if(prev_State = Initialize) then regOut <= x"80"; --Enable register address "1000_0000"
															dOut   <= x"03"; --Data "0000_0011"
															byteCounter <= 0;
														 
			elsif(prev_State = Read0)      then regOut <= x"93";
															
															byteCounter <= byteCounter;
															reRead <= 0;
															
			elsif(prev_State = Read1)      then regOut <= x"B4"; --
														   byteCounter <= 3; --
															reRead <= 1;
															
			elsif(prev_State = Read2)      then regOut <= x"B6"; --
														   byteCounter <= 2; --
															reRead <= 1;
			
			elsif(prev_State = Write0)   	 then regOut <= x"8F"; --
															dout   <= x"00";
														   byteCounter <= 1; --

															
			elsif(prev_State = Write1)  	 then regOut <= x"81";
															dOut   <= x"F6";
															byteCounter <= 2;
														
			end if;
		end if;
		
	end process;
	
	
	process(all)

	begin
	
	--Default values--
	RD   <= '0';
	WR   <= '0';
	------------------
		case(prev_State) is
		
			when StartUp =>
				
				if (busy = '1') then next_State <= StartUp;
				else                 next_State  <= Initialize;	 
				end if;
				
			when Initialize =>	
			
							WR     	   <= '1'; --Starts the i2c_master FSM
							
							if(busy = '0') then next_State <= Initialize; 
							else 					  next_State <= Hold;		 --When i2c_master becomes busy switch to hold		
							end if;
							
			when Read0 =>
						
							RD    	   <= '1'; --Starts the i2c_master FSM
						
							if(busy = '0') then next_State <= Read0;					
							else     			  next_State <= Hold;	 --When i2c_master becomes busy switch to hold			
							end if;	
							
			when Read1 =>
						
							RD    	   <= '1'; --Starts the i2c_master FSM
						
							if(busy = '0') then next_State <= Read1;					
							else     			  next_State <= Hold;	 --When i2c_master becomes busy switch to hold			
							end if;
					
			
			
			when Read2 =>
						
							RD    	   <= '1'; --Starts the i2c_master FSM
						
							if(busy = '0') then next_State <= Read2;					
							else     			  next_State <= Hold;	 --When i2c_master becomes busy switch to hold			
							end if;
		
		
			when Write0 =>
						
							WR	   	   <= '1'; --Starts the i2c_master FSM
						
							if(busy = '0') then next_State <= Write0;					
							else     			  next_State <= Hold;	 --When i2c_master becomes busy switch to hold			
							end if;	
			
			when Write1 =>
						
							WR	   	   <= '1'; --Starts the i2c_master FSM
						
							if(busy = '0') then next_State <= Write1;					
							else     			  next_State <= Hold;	 --When i2c_master becomes busy switch to hold			
							end if;
			
			
			when Hold => 	
			
	
							if(busy = '1') then next_State <= Hold; 				  		  
							else 
							
									if(byteCounter = 0)   then next_State <= Write0;
								elsif(byteCounter = 1)   then next_State <= Write1;
								elsif(statusInput = '1') then 
											
											if(byteCounter = 2) then next_State <= Read1;
											else                     next_State <= Read2;
											end if;
												
								else   								 	 next_State <= Read0;                    
								end if;
							end if;	
				
				
								
		end case;
		
	end process;
end FSM;