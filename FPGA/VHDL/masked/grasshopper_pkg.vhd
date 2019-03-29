--------------------------------------------------------------------------------------------------
-- File        : grasshopper_pkg.vhd
-- Date        : June 8th, 2018
-- Last update : August 28th, 2018
-- Summary     : Definition of the functions used in Grasshopper encryption and decryption algorithms
--------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package grasshopper_pkg is

    ----------------------------------------------------------------
    -- Types
    ----------------------------------------------------------------

    type linear_array         is array(0 to 255) of std_logic_vector(7 downto 0);
    type bidimensionnal_array is array(1 to 8  , 0 to 255) of std_logic_vector(7 downto 0);
    type tuple                is array(0 to 1  ) of std_logic_vector(127 downto 0);
    type sub_keys             is array(1 to 10 ) of std_logic_vector(127 downto 0);
    type sub_c                is array(1 to 33 ) of std_logic_vector(127 downto 0);

    ----------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------
    constant SBOX_ARRAY     : linear_array := (x"fc", x"ee", x"dd", x"11", x"cf", x"6e", x"31", x"16", x"fb", x"c4", x"fa", x"da", x"23", x"c5", x"04", x"4d", x"e9", x"77", x"f0", x"db", x"93", x"2e", x"99", x"ba", x"17", x"36", x"f1", x"bb", x"14", x"cd", x"5f", x"c1", x"f9", x"18", x"65", x"5a", x"e2", x"5c", x"ef", x"21", x"81", x"1c", x"3c", x"42", x"8b", x"01", x"8e", x"4f", x"05", x"84", x"02", x"ae", x"e3", x"6a", x"8f", x"a0", x"06", x"0b", x"ed", x"98", x"7f", x"d4", x"d3", x"1f", x"eb", x"34", x"2c", x"51", x"ea", x"c8", x"48", x"ab", x"f2", x"2a", x"68", x"a2", x"fd", x"3a", x"ce", x"cc", x"b5", x"70", x"0e", x"56", x"08", x"0c", x"76", x"12", x"bf", x"72", x"13", x"47", x"9c", x"b7", x"5d", x"87", x"15", x"a1", x"96", x"29", x"10", x"7b", x"9a", x"c7", x"f3", x"91", x"78", x"6f", x"9d", x"9e", x"b2", x"b1", x"32", x"75", x"19", x"3d", x"ff", x"35", x"8a", x"7e", x"6d", x"54", x"c6", x"80", x"c3", x"bd", x"0d", x"57", x"df", x"f5", x"24", x"a9", x"3e", x"a8", x"43", x"c9", x"d7", x"79", x"d6", x"f6", x"7c", x"22", x"b9", x"03", x"e0", x"0f", x"ec", x"de", x"7a", x"94", x"b0", x"bc", x"dc", x"e8", x"28", x"50", x"4e", x"33", x"0a", x"4a", x"a7", x"97", x"60", x"73", x"1e", x"00", x"62", x"44", x"1a", x"b8", x"38", x"82", x"64", x"9f", x"26", x"41", x"ad", x"45", x"46", x"92", x"27", x"5e", x"55", x"2f", x"8c", x"a3", x"a5", x"7d", x"69", x"d5", x"95", x"3b", x"07", x"58", x"b3", x"40", x"86", x"ac", x"1d", x"f7", x"30", x"37", x"6b", x"e4", x"88", x"d9", x"e7", x"89", x"e1", x"1b", x"83", x"49", x"4c", x"3f", x"f8", x"fe", x"8d", x"53", x"aa", x"90", x"ca", x"d8", x"85", x"61", x"20", x"71", x"67", x"a4", x"2d", x"2b", x"09", x"5b", x"cb", x"9b", x"25", x"d0", x"be", x"e5", x"6c", x"52", x"59", x"a6", x"74", x"d2", x"e6", x"f4", x"b4", x"c0", x"d1", x"66", x"af", x"c2", x"39", x"4b", x"63", x"b6");
    constant INV_SBOX_ARRAY : linear_array := (x"a5", x"2d", x"32", x"8f", x"0e", x"30", x"38", x"c0", x"54", x"e6", x"9e", x"39", x"55", x"7e", x"52", x"91", x"64", x"03", x"57", x"5a", x"1c", x"60", x"07", x"18", x"21", x"72", x"a8", x"d1", x"29", x"c6", x"a4", x"3f", x"e0", x"27", x"8d", x"0c", x"82", x"ea", x"ae", x"b4", x"9a", x"63", x"49", x"e5", x"42", x"e4", x"15", x"b7", x"c8", x"06", x"70", x"9d", x"41", x"75", x"19", x"c9", x"aa", x"fc", x"4d", x"bf", x"2a", x"73", x"84", x"d5", x"c3", x"af", x"2b", x"86", x"a7", x"b1", x"b2", x"5b", x"46", x"d3", x"9f", x"fd", x"d4", x"0f", x"9c", x"2f", x"9b", x"43", x"ef", x"d9", x"79", x"b6", x"53", x"7f", x"c1", x"f0", x"23", x"e7", x"25", x"5e", x"b5", x"1e", x"a2", x"df", x"a6", x"fe", x"ac", x"22", x"f9", x"e2", x"4a", x"bc", x"35", x"ca", x"ee", x"78", x"05", x"6b", x"51", x"e1", x"59", x"a3", x"f2", x"71", x"56", x"11", x"6a", x"89", x"94", x"65", x"8c", x"bb", x"77", x"3c", x"7b", x"28", x"ab", x"d2", x"31", x"de", x"c4", x"5f", x"cc", x"cf", x"76", x"2c", x"b8", x"d8", x"2e", x"36", x"db", x"69", x"b3", x"14", x"95", x"be", x"62", x"a1", x"3b", x"16", x"66", x"e9", x"5c", x"6c", x"6d", x"ad", x"37", x"61", x"4b", x"b9", x"e3", x"ba", x"f1", x"a0", x"85", x"83", x"da", x"47", x"c5", x"b0", x"33", x"fa", x"96", x"6f", x"6e", x"c2", x"f6", x"50", x"ff", x"5d", x"a9", x"8e", x"17", x"1b", x"97", x"7d", x"ec", x"58", x"f7", x"1f", x"fb", x"7c", x"09", x"0d", x"7a", x"67", x"45", x"87", x"dc", x"e8", x"4f", x"1d", x"4e", x"04", x"eb", x"f8", x"f3", x"3e", x"3d", x"bd", x"8a", x"88", x"dd", x"cd", x"0b", x"13", x"98", x"02", x"93", x"80", x"90", x"d0", x"24", x"34", x"cb", x"ed", x"f4", x"ce", x"99", x"10", x"44", x"40", x"92", x"3a", x"01", x"26", x"12", x"1a", x"48", x"68", x"f5", x"81", x"8b", x"c7", x"d6", x"20", x"0a", x"08", x"00", x"4c", x"d7", x"74");
    
    -- following arrays are the results of finite field multiplication by the numbers required in the R step
    constant L_ARRAY_2 : linear_array := (x"00", x"10", x"20", x"30", x"40", x"50", x"60", x"70", x"80", x"90", x"a0", x"b0", x"c0", x"d0", x"e0", x"f0", x"c3", x"d3", x"e3", x"f3", x"83", x"93", x"a3", x"b3", x"43", x"53", x"63", x"73", x"03", x"13", x"23", x"33", x"45", x"55", x"65", x"75", x"05", x"15", x"25", x"35", x"c5", x"d5", x"e5", x"f5", x"85", x"95", x"a5", x"b5", x"86", x"96", x"a6", x"b6", x"c6", x"d6", x"e6", x"f6", x"06", x"16", x"26", x"36", x"46", x"56", x"66", x"76", x"8a", x"9a", x"aa", x"ba", x"ca", x"da", x"ea", x"fa", x"0a", x"1a", x"2a", x"3a", x"4a", x"5a", x"6a", x"7a", x"49", x"59", x"69", x"79", x"09", x"19", x"29", x"39", x"c9", x"d9", x"e9", x"f9", x"89", x"99", x"a9", x"b9", x"cf", x"df", x"ef", x"ff", x"8f", x"9f", x"af", x"bf", x"4f", x"5f", x"6f", x"7f", x"0f", x"1f", x"2f", x"3f", x"0c", x"1c", x"2c", x"3c", x"4c", x"5c", x"6c", x"7c", x"8c", x"9c", x"ac", x"bc", x"cc", x"dc", x"ec", x"fc", x"d7", x"c7", x"f7", x"e7", x"97", x"87", x"b7", x"a7", x"57", x"47", x"77", x"67", x"17", x"07", x"37", x"27", x"14", x"04", x"34", x"24", x"54", x"44", x"74", x"64", x"94", x"84", x"b4", x"a4", x"d4", x"c4", x"f4", x"e4", x"92", x"82", x"b2", x"a2", x"d2", x"c2", x"f2", x"e2", x"12", x"02", x"32", x"22", x"52", x"42", x"72", x"62", x"51", x"41", x"71", x"61", x"11", x"01", x"31", x"21", x"d1", x"c1", x"f1", x"e1", x"91", x"81", x"b1", x"a1", x"5d", x"4d", x"7d", x"6d", x"1d", x"0d", x"3d", x"2d", x"dd", x"cd", x"fd", x"ed", x"9d", x"8d", x"bd", x"ad", x"9e", x"8e", x"be", x"ae", x"de", x"ce", x"fe", x"ee", x"1e", x"0e", x"3e", x"2e", x"5e", x"4e", x"7e", x"6e", x"18", x"08", x"38", x"28", x"58", x"48", x"78", x"68", x"98", x"88", x"b8", x"a8", x"d8", x"c8", x"f8", x"e8", x"db", x"cb", x"fb", x"eb", x"9b", x"8b", x"bb", x"ab", x"5b", x"4b", x"7b", x"6b", x"1b", x"0b", x"3b", x"2b");
    constant L_ARRAY_3 : linear_array := (x"00", x"20", x"40", x"60", x"80", x"a0", x"c0", x"e0", x"c3", x"e3", x"83", x"a3", x"43", x"63", x"03", x"23", x"45", x"65", x"05", x"25", x"c5", x"e5", x"85", x"a5", x"86", x"a6", x"c6", x"e6", x"06", x"26", x"46", x"66", x"8a", x"aa", x"ca", x"ea", x"0a", x"2a", x"4a", x"6a", x"49", x"69", x"09", x"29", x"c9", x"e9", x"89", x"a9", x"cf", x"ef", x"8f", x"af", x"4f", x"6f", x"0f", x"2f", x"0c", x"2c", x"4c", x"6c", x"8c", x"ac", x"cc", x"ec", x"d7", x"f7", x"97", x"b7", x"57", x"77", x"17", x"37", x"14", x"34", x"54", x"74", x"94", x"b4", x"d4", x"f4", x"92", x"b2", x"d2", x"f2", x"12", x"32", x"52", x"72", x"51", x"71", x"11", x"31", x"d1", x"f1", x"91", x"b1", x"5d", x"7d", x"1d", x"3d", x"dd", x"fd", x"9d", x"bd", x"9e", x"be", x"de", x"fe", x"1e", x"3e", x"5e", x"7e", x"18", x"38", x"58", x"78", x"98", x"b8", x"d8", x"f8", x"db", x"fb", x"9b", x"bb", x"5b", x"7b", x"1b", x"3b", x"6d", x"4d", x"2d", x"0d", x"ed", x"cd", x"ad", x"8d", x"ae", x"8e", x"ee", x"ce", x"2e", x"0e", x"6e", x"4e", x"28", x"08", x"68", x"48", x"a8", x"88", x"e8", x"c8", x"eb", x"cb", x"ab", x"8b", x"6b", x"4b", x"2b", x"0b", x"e7", x"c7", x"a7", x"87", x"67", x"47", x"27", x"07", x"24", x"04", x"64", x"44", x"a4", x"84", x"e4", x"c4", x"a2", x"82", x"e2", x"c2", x"22", x"02", x"62", x"42", x"61", x"41", x"21", x"01", x"e1", x"c1", x"a1", x"81", x"ba", x"9a", x"fa", x"da", x"3a", x"1a", x"7a", x"5a", x"79", x"59", x"39", x"19", x"f9", x"d9", x"b9", x"99", x"ff", x"df", x"bf", x"9f", x"7f", x"5f", x"3f", x"1f", x"3c", x"1c", x"7c", x"5c", x"bc", x"9c", x"fc", x"dc", x"30", x"10", x"70", x"50", x"b0", x"90", x"f0", x"d0", x"f3", x"d3", x"b3", x"93", x"73", x"53", x"33", x"13", x"75", x"55", x"35", x"15", x"f5", x"d5", x"b5", x"95", x"b6", x"96", x"f6", x"d6", x"36", x"16", x"76", x"56");
    constant L_ARRAY_4 : linear_array := (x"00", x"85", x"c9", x"4c", x"51", x"d4", x"98", x"1d", x"a2", x"27", x"6b", x"ee", x"f3", x"76", x"3a", x"bf", x"87", x"02", x"4e", x"cb", x"d6", x"53", x"1f", x"9a", x"25", x"a0", x"ec", x"69", x"74", x"f1", x"bd", x"38", x"cd", x"48", x"04", x"81", x"9c", x"19", x"55", x"d0", x"6f", x"ea", x"a6", x"23", x"3e", x"bb", x"f7", x"72", x"4a", x"cf", x"83", x"06", x"1b", x"9e", x"d2", x"57", x"e8", x"6d", x"21", x"a4", x"b9", x"3c", x"70", x"f5", x"59", x"dc", x"90", x"15", x"08", x"8d", x"c1", x"44", x"fb", x"7e", x"32", x"b7", x"aa", x"2f", x"63", x"e6", x"de", x"5b", x"17", x"92", x"8f", x"0a", x"46", x"c3", x"7c", x"f9", x"b5", x"30", x"2d", x"a8", x"e4", x"61", x"94", x"11", x"5d", x"d8", x"c5", x"40", x"0c", x"89", x"36", x"b3", x"ff", x"7a", x"67", x"e2", x"ae", x"2b", x"13", x"96", x"da", x"5f", x"42", x"c7", x"8b", x"0e", x"b1", x"34", x"78", x"fd", x"e0", x"65", x"29", x"ac", x"b2", x"37", x"7b", x"fe", x"e3", x"66", x"2a", x"af", x"10", x"95", x"d9", x"5c", x"41", x"c4", x"88", x"0d", x"35", x"b0", x"fc", x"79", x"64", x"e1", x"ad", x"28", x"97", x"12", x"5e", x"db", x"c6", x"43", x"0f", x"8a", x"7f", x"fa", x"b6", x"33", x"2e", x"ab", x"e7", x"62", x"dd", x"58", x"14", x"91", x"8c", x"09", x"45", x"c0", x"f8", x"7d", x"31", x"b4", x"a9", x"2c", x"60", x"e5", x"5a", x"df", x"93", x"16", x"0b", x"8e", x"c2", x"47", x"eb", x"6e", x"22", x"a7", x"ba", x"3f", x"73", x"f6", x"49", x"cc", x"80", x"05", x"18", x"9d", x"d1", x"54", x"6c", x"e9", x"a5", x"20", x"3d", x"b8", x"f4", x"71", x"ce", x"4b", x"07", x"82", x"9f", x"1a", x"56", x"d3", x"26", x"a3", x"ef", x"6a", x"77", x"f2", x"be", x"3b", x"84", x"01", x"4d", x"c8", x"d5", x"50", x"1c", x"99", x"a1", x"24", x"68", x"ed", x"f0", x"75", x"39", x"bc", x"03", x"86", x"ca", x"4f", x"52", x"d7", x"9b", x"1e");
    constant L_ARRAY_5 : linear_array := (x"00", x"94", x"eb", x"7f", x"15", x"81", x"fe", x"6a", x"2a", x"be", x"c1", x"55", x"3f", x"ab", x"d4", x"40", x"54", x"c0", x"bf", x"2b", x"41", x"d5", x"aa", x"3e", x"7e", x"ea", x"95", x"01", x"6b", x"ff", x"80", x"14", x"a8", x"3c", x"43", x"d7", x"bd", x"29", x"56", x"c2", x"82", x"16", x"69", x"fd", x"97", x"03", x"7c", x"e8", x"fc", x"68", x"17", x"83", x"e9", x"7d", x"02", x"96", x"d6", x"42", x"3d", x"a9", x"c3", x"57", x"28", x"bc", x"93", x"07", x"78", x"ec", x"86", x"12", x"6d", x"f9", x"b9", x"2d", x"52", x"c6", x"ac", x"38", x"47", x"d3", x"c7", x"53", x"2c", x"b8", x"d2", x"46", x"39", x"ad", x"ed", x"79", x"06", x"92", x"f8", x"6c", x"13", x"87", x"3b", x"af", x"d0", x"44", x"2e", x"ba", x"c5", x"51", x"11", x"85", x"fa", x"6e", x"04", x"90", x"ef", x"7b", x"6f", x"fb", x"84", x"10", x"7a", x"ee", x"91", x"05", x"45", x"d1", x"ae", x"3a", x"50", x"c4", x"bb", x"2f", x"e5", x"71", x"0e", x"9a", x"f0", x"64", x"1b", x"8f", x"cf", x"5b", x"24", x"b0", x"da", x"4e", x"31", x"a5", x"b1", x"25", x"5a", x"ce", x"a4", x"30", x"4f", x"db", x"9b", x"0f", x"70", x"e4", x"8e", x"1a", x"65", x"f1", x"4d", x"d9", x"a6", x"32", x"58", x"cc", x"b3", x"27", x"67", x"f3", x"8c", x"18", x"72", x"e6", x"99", x"0d", x"19", x"8d", x"f2", x"66", x"0c", x"98", x"e7", x"73", x"33", x"a7", x"d8", x"4c", x"26", x"b2", x"cd", x"59", x"76", x"e2", x"9d", x"09", x"63", x"f7", x"88", x"1c", x"5c", x"c8", x"b7", x"23", x"49", x"dd", x"a2", x"36", x"22", x"b6", x"c9", x"5d", x"37", x"a3", x"dc", x"48", x"08", x"9c", x"e3", x"77", x"1d", x"89", x"f6", x"62", x"de", x"4a", x"35", x"a1", x"cb", x"5f", x"20", x"b4", x"f4", x"60", x"1f", x"8b", x"e1", x"75", x"0a", x"9e", x"8a", x"1e", x"61", x"f5", x"9f", x"0b", x"74", x"e0", x"a0", x"34", x"4b", x"df", x"b5", x"21", x"5e", x"ca");
    constant L_ARRAY_6 : linear_array := (x"00", x"c0", x"43", x"83", x"86", x"46", x"c5", x"05", x"cf", x"0f", x"8c", x"4c", x"49", x"89", x"0a", x"ca", x"5d", x"9d", x"1e", x"de", x"db", x"1b", x"98", x"58", x"92", x"52", x"d1", x"11", x"14", x"d4", x"57", x"97", x"ba", x"7a", x"f9", x"39", x"3c", x"fc", x"7f", x"bf", x"75", x"b5", x"36", x"f6", x"f3", x"33", x"b0", x"70", x"e7", x"27", x"a4", x"64", x"61", x"a1", x"22", x"e2", x"28", x"e8", x"6b", x"ab", x"ae", x"6e", x"ed", x"2d", x"b7", x"77", x"f4", x"34", x"31", x"f1", x"72", x"b2", x"78", x"b8", x"3b", x"fb", x"fe", x"3e", x"bd", x"7d", x"ea", x"2a", x"a9", x"69", x"6c", x"ac", x"2f", x"ef", x"25", x"e5", x"66", x"a6", x"a3", x"63", x"e0", x"20", x"0d", x"cd", x"4e", x"8e", x"8b", x"4b", x"c8", x"08", x"c2", x"02", x"81", x"41", x"44", x"84", x"07", x"c7", x"50", x"90", x"13", x"d3", x"d6", x"16", x"95", x"55", x"9f", x"5f", x"dc", x"1c", x"19", x"d9", x"5a", x"9a", x"ad", x"6d", x"ee", x"2e", x"2b", x"eb", x"68", x"a8", x"62", x"a2", x"21", x"e1", x"e4", x"24", x"a7", x"67", x"f0", x"30", x"b3", x"73", x"76", x"b6", x"35", x"f5", x"3f", x"ff", x"7c", x"bc", x"b9", x"79", x"fa", x"3a", x"17", x"d7", x"54", x"94", x"91", x"51", x"d2", x"12", x"d8", x"18", x"9b", x"5b", x"5e", x"9e", x"1d", x"dd", x"4a", x"8a", x"09", x"c9", x"cc", x"0c", x"8f", x"4f", x"85", x"45", x"c6", x"06", x"03", x"c3", x"40", x"80", x"1a", x"da", x"59", x"99", x"9c", x"5c", x"df", x"1f", x"d5", x"15", x"96", x"56", x"53", x"93", x"10", x"d0", x"47", x"87", x"04", x"c4", x"c1", x"01", x"82", x"42", x"88", x"48", x"cb", x"0b", x"0e", x"ce", x"4d", x"8d", x"a0", x"60", x"e3", x"23", x"26", x"e6", x"65", x"a5", x"6f", x"af", x"2c", x"ec", x"e9", x"29", x"aa", x"6a", x"fd", x"3d", x"be", x"7e", x"7b", x"bb", x"38", x"f8", x"32", x"f2", x"71", x"b1", x"b4", x"74", x"f7", x"37");
    constant L_ARRAY_7 : linear_array := (x"00", x"c2", x"47", x"85", x"8e", x"4c", x"c9", x"0b", x"df", x"1d", x"98", x"5a", x"51", x"93", x"16", x"d4", x"7d", x"bf", x"3a", x"f8", x"f3", x"31", x"b4", x"76", x"a2", x"60", x"e5", x"27", x"2c", x"ee", x"6b", x"a9", x"fa", x"38", x"bd", x"7f", x"74", x"b6", x"33", x"f1", x"25", x"e7", x"62", x"a0", x"ab", x"69", x"ec", x"2e", x"87", x"45", x"c0", x"02", x"09", x"cb", x"4e", x"8c", x"58", x"9a", x"1f", x"dd", x"d6", x"14", x"91", x"53", x"37", x"f5", x"70", x"b2", x"b9", x"7b", x"fe", x"3c", x"e8", x"2a", x"af", x"6d", x"66", x"a4", x"21", x"e3", x"4a", x"88", x"0d", x"cf", x"c4", x"06", x"83", x"41", x"95", x"57", x"d2", x"10", x"1b", x"d9", x"5c", x"9e", x"cd", x"0f", x"8a", x"48", x"43", x"81", x"04", x"c6", x"12", x"d0", x"55", x"97", x"9c", x"5e", x"db", x"19", x"b0", x"72", x"f7", x"35", x"3e", x"fc", x"79", x"bb", x"6f", x"ad", x"28", x"ea", x"e1", x"23", x"a6", x"64", x"6e", x"ac", x"29", x"eb", x"e0", x"22", x"a7", x"65", x"b1", x"73", x"f6", x"34", x"3f", x"fd", x"78", x"ba", x"13", x"d1", x"54", x"96", x"9d", x"5f", x"da", x"18", x"cc", x"0e", x"8b", x"49", x"42", x"80", x"05", x"c7", x"94", x"56", x"d3", x"11", x"1a", x"d8", x"5d", x"9f", x"4b", x"89", x"0c", x"ce", x"c5", x"07", x"82", x"40", x"e9", x"2b", x"ae", x"6c", x"67", x"a5", x"20", x"e2", x"36", x"f4", x"71", x"b3", x"b8", x"7a", x"ff", x"3d", x"59", x"9b", x"1e", x"dc", x"d7", x"15", x"90", x"52", x"86", x"44", x"c1", x"03", x"08", x"ca", x"4f", x"8d", x"24", x"e6", x"63", x"a1", x"aa", x"68", x"ed", x"2f", x"fb", x"39", x"bc", x"7e", x"75", x"b7", x"32", x"f0", x"a3", x"61", x"e4", x"26", x"2d", x"ef", x"6a", x"a8", x"7c", x"be", x"3b", x"f9", x"f2", x"30", x"b5", x"77", x"de", x"1c", x"99", x"5b", x"50", x"92", x"17", x"d5", x"01", x"c3", x"46", x"84", x"8f", x"4d", x"c8", x"0a");
    constant L_ARRAY_8 : linear_array := (x"00", x"fb", x"35", x"ce", x"6a", x"91", x"5f", x"a4", x"d4", x"2f", x"e1", x"1a", x"be", x"45", x"8b", x"70", x"6b", x"90", x"5e", x"a5", x"01", x"fa", x"34", x"cf", x"bf", x"44", x"8a", x"71", x"d5", x"2e", x"e0", x"1b", x"d6", x"2d", x"e3", x"18", x"bc", x"47", x"89", x"72", x"02", x"f9", x"37", x"cc", x"68", x"93", x"5d", x"a6", x"bd", x"46", x"88", x"73", x"d7", x"2c", x"e2", x"19", x"69", x"92", x"5c", x"a7", x"03", x"f8", x"36", x"cd", x"6f", x"94", x"5a", x"a1", x"05", x"fe", x"30", x"cb", x"bb", x"40", x"8e", x"75", x"d1", x"2a", x"e4", x"1f", x"04", x"ff", x"31", x"ca", x"6e", x"95", x"5b", x"a0", x"d0", x"2b", x"e5", x"1e", x"ba", x"41", x"8f", x"74", x"b9", x"42", x"8c", x"77", x"d3", x"28", x"e6", x"1d", x"6d", x"96", x"58", x"a3", x"07", x"fc", x"32", x"c9", x"d2", x"29", x"e7", x"1c", x"b8", x"43", x"8d", x"76", x"06", x"fd", x"33", x"c8", x"6c", x"97", x"59", x"a2", x"de", x"25", x"eb", x"10", x"b4", x"4f", x"81", x"7a", x"0a", x"f1", x"3f", x"c4", x"60", x"9b", x"55", x"ae", x"b5", x"4e", x"80", x"7b", x"df", x"24", x"ea", x"11", x"61", x"9a", x"54", x"af", x"0b", x"f0", x"3e", x"c5", x"08", x"f3", x"3d", x"c6", x"62", x"99", x"57", x"ac", x"dc", x"27", x"e9", x"12", x"b6", x"4d", x"83", x"78", x"63", x"98", x"56", x"ad", x"09", x"f2", x"3c", x"c7", x"b7", x"4c", x"82", x"79", x"dd", x"26", x"e8", x"13", x"b1", x"4a", x"84", x"7f", x"db", x"20", x"ee", x"15", x"65", x"9e", x"50", x"ab", x"0f", x"f4", x"3a", x"c1", x"da", x"21", x"ef", x"14", x"b0", x"4b", x"85", x"7e", x"0e", x"f5", x"3b", x"c0", x"64", x"9f", x"51", x"aa", x"67", x"9c", x"52", x"a9", x"0d", x"f6", x"38", x"c3", x"b3", x"48", x"86", x"7d", x"d9", x"22", x"ec", x"17", x"0c", x"f7", x"39", x"c2", x"66", x"9d", x"53", x"a8", x"d8", x"23", x"ed", x"16", x"b2", x"49", x"87", x"7c");

    --constant numbers used in sub key schedule
    constant SUB_KEYS_CI : sub_c := (x"6ea276726c487ab85d27bd10dd849401", x"dc87ece4d890f4b3ba4eb92079cbeb02", x"b2259a96b4d88e0be7690430a44f7f03", x"7bcd1b0b73e32ba5b79cb140f2551504", x"156f6d791fab511deabb0c502fd18105", x"a74af7efab73df160dd208608b9efe06", x"c9e8819dc73ba5ae50f5b570561a6a07", x"f6593616e6055689adfba18027aa2a08", x"98fb40648a4d2c31f0dc1c90fa2ebe09", x"2adedaf23e95a23a17b518a05e61c10a", x"447cac8052ddd8824a92a5b083e5550b", x"8d942d1d95e67d2c1a6710c0d5ff3f0c", x"e3365b6ff9ae07944740add0087bab0d", x"5113c1f94d76899fa029a9e0ac34d40e", x"3fb1b78b213ef327fd0e14f071b0400f", x"2fb26c2c0f0aacd1993581c34e975410", x"41101a5e6342d669c4123cd39313c011", x"f33580c8d79a5862237b38e3375cbf12", x"9d97f6babbd222da7e5c85f3ead82b13", x"547f77277ce987742ea93083bcc24114", x"3add015510a1fdcc738e8d936146d515", x"88f89bc3a47973c794e789a3c509aa16", x"e65aedb1c831097fc9c034b3188d3e17", x"d9eb5a3ae90ffa5834ce2043693d7e18", x"b7492c48854780e069e99d53b4b9ea19", x"056cb6de319f0eeb8e80996310f6951a", x"6bcec0ac5dd77453d3a72473cd72011b", x"a22641319aecd1fd835291039b686b1c", x"cc843743f6a4ab45de752c1346ecff1d", x"7ea1add5427c254e391c2823e2a3801e", x"1003dba72e345ff6643b95333f27141f", x"5ea7d8581e149b61f16ac1459ceda820", x"00000000000000000000000000000000");

    ----------------------------------------------------------------
    -- Functions declarations for encryption
    ----------------------------------------------------------------  
    -- sBox applied to the whole state
    function sStep( s_inp : std_logic_vector(127 downto 0)) return std_logic_vector;   
    -- R-step of the algorithm -> linear transformation
    function rStep( r_inp : std_logic_vector(127 downto 0)) return std_logic_vector;
    --L-step of the algorithm -> R-step applied 16 times
    function lStep( l_inp : std_logic_vector(127 downto 0)) return std_logic_vector;    
    --Add Round Key
    function ARK(ark_in, ark_key : std_logic_vector(127 downto 0)) return std_logic_vector;

    ----------------------------------------------------------------
    -- Functions declarations for key scheduling
    ----------------------------------------------------------------        
    --Intermediate step for Sub-Key procedure             
    function fStep( a1,a0,f_key : in  std_logic_vector (127 downto 0)) return tuple;
        
    ----------------------------------------------------------------
    -- Functions declarations for decryption
    ----------------------------------------------------------------
    --inverse S-Step (inverse sBox applied to the whole state)
    function inv_sStep( inv_s_inp : std_logic_vector(127 downto 0)) return std_logic_vector;
    --inverse R-Step of the algorithm
    function inv_rStep( inv_r_inp : std_logic_vector(127 downto 0)) return std_logic_vector;
    --inverse L-Step of the algorithm
    function inv_lStep( inv_l_inp : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    ----------------------------------------------------------------
    -- ENCRYPTION
    ----------------------------------------------------------------
    
    function round (state, k : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function inv_round(state, k : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    ----------------------------------------------------------------
    -- Methods for masked encryption
    ----------------------------------------------------------------
    function masked_sbox(s, m : std_logic_vector(7 downto 0)) return std_logic_vector;
    
    function masked_sStep(state, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function masked_round(state, k, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    ----------------------------------------------------------------
    -- Methods for masked decryption
    ----------------------------------------------------------------    
    function inv_masked_sbox(s, m : std_logic_vector(7 downto 0)) return std_logic_vector;
    
    function inv_masked_sstep(state, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function inv_masked_round(state, k, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    

end grasshopper_pkg;

package body grasshopper_pkg is

    -- Non linear permutation

    function sStep(s_inp : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable s_out :std_logic_vector(127 downto 0);
    begin
        s_out(127 downto 120) := SBOX_ARRAY(to_integer(unsigned(s_inp(127 downto 120))));
        s_out(119 downto 112) := SBOX_ARRAY(to_integer(unsigned(s_inp(119 downto 112))));
        s_out(111 downto 104) := SBOX_ARRAY(to_integer(unsigned(s_inp(111 downto 104))));
        s_out(103 downto 96 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(103 downto 96 ))));
        s_out(95  downto 88 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(95  downto 88 ))));
        s_out(87  downto 80 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(87  downto 80 ))));
        s_out(79  downto 72 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(79  downto 72 ))));
        s_out(71  downto 64 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(71  downto 64 ))));
        s_out(63  downto 56 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(63  downto 56 ))));
        s_out(55  downto 48 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(55  downto 48 ))));
        s_out(47  downto 40 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(47  downto 40 ))));
        s_out(39  downto 32 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(39  downto 32 ))));
        s_out(31  downto 24 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(31  downto 24 ))));
        s_out(23  downto 16 ) := SBOX_ARRAY(to_integer(unsigned(s_inp(23  downto 16 ))));
        s_out(15  downto 8  ) := SBOX_ARRAY(to_integer(unsigned(s_inp(15  downto 8  ))));
        s_out(7   downto 0  ) := SBOX_ARRAY(to_integer(unsigned(s_inp(7   downto 0  ))));
        return s_out;
    end function sStep;
    
    -- linear function l
    
    function rStep(r_inp : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable r_out : std_logic_vector(127 downto 0);
    begin
        r_out(127 downto 120) := L_ARRAY_5(to_integer(unsigned(r_inp(127 downto 120)))) xor L_ARRAY_3(to_integer(unsigned(r_inp(119 downto 112)))) xor L_ARRAY_4(to_integer(unsigned(r_inp(111 downto 104)))) xor L_ARRAY_2(to_integer(unsigned(r_inp(103 downto 96 )))) xor L_ARRAY_7(to_integer(unsigned(r_inp(95  downto 88 )))) xor L_ARRAY_6(to_integer(unsigned(r_inp(87  downto 80 )))) xor r_inp(79  downto 72 ) xor L_ARRAY_8(to_integer(unsigned(r_inp(71  downto 64 )))) xor r_inp(63  downto 56 ) xor L_ARRAY_6(to_integer(unsigned(r_inp(55  downto 48 )))) xor L_ARRAY_7(to_integer(unsigned(r_inp(47  downto 40 )))) xor L_ARRAY_2(to_integer(unsigned(r_inp(39  downto 32 )))) xor L_ARRAY_4(to_integer(unsigned(r_inp(31  downto 24 )))) xor L_ARRAY_3(to_integer(unsigned(r_inp(23  downto 16 )))) xor L_ARRAY_5(to_integer(unsigned(r_inp(15  downto 8  )))) xor r_inp(7   downto 0  );
            
        r_out(119 downto 0  ) := r_inp(127 downto 8);
        return r_out;
    end function rStep;
    
    -- linear permutation
    
    function lStep( l_inp : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable l_out       : std_logic_vector(127 downto 0);
        variable l_inter     : std_logic_vector(127 downto 0);
    begin
        l_inter := rStep(l_inp);
        for i in 2 to 15 loop
            l_inter := rStep(l_inter);
        end loop;       
        l_out := rStep(l_inter);
        return l_out;
    end function lStep;
    
    -- add round key
    
    function ARK(ark_in, ark_key : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable ark_out : std_logic_vector(127 downto 0);
    begin
        ark_out := ark_in xor ark_key;
        return ark_out;
    end function ARK;
    
    --f step, used for SKS
    
    function fStep(a1,a0,f_key : in  std_logic_vector(127 downto 0))
        return tuple is
        variable f_output    : tuple;
        variable f_inter     : std_logic_vector(127 downto 0);
    begin
        --first assignement is quite easy
        f_output(1) := a1;
        
        --second assignement requires a call to Lstep, Sstep and AddRoundKey
        f_inter := ARK(a1,f_key);
        f_inter := sStep(f_inter);
        f_output(0) := lStep(f_inter) xor a0;
        
        return f_output;
    end fStep;
    
    -- Inverse functions, for decryption
                    
    function inv_sStep(inv_s_inp : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable inv_s_out :std_logic_vector(127 downto 0);
    begin
        inv_s_out(127 downto 120) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(127 downto 120))));
        inv_s_out(119 downto 112) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(119 downto 112))));
        inv_s_out(111 downto 104) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(111 downto 104))));
        inv_s_out(103 downto 96 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(103 downto 96 ))));
        inv_s_out(95  downto 88 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(95  downto 88 ))));
        inv_s_out(87  downto 80 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(87  downto 80 ))));
        inv_s_out(79  downto 72 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(79  downto 72 ))));
        inv_s_out(71  downto 64 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(71  downto 64 ))));
        inv_s_out(63  downto 56 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(63  downto 56 ))));
        inv_s_out(55  downto 48 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(55  downto 48 ))));
        inv_s_out(47  downto 40 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(47  downto 40 ))));
        inv_s_out(39  downto 32 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(39  downto 32 ))));
        inv_s_out(31  downto 24 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(31  downto 24 ))));
        inv_s_out(23  downto 16 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(23  downto 16 ))));
        inv_s_out(15  downto 8  ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(15  downto 8  ))));
        inv_s_out(7   downto 0  ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_s_inp(7   downto 0  ))));
        return inv_s_out;
    end function inv_sStep;
    
    function inv_rStep(inv_r_inp : std_logic_vector(127downto 0))
        return std_logic_vector is
        variable inv_r_out : std_logic_vector(127 downto 0);
    begin
        inv_r_out(7 downto 0) :=  L_ARRAY_5(to_integer(unsigned(inv_r_inp(119 downto 112))))  xor  L_ARRAY_3(to_integer(unsigned(inv_r_inp(111 downto 104))))  xor  L_ARRAY_4(to_integer(unsigned(inv_r_inp(103 downto 96))))  xor  L_ARRAY_2(to_integer(unsigned(inv_r_inp(95  downto 88 ))))  xor  L_ARRAY_7(to_integer(unsigned(inv_r_inp(87  downto 80 ))))  xor  L_ARRAY_6(to_integer(unsigned(inv_r_inp(79  downto 72 ))))  xor  inv_r_inp(71  downto 64 )  xor  L_ARRAY_8(to_integer(unsigned(inv_r_inp(63  downto 56 ))))  xor  inv_r_inp(55  downto 48 )  xor  L_ARRAY_6(to_integer(unsigned(inv_r_inp(47  downto 40 ))))  xor  L_ARRAY_7(to_integer(unsigned(inv_r_inp(39  downto 32 ))))  xor  L_ARRAY_2(to_integer(unsigned(inv_r_inp(31  downto 24 ))))  xor  L_ARRAY_4(to_integer(unsigned(inv_r_inp(23  downto 16 ))))  xor  L_ARRAY_3(to_integer(unsigned(inv_r_inp(15  downto 8  ))))  xor  L_ARRAY_5(to_integer(unsigned(inv_r_inp(7   downto 0  ))))  xor  inv_r_inp(127 downto 120) ;
        inv_r_out(127 downto 8) := inv_r_inp(119 downto 0);
        return inv_r_out;
    end function inv_rStep;
    
    function inv_lStep( inv_l_inp : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable inv_l_out   : std_logic_vector(127 downto 0);
        variable l_inter     : std_logic_vector(127 downto 0);
    begin
        l_inter := inv_rStep(inv_l_inp);
        for i in 2 to 15 loop
            l_inter := inv_rStep(l_inter);
        end loop;
        inv_l_out := inv_rStep(l_inter);
        return inv_l_out;
    end function inv_lStep;
    
    function round (state, k : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable state_out : std_logic_vector(127 downto 0);
    begin
    
        state_out := ARK(state,k);
        state_out := sStep(state_out);
        state_out := lStep(state_out);
        
        return state_out;
    end function round;
    
    function inv_round(state, k : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable state_out : std_logic_vector(127 downto 0);
    begin
        
        state_out := ARK(state, k);
        state_out := inv_lStep(state_out);
        state_out := inv_sStep(state_out);
        
        return state_out;
    
    end function inv_round;
    
    
    function masked_sbox(s,m : std_logic_vector(7 downto 0)) 
            return std_logic_vector is
            variable state_out,inter : std_logic_vector(7 downto 0);
        begin
            inter := s xor m;
            state_out := SBOX_ARRAY(to_integer(unsigned(inter))) xor m;
            
            return state_out;
        end function masked_sbox;
        
        function masked_sStep(state, mask : std_logic_vector(127 downto 0))
            return std_logic_vector is
            variable state_out : std_logic_vector(127 downto 0);
        begin
            for i in 0 to 15 loop
                state_out(8*i+7 downto 8*i) := masked_sBox(state(8*i+7 downto 8*i), mask(8*i+7 downto 8*i));
            end loop;
            return state_out;
        end function masked_sStep;
        
        function masked_round(state, k, mask : std_logic_vector(127 downto 0))     
            return std_logic_vector is
            variable state_out : std_logic_vector(127 downto 0);
        begin
            state_out := ARK(state,k);
            state_out := masked_sStep(state_out, mask);
            state_out := lStep(state_out);
            
            return state_out;
        end function masked_round;
        
        function inv_masked_sbox(s,m : std_logic_vector(7 downto 0))
            return std_logic_vector is
            variable s_out,inter : std_logic_vector(7 downto 0);
        begin
            inter := s xor m;
            s_out := INV_SBOX_ARRAY(to_integer(unsigned(inter))) xor m;
            return s_out;
        end function inv_masked_sbox;
        
        function inv_masked_sstep(state, mask : std_logic_vector(127 downto 0))
            return std_logic_vector is
            variable state_out : std_logic_vector(127 downto 0);
        begin
            for i in 0 to 15 loop
                state_out(8*i+7 downto 8*i) := inv_masked_sBox(state(8*i+7 downto 8*i), mask(8*i+7 downto 8*i));
            end loop;
            return state_out;
        end function inv_masked_sstep;
        
        function inv_masked_round(state, k, mask : std_logic_vector(127 downto 0))
            return std_logic_vector is
            variable state_out, int_m : std_logic_vector(127 downto 0);
        begin
            int_m := inv_lStep(mask);
            state_out := ARK(state, k);
            state_out := inv_lStep(state_out);
            state_out := inv_masked_sstep(state_out, int_m);
            
            return state_out;
        end function inv_masked_round;
           
end package body grasshopper_pkg;
