----------------------------------------------------------------------------------
-- Tool for transmitting the cipher text to the Tx
-- 128-bit buffer
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Tx_collecteur is
    port( clk, reset : in std_logic;
          cipher : in std_logic_vector(127 downto 0);
          start_transmit : in std_logic;
          data_to_tx : out std_logic_vector(7 downto 0);
          tx_ready : in std_logic;
          start_tx : out std_logic;
          done_transmit : out std_logic);
end Tx_collecteur;

architecture arch of Tx_collecteur is

    signal cpt : integer range 0 to 16 := 16;
    signal temp_tx_ready : std_logic := '0';

begin

    process(clk,reset)
    begin
        if(reset='1') then
            start_tx <= '0';
            data_to_tx <= (others => '0');
            temp_tx_ready <= '0';
            cpt <= 16;
        elsif(rising_edge(clk)) then
            start_tx <= '0';
            done_transmit <= '1';
            if(start_transmit = '1' and cpt = 16) then
                if(temp_tx_ready = '0') then
                    done_transmit <= '0';
                    data_to_tx <= cipher(127 downto 120); -- first byte to transmit
                    start_tx <= '1';
                    temp_tx_ready <= '1';
                else
                    temp_tx_ready <= '0';
                    cpt <= cpt - 1;
                end if;
            elsif(cpt < 16 and cpt > 0) then
                done_transmit <= '0';
                if(tx_ready = '1') then
                    if(temp_tx_ready = '0') then
                        data_to_tx <= cipher(8*(cpt-1)+7 downto 8*(cpt-1)); -- others bytes to transmit
                        start_tx <= '1';
                        temp_tx_ready <= '1';
                    else
                        temp_tx_ready <= '0';
                        cpt <= cpt - 1;
                    end if;
                end if;
            elsif(cpt = 0) then
                done_transmit <= '0';
                if(tx_ready = '1') then
                    if(temp_tx_ready = '0') then
                        data_to_tx <= cipher(8*cpt+7 downto 8*cpt); --transmitting the last byte
                        start_tx <= '1';
                        temp_tx_ready <= '1';
                    else
                        temp_tx_ready <= '0';
                        cpt <= 16;
                        done_transmit <= '1';  --indicates that all the bytes were transmitted
                    end if;
                end if;
            else
                data_to_tx <= (others => '0'); --resetting the byte to transmit
            end if;
        end if;
    end process;
            


end arch;
