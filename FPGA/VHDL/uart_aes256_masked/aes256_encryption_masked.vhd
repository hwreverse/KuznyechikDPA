----------------------------------------------------------------------------------
-- Masked AES-256 Encryption / Decryption
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.aes256_pkg.all;

entity aes256_encryption_masked is
    port (clk, reset    : in std_logic;
          plain         : in std_logic_vector(127 downto 0);
          k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,k10,k11,k12,k13,k14 : in std_logic_vector(127 downto 0); -- sub keys
          can_start     : in std_logic; -- signal that allows or not to start the encryption
          cipher        : out std_logic_vector(127 downto 0);
          can_transmit  : out std_logic; -- signal that allows or not the transmitting process
          transmit_before : in std_logic; --signal that indicates that the previous cipher was transmitted
          enc_dec_sel   : in std_logic;
          mask          : in std_logic_vector(127 downto 0)); 
end aes256_encryption_masked;

architecture arch of aes256_encryption_masked is

    signal tour : integer range 0 to 16 := 0;
    attribute keep : string;
    attribute keep of tour : signal is "true";
    
    signal subKeys : sub_keys_aes;
    signal inter_state, inter_mask : std_logic_vector(127 downto 0) := (others => '0');
    
    signal mem_cipher : std_logic_vector(127 downto 0) := (others => '0');

begin

    subKeys <= (k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,k10,k11,k12,k13,k14);

    process(clk,reset)
    begin
        if(reset='1') then
            cipher <= (others=>'0');
            can_transmit <= '0';
            tour <= 0;
        elsif(rising_edge(clk)) then
            if(enc_dec_sel = '0') then -- selecter in encryption mode
                if(tour = 0) then
                    if(can_start = '1') then
                        tour <= 1;
                        inter_state <= plain xor k0 xor mask;
                        inter_mask <= mask;
                        can_transmit <= '0';
                    end if;
                elsif(tour > 0 and tour < 14) then
                    inter_state <= masked_round(inter_state, subKeys(tour), inter_mask); --standard grasshopper round
                    inter_mask <= mask_operation(inter_mask);
                    tour <= tour + 1;
                elsif(tour = 14) then
                    inter_state <= masked_last_round(inter_state,subKeys(14), inter_mask);
                    inter_mask <= shiftRows(inter_mask);
                    tour <= tour + 1;
                else
                    cipher <= inter_state xor inter_mask;
                    if(transmit_before = '1' and mem_cipher /= inter_state) then -- condition for starting to transmit the cipher
                        can_transmit <= '1';
                        mem_cipher <= inter_state;
                    else
                        can_transmit <= '0';
                        tour <= 0;
                    end if;
                end if;
            else --selecter in decryption mode
                if(tour = 0) then
                    if(can_start = '1') then
                        tour <= 1;
                        inter_state <= plain xor subKeys(14) xor mask;
                        inter_mask <= mask;
                        can_transmit <= '0';
                    end if;
                elsif(tour > 0 and tour < 14) then
                    inter_state <= inv_masked_round(inter_state, subKeys(14 - tour), inter_mask); --standard aes inverse round, defined in the aes package
                    inter_mask <= inv_mask_operation(inter_mask);
                    tour <= tour + 1;
                elsif(tour = 14) then
                    inter_state <= inv_masked_last_round(inter_state,subKeys(0), inter_mask); -- last inverse round
                    inter_mask <= inv_shiftRows(inter_mask);
                    tour <= tour + 1;
                elsif(tour = 15) then
                    cipher <= inter_state xor inter_mask;
                    if(transmit_before = '1' and mem_cipher /= inter_state) then -- condition for starting to transmit the cipher
                        can_transmit <= '1';
                        mem_cipher <= inter_state;
                    else
                        can_transmit <= '0';
                        tour <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;
                    
end arch;
