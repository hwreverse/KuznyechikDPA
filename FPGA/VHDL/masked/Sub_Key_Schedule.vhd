library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.grasshopper_pkg.all;

entity Sub_Key_Schedule is
    port ( masterkey : in  std_logic_vector(255 downto 0);
           k1,k2,k3,k4,k5,k6,k7,k8,k9,k10   : out std_logic_vector(127 downto 0); --sub_keys is an array of 10 128-bit vectors
           terminated : out std_logic; --signal that indicates that the subkeys are genereated
           reset      : in  std_logic;
           clk        : in  std_logic;
           cw_trigger : out std_logic);
end Sub_Key_Schedule;

architecture arch of Sub_Key_Schedule is

    signal index : integer range 0 to 35 := 35; --counter for algorithm steps
    signal tuple_inter : tuple; --tuple is an array of 2 128-bit vectors

begin

    process(clk,reset)
    begin
        if(reset = '1') then
            terminated <= '0';
            index <= 0;
            cw_trigger <= '1';    
        elsif(rising_edge(clk)) then
            cw_trigger <= '0';
            if index < 34 then
                terminated <= '0';
                if index = 0 then
                    k1 <= masterkey(255 downto 128);
                    k2 <= masterkey(127 downto 0  );
                    tuple_inter(0) <= masterkey(255 downto 128);
                    tuple_inter(1) <= masterkey(127 downto 0  );
                else
                    tuple_inter <= fStep(tuple_inter(0),tuple_inter(1), SUB_KEYS_CI(index));
                    if index = 9 then
                        k3 <= tuple_inter(0);
                        k4 <= tuple_inter(1);
                    elsif index = 17 then
                        k5 <= tuple_inter(0);
                        k6 <= tuple_inter(1); 
                    elsif index = 25 then
                        k7 <= tuple_inter(0);
                        k8 <= tuple_inter(1);
                    elsif index = 33 then
                        k9 <= tuple_inter(0);
                        k10 <= tuple_inter(1);
                    end if;
                end if;
                index <= index + 1 ;
            elsif(index = 34) then
                terminated <= '1';
                index <= index + 1;
            else
                terminated <= '0';
            end if; 
        end if;
    end process;
end arch;
