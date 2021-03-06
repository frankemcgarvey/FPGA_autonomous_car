--synthesis VHDL_INPUT_VERSION VHDL_2008 
library ieee;

use ieee.std_logic_1164.all;

entity i2c_master is
	generic( 
				clk_freq  : integer := 50_000_000;
				i2c_freq  : integer := 400_000;
				--7 bit address is 0x29
				slaveWR0  : std_logic_vector(7 downto 0) := x"52"; --Slave's address with 0 extended lSB
				slaveRD0  : std_logic_vector(7 downto 0) := x"53"  --Slave's address with 1 extended LSB
			  );
	port(
			clk50,
			WR, RD,  --Triggers i2c_master FSM
			reset     	: in    std_logic 						 := '0';
			reRead    	: in    natural range 0 to 7;
			dIn       	: in    std_logic_vector(7 downto 0) := (others => '0'); --Data for slave
			Reg_Addr  	: in    std_logic_vector(7 downto 0) := (others => '0'); --Address of slave's register
			SCL	   	: out   std_logic := '0';
			SDA0, SDA1	: inout std_logic := '0';
			busy,
			statusBit,
			flag      	: out   std_logic := '0'; --Indicates if the i2c_master is busy  
			output0,
			output1     : out   std_logic_vector(7 downto 0) := (others => '0') --Output of the SDA
		 );
end i2c_master; 

architecture FSM of i2c_master is

CONSTANT divider  :  INTEGER := (clk_freq/i2c_freq)/4; --number of clocks in 1/4 cycle of scl

type masterState is (
						  StartUp,
						  Idle, Start, Slave_Address, Ack1, Stop, Hold,
                    WR_Address, Ack2, Write_Data, Ack3,
						  RD_Address, Ack4, restartL, restartR, Initiate_Read, Ack5, Read_Data, Read_Again, noAck
						  );

signal prev_State, next_State : masterState := StartUp;

signal i2c_clk, data_clk     : std_logic := '0';

signal i, iReg,
		 j, jReg		: natural range 0 to 8;

signal wr_Reg     : std_logic := '0'; --Register to indicate rd or wr command

signal sda_ena0,
		 sda_ena1 	: std_logic := '0'; --Controlls the SDA

signal memory0, memory1 : std_logic_vector(7 downto 0) := x"00";
begin

--i2c clk--
--	process(all)
--	variable clk_counter : natural range 0 to 2*clk_freq/(i2c_freq);
--	begin
--	
--		if(rising_edge(clk50)) then clk_counter := clk_counter + 1;
--			if(clk_counter = clk_freq/(2*i2c_freq)) then i2c_clk <= not i2c_clk;
--																		clk_counter := 0;
--			end if;
--		end if;
--	end process;

PROCESS(all)
    VARIABLE count : INTEGER RANGE 0 TO divider*4; --timing for clock generation
  BEGIN
    IF(reset = '1') THEN               --reset asserted
      count := 0;
    ELSIF(rising_edge(clk50)) THEN
      IF(count = divider*4-1) THEN       --end of timing cycle
        count := 0;                      --reset timer
      ELSE
        count := count + 1;              --continue clock generation timing
      END IF; 
      CASE count IS
        WHEN 0 TO divider-1 =>           --first 1/4 cycle of clocking
          i2c_clk <= '0';
          data_clk <= '0';
        WHEN divider TO divider*2-1 =>   --second 1/4 cycle of clocking
          i2c_clk <= '0';
          data_clk <= '1';
        WHEN divider*2 TO divider*3-1 => --third 1/4 cycle of clocking
          i2c_clk <= '1';                
          data_clk <= '1';
        WHEN OTHERS =>                   --last 1/4 cycle of clocking
          i2c_clk <= '1';
          data_clk <= '0';
      END CASE;
    END IF;
  END PROCESS;


-----------------	

--FSM--	
	process(all)
	begin
	
		if   (reset = '1') 			   then prev_State <= StartUp;
													  iReg <= 0;
													  jReg <= 0;
											  
		elsif(rising_edge(data_clk)) then prev_State <= next_State;
												     iReg <= i;
													  jReg <= j;
		end if;
	

	end process;

