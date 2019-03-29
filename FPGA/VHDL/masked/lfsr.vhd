library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity lfsr is
    port ( seed : in  std_logic_vector(127 downto 0);
           start: in std_logic;
           clk  : in  std_logic;
           outp : out std_logic_vector(127 downto 0));
end lfsr;

architecture arch of lfsr is

    signal state     : std_logic_vector(127 downto 0);
    signal state_bis : std_logic_vector(127 downto 0) := (others => '0');
    signal MSB,deb   : std_logic := '0';
    signal index     : integer range 0 to 128 := 0;
    signal can_run   : std_logic := '0';

begin
 
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(start = '1') then -- if statement in order to detect a change of seed -> launches the lfsr again
                state <= seed;
                index <= 0;
                can_run <= '1';
            elsif(can_run = '1') then
                MSB <= state(127) xor state(126) xor state(125) xor state(120) xor state(0);
                state <= MSB & state(127 downto 1);
                
                if(index < 128) then -- random value is made of 128 bits
                    state_bis(index) <= state(0);
                    index <= index + 1;
                else
                    outp <= state_bis;
                    index <= 0;
                end if;
            end if;
        end if;
    end process; 

end arch;
