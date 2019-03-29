----------------------------------------------------------------------------------
-- tool that collects the plain text coming from Rx
-- 128-bit buffer
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Rx_collecteur is
    port(clk, reset : in std_logic;
         data_in : in std_logic_vector(7 downto 0);
         data_tick : in std_logic;
         plain : out std_logic_vector(127 downto 0);
         full_data : out std_logic);
end Rx_collecteur;

architecture arch of Rx_collecteur is

    signal cpt    : integer range 0 to 15 := 15; --counter of bytes received

begin

    process(clk,reset)
    begin
        if(reset='1') then
            full_data <= '0';
            plain <= (others => '0');
        elsif(rising_edge(clk)) then
            full_data <= '0';
            if(data_tick = '1') then
                plain(8*cpt+7 downto 8*cpt) <= data_in; --storing received bytes
                if(cpt /= 0) then
                    cpt <= cpt - 1;
                    full_data <= '0';
                else
                    cpt <= 15;
                    full_data <= '1'; --all the bytes of the plain were received
                end if;
            end if;
        end if;
    end process;

end arch;