--Next state logic--	
	
	process(all)
	begin
	
	--Default values--
	SCL <= i2c_clk;
	i <= 0;
	j <= 0;
	flag <= '0';
	busy <= '1'; --Busy
	------------------
	
		case (prev_State) is
		
			when StartUp =>	    next_State <= Idle;
										 sda_ena0 <= '1';
										 sda_ena1 <= '1';
										 SCL <= '1';
			when Idle => 		
								SCL <= '1';  --Holds high waiting for WR or RD for a start command
								sda_ena0 <= '1'; --High impedance
								sda_ena1 <= '1';
								busy <= '0'; --Not busy
								if(WR = '1' or RD = '1') then next_State <= Start;
								else              				next_State <= Idle;
								end if;
						
			when Start => 
							
								SCL <= '1';
								sda_ena0 <= '0'; --Start command 
								sda_ena1 <= '0'; 
								next_State <= Slave_Address;
			
			when Slave_Address =>

								
								sda_ena0 <= slaveWR0(8-i); --Slave's wr address 
								sda_ena1 <= slaveWR0(8-i);
								
								i <= iReg + 1;
								
								if(i = 8) then next_State <= Ack1; 
								else           next_State <= Slave_Address;
											   
								end if;
			
			when Ack1 =>
								
								sda_ena0 <= '1';
								sda_ena1 <= '1';
								
								if(wr_Reg = '1') then next_State <= WR_Address;
								else       		 	  	 next_State <= RD_Address;
								end if;
			
			when Stop =>
								
								sda_ena0 <= '0'; --Low 
								sda_ena1 <= '0';
								SCL <= '1';
								next_State <= Hold;
								
			when Hold => 		 
								SCL <= '1';
								sda_ena0 <= '1';
								sda_ena1 <= '1';
								if(wr = '0' and rd = '0') then next_State <= Idle;
								else                				 next_State <= Hold;
								end if;
			
			when WR_Address =>
								  
								sda_ena0 <= Reg_Addr(8-i); --Slave's register address
								sda_ena1 <= Reg_Addr(8-i);
								
								i <= iReg + 1;
								
								if(i = 8) then next_State <= Ack2;
								else           next_State <= WR_Address;
								end if;
			
			 when Ack2 =>
								
								sda_ena0 <= '1';
								sda_ena1 <= '1';
								next_State <= Write_Data;
			
			 when Write_Data =>
								
								sda_ena0 <= dIn(8-i);  --Data for slave
								sda_ena1 <= dIn(8-i);
							
								i <= iReg + 1;
								
								if(i = 8) then next_State <= Ack3;
								else           next_State <= Write_Data;
								end if;
			  
			 when Ack3 =>
							
								sda_ena0 <= '1';
								sda_ena1 <= '1';
								
								next_State <= Stop;
			
				
			 when RD_Address =>
			 
			 					
			 					sda_ena0 <=  Reg_Addr(8-i); --Read Command address for slave's register
								sda_ena1 <=  Reg_Addr(8-i);
								
								i <= iReg + 1;
								
								if(i = 8) then next_State <= Ack4;
								else           next_State <= RD_Address;
								end if;
								
			 when Ack4 =>
			 
							 sda_ena0 <= '1';
							 sda_ena1 <= '1';
							 
							 next_State <= restartL;
			
			 when restartL =>
			 
							 SCL <= '0';
							 sda_ena0 <= '1';
							 sda_ena1 <= '1';
							 
							 next_State <= restartR;
				
			 when restartR =>
			 
							SCL <= '1';
							sda_ena0 <= not i2c_clk; --Read protocol - combined protocol restart
							sda_ena1 <= not i2c_clk;
							next_State <= Initiate_Read;
							
				
			 when Initiate_Read =>
			 
							
			 				sda_ena0 <= slaveRD0(8-i); --Slave's rd address
							sda_ena1 <= slaveRD0(8-i);
							
							i <= iReg + 1;
							
							if(i = 8) then next_State <= Ack5;
							else           next_State <= Initiate_Read;
							end if;
							
			when Ack5 =>

							sda_ena0 <= '1';
							sda_ena1 <= '1';
							next_State <= Read_Data;
							
			when Read_Data =>
						
							sda_ena0 <= '1';
							sda_ena1 <= '1';
							
							i <= iReg + 1;
							j <= jReg;			
							if(i = 8) then 
								
								if(j = reRead) then next_State <= noAck;
								else           next_State <= Read_Again;
								end if;
												
							else           next_State <= Read_Data;
							end if;
		
		 when Read_Again =>
					
							flag <= '1';
							j <= jReg + 1;
							sda_ena0 <= '0';
							sda_ena1 <= '0';
							next_State <= Read_Data;
							
		 when noAck =>
							
							if(reRead = 1) then flag <= '1';
			 				else          	    flag <= '0';
							end if;
							
							sda_ena0 <= '1';
							sda_ena1 <= '1';
							next_State <= Stop;
							
		end case;	
	
	end process;
	

	SDA0 <= '0' WHEN sda_ena0 = '0' ELSE 'Z'; --If sda_ena_n is high, then SDA is high impedance; else SDA is low
	SDA1 <= '0' WHEN sda_ena1 = '0' ELSE 'Z';

	process(all)
	begin
	
		if(falling_edge(clk50)) then
				if(prev_State = Read_Again) then output0 <= memory0;
															output1 <= memory1;
			elsif(prev_State = noAck) then 
														if(reRead = 1) then output0 <= memory0;
																				  output1 <= memory1;
														end if;	
			end if;
		end if;
	
		if(rising_edge(clk50)) then 
			if(prev_State = Idle) then wr_Reg <= WR; --Register to remember WR or RD command
			end if;
		end if;

		if(falling_edge(data_clk)) then 
				if(prev_State = Start)    	then memory0 	<= x"00";
														  memory1 	<= x"00";
														  statusBit <= '0';									  
			elsif(prev_State = Read_Data) then memory0(8-i) <= SDA0;
														  memory1(8-i) <= SDA1;
			elsif(prev_State = noAck)     then statusBit   <= memory0(0) or memory1(0);
			end if;
		end if;

	end process;

	
end FSM;