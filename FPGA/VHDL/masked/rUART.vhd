-------------------------------------------------------------------------------
--	FILE:			rUART.vhd
--
--	DESCRIPTION:	This design is used to implement a UART Receiver.
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity rUART is
generic(
	baud 						: integer := 115200;
	clk_rate					: integer := 100000000);
port(
	data_out					: out std_logic_vector(7 downto 0);
	data_valid					: out std_logic;
	data_in						: in std_logic;
	reset						: in std_logic;
	clk							: in std_logic);
end rUART;

architecture behavior of rUART is
  	
constant clk_freq 				: integer := clk_rate;
constant max_bit_count 			: integer := clk_freq / baud;
constant max_start_bit_count 	: integer := max_bit_count / 2;
constant max_bits 				: integer := 10;
	
signal bit_counter 				: integer range 0 to max_bit_count - 1 := 0;
signal start_bit_counter 		: integer range 0 to max_start_bit_count - 1 := 0;
signal number_bits 				: integer range 0 to max_bits-1 := 0 ;
	
-- signals used for edge detection circuitry
signal start_reg 				: std_logic_vector(1 downto 0) := (others => '0');
signal start_proc 				: std_logic := '0';
	
-- signals used for the UART shift register
signal data_reg 				: std_logic_vector(9 downto 0) := (others => '0');
	
-- control signals
signal read_start 				: std_logic := '0';
signal reading 					: std_logic:= '0';
signal done_reading 			: std_logic:= '0';
signal read_bit 				: std_logic:= '0';

type state_type is(init_state, read_start_bit_state, 
	read_bits_state, done_state);
signal state, nxt_state			: state_type;
	
begin
	-- state machine processes
	state_proc : process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				state <= init_state;
			else
				state <= nxt_state;
			end if;
		end if;
	end process state_proc;
	nxt_state_proc : process(state, start_proc, read_bit, done_reading)
	begin
		nxt_state <= state;		read_start <= '0';	
		reading <= '0';			data_valid <= '0';
		
		case state is
			when init_state => 
				if start_proc = '1' then
					nxt_state <= read_start_bit_state;
				else
					nxt_state <= init_state;
				end if;
			when read_start_bit_state =>
				read_start <= '1';
				if(read_bit = '1') then
					nxt_state <= read_bits_state;
				else
					nxt_state <= read_start_bit_state;
				end if;
			when read_bits_state =>
				reading <= '1';
				if (done_reading = '1') then
					nxt_state <= done_state;
				else
					nxt_state <= read_bits_state;
				end if;
			when done_state =>
				data_valid <= '1';
				if(start_proc = '1') then
					nxt_state <= read_start_bit_state;
				else
					nxt_state <= init_state;
				end if;
			when others =>
				nxt_state <= init_state;
		end case;
	end process nxt_state_proc;

	-- we start with edge detection circuitry for the start input
	start_proc <= start_reg(1) and start_reg(0);
	start_reg_proc : process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				start_reg(1 downto 0) <= (others => '0');
			else
				start_reg(0) <= not data_in;
				start_reg(1) <= not start_reg(0);
			end if;
		end if;
	end process start_reg_proc;
		
	-- start bit counter
	start_bit_proc : process(clk)
	begin
		if(rising_edge(clk)) then
			if((reset = '1') or (start_bit_counter = max_start_bit_count-1)) then
				start_bit_counter <= 0;
			elsif(read_start = '1') then
				start_bit_counter <= start_bit_counter + 1;
			else
				start_bit_counter <= 0;
			end if;
		end if;
	end process start_bit_proc;
	-- all other bits counter
	bit_count_proc : process(clk)
	begin
		if(rising_edge(clk)) then
			if((reset = '1') or (bit_counter = max_bit_count-1)) then
				bit_counter <= 0;
			elsif(reading = '1') then
				bit_counter <= bit_counter + 1;
			else
				bit_counter <= 0;
			end if;
		end if;
	end process bit_count_proc;
		
	-- flag to determine when we read a bit
	read_start_bit_proc : process(start_bit_counter, bit_counter)
	begin
		if((start_bit_counter = max_start_bit_count-1) or (bit_counter = max_bit_count-1)) then
			read_bit <= '1';
		else
			read_bit <= '0';
		end if;
	end process read_start_bit_proc;
		
	-- processes to keep track of the number of bits read
	number_bits_proc : process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1' or number_bits = (max_bits-1) or reading = '0') then
				number_bits <= 0;
			elsif(bit_counter = max_bit_count - 1) then
				number_bits <= number_bits + 1;
			end if;
		end if;
	end process number_bits_proc;
	done_reading_proc : process(number_bits)
	begin
		if(number_bits = (max_bits-1)) then
			done_reading <= '1';
		else
			done_reading <= '0';
		end if;
	end process done_reading_proc;
			
	-- shift register process (we use little endian for the tranmitter)
	-- hense, a right shift register
	data_out <= data_reg(8 downto 1);
	shift_reg_proc : process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				data_reg <= (others => '0');
			elsif(read_bit = '1') then
				data_reg <= data_in & data_reg(9 downto 1);
			end if;
		end if;
	end process shift_reg_proc;	
end behavior;
