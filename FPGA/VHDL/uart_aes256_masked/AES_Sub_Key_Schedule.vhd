library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.aes256_pkg.all;

entity AES_Sub_Key_Schedule is
    port ( masterkey : in  std_logic_vector(255 downto 0);
           k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,k10,k11,k12,k13,k14   : out std_logic_vector(127 downto 0); --sub_keys is an array of 10 128-bit vectors
           terminated : out std_logic; --signal that indicates that the subkeys are genereated
           reset      : in  std_logic;
           clk        : in  std_logic;
           cw_trigger : out std_logic);
end AES_Sub_Key_Schedule;

architecture arch of AES_Sub_Key_Schedule is

    signal index : integer range 0 to 60 := 60; --counter for algorithm steps
    signal temp, pre_temp : std_logic_vector(31 downto 0) := (others => '0');
    signal w : word_array;
    signal indexWasTaken : integer range 1 to 3 := 1;
    

begin

    process(clk,reset)
    begin
        if(reset = '1') then
            terminated <= '0';
            index <= 0;
            cw_trigger <= '1';    
        elsif(rising_edge(clk)) then
            cw_trigger <= '0';
            if (index < 8) then
                w(index) <= masterkey(255-(32*index) downto 255-(32*index)-31);
                index <= index + 1;
            elsif(index < 60) then
                if(indexWasTaken = 1) then
                    temp <= w(index-1);
                    indexWasTaken <= 2;
                elsif(indexWasTaken = 2) then
                    if(index = 8 or index = 16 or index = 24 or index = 32 or index = 40 or index = 48 or index = 56) then
                        temp <= SWRW(temp,index);
                    elsif(index = 12 or index = 20 or index = 28 or index = 36 or index = 44 or index = 52) then
                        temp <= subWord(temp);
                    end if;
                    indexWAsTaken <= 3;
                else
                    w(index) <= w(index-8) xor temp;  
                    index <= index + 1 ;
                    indexWasTaken <= 1;
                end if;
            elsif(index = 60) then
                terminated <= '1';
                k0 <= w(0) & w(1) & w(2) & w(3);
                k1 <= w(4) & w(5) & w(6) & w(7);
                k2 <= w(8) & w(9) & w(10) & w(11);
                k3 <= w(12) & w(13) & w(14) & w(15);
                k4 <= w(16) & w(17) & w(18) & w(19);
                k5 <= w(20) & w(21) & w(22) & w(23);
                k6 <= w(24) & w(25) & w(26) & w(27);
                k7 <= w(28) & w(29) & w(30) & w(31);
                k8 <= w(32) & w(33) & w(34) & w(35);
                k9 <= w(36) & w(37) & w(38) & w(39);
                k10 <= w(40) & w(41) & w(42) & w(43);
                k11 <= w(44) & w(45) & w(46) & w(47);
                k12 <= w(48) & w(49) & w(50) & w(51);
                k13 <= w(52) & w(53) & w(54) & w(55);
                k14 <= w(56) & w(57) & w(58) & w(59);
                index <= index + 1;
            else
                terminated <= '0';
            end if; 
        end if;
    end process;
end arch;
