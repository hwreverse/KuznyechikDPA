----------------------------------------------------------------------------------
-- AES-256 masked encryption/decryption UART
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_AES256_MASKED is
    port ( clk, reset : in  std_logic;
           rx         : in  std_logic;
           tx         : out std_logic;
           enc_dec_sel: in  std_logic;  --selecter for either encryption or decryption
           cw_trigger : out std_logic); --trigger pin for ChipWhisperer Capture
end UART_AES256_MASKED;

architecture arch of UART_AES256_MASKED is

    signal LOWclk : std_logic := '0';

    signal tx_ready   : std_logic := '0';
    signal tx_start   : std_logic := '0';
    signal tx_data_in : std_logic_vector(7 downto 0) := (others => '0');
    
    signal rx_data_out : std_logic_vector(7 downto 0) := (others => '0');
    signal data_valid  : std_logic := '0' ;
    
    signal sks_end : std_logic := '0';
    signal can_transmit_cipher : std_logic := '0';
    signal done_transmit : std_logic := '0';

    signal plain, cipher, mask : std_logic_vector(127 downto 0) := (others => '0');
    signal k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,k10,k11,k12,k13,k14 : std_logic_vector(127 downto 0) := (others => '0');
    signal full_data : std_logic := '0';
    signal masterkey : std_logic_vector(255 downto 0) := x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"; 
    
    attribute dont_touch : string;
    attribute dont_touch of masterkey : signal is "true";
    attribute dont_touch of plain     : signal is "true";
    attribute dont_touch of k0,k1,k2,k3,k4,k5,k7,k8,k9,k10,k11,k12,k13,k14 : signal is "true";
    attribute dont_touch of cipher    : signal is "true";
    
    signal clk_counter : integer range 0 to 5 := 0;
    
begin

    --components declarations
    tx_comp : entity work.tUART(behavior)
              generic map (baud => 115200, clk_rate => 100000000)
              port    map (data_out => tx, tx_ready => tx_ready, start => tx_start, data_in => tx_data_in, reset => reset, clk => clk);

    rx_comp : entity work.rUART(behavior)
              generic map (baud => 115200, clk_rate => 100000000)
              port    map (data_out => rx_data_out, data_valid => data_valid, data_in => rx, reset => reset, clk => clk);
              
    rx_coll : entity work.Rx_collecteur(arch)
              port    map (clk => clk, reset => reset, data_in => rx_data_out, data_tick => data_valid, plain => plain, full_data => full_data);
              
    tx_coll : entity work.Tx_collecteur(arch)
              port    map (clk => clk, reset => reset, cipher => cipher, start_transmit => can_transmit_cipher, data_to_tx => tx_data_in, tx_ready => tx_ready, start_tx => tx_start, done_transmit => done_transmit);
              
    sks     : entity work.AES_Sub_Key_Schedule(arch)
              port    map (masterkey => masterkey, k0 => k0, k1 => k1, k2 => k2, k3 => k3, k4 => k4, k5 => k5, k6 => k6, k7 => k7, k8 => k8, k9 => k9, k10 => k10, k11 => k11, k12 => k12, k13 => k13, k14 => k14, terminated => sks_end, reset => full_data, clk => LOWclk, cw_trigger => cw_trigger);
              
    encrypt : entity work.aes256_encryption_masked(arch)
              port    map (clk => LOWclk, reset => reset, plain => plain, k0 => k0, k1 => k1, k2 => k2, k3 => k3, k4 => k4, k5 => k5, k6 => k6, k7 => k7, k8 => k8, k9 => k9, k10 => k10, k11 => k11, k12 => k12, k13 => k13, k14 => k14, can_start => sks_end, cipher => cipher, can_transmit => can_transmit_cipher, transmit_before => done_transmit, enc_dec_sel => enc_dec_sel, mask => mask);
    
    prng    : entity work.lfsr(arch)
              port    map (seed => plain, start => full_data, clk => clk, outp => mask);
                  
              
    --generation of a 20 MHz clock for SKS and encryption
    LOWclk_proc : process(clk)
    begin
      if(rising_edge(clk)) then
          if(clk_counter = 5) then
              LOWclk <= not LOWclk;
              clk_counter <= 0;
          else
              clk_counter <= clk_counter + 1;
          end if;
      end if;
    end process;


end arch;
