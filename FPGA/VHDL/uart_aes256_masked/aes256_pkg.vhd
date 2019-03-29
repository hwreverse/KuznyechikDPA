--------------------------------------------------------------------------------------------------
-- File    : aes256_pkg.vhd
-- Author  : Cedric DELAUNAY
-- Date    : September 6th, 2018
--   
-- Summary : Definition of the functions used in AES-256 encryption and decryption algorithms
--------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

package aes256_pkg is 

    ----------------------------------------------------------------
    -- Types
    ----------------------------------------------------------------
    type linear_array is array (0 to 255) of std_logic_vector(7   downto 0);
    type    key_array is array (0 to 59 ) of std_logic_vector(31  downto 0);
    type  rconv_array is array (0 to 15 ) of std_logic_vector(31  downto 0);
    type sub_keys_aes is array (0 to 14 ) of std_logic_vector(127 downto 0);
    type word_array   is array (0 to 59 ) of std_logic_vector(31  downto 0);
    
    ----------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------
    constant SBOX_ARRAY     : linear_array := (x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76", x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0", x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15", x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75", x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84", x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf", x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8", x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2", x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73", x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db", x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79", x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08", x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a", x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e", x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df", x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16");
    constant INV_SBOX_ARRAY : linear_array := (x"52", x"09", x"6a", x"d5", x"30", x"36", x"a5", x"38", x"bf", x"40", x"a3", x"9e", x"81", x"f3", x"d7", x"fb", x"7c", x"e3", x"39", x"82", x"9b", x"2f", x"ff", x"87", x"34", x"8e", x"43", x"44", x"c4", x"de", x"e9", x"cb", x"54", x"7b", x"94", x"32", x"a6", x"c2", x"23", x"3d", x"ee", x"4c", x"95", x"0b", x"42", x"fa", x"c3", x"4e", x"08", x"2e", x"a1", x"66", x"28", x"d9", x"24", x"b2", x"76", x"5b", x"a2", x"49", x"6d", x"8b", x"d1", x"25", x"72", x"f8", x"f6", x"64", x"86", x"68", x"98", x"16", x"d4", x"a4", x"5c", x"cc", x"5d", x"65", x"b6", x"92", x"6c", x"70", x"48", x"50", x"fd", x"ed", x"b9", x"da", x"5e", x"15", x"46", x"57", x"a7", x"8d", x"9d", x"84", x"90", x"d8", x"ab", x"00", x"8c", x"bc", x"d3", x"0a", x"f7", x"e4", x"58", x"05", x"b8", x"b3", x"45", x"06", x"d0", x"2c", x"1e", x"8f", x"ca", x"3f", x"0f", x"02", x"c1", x"af", x"bd", x"03", x"01", x"13", x"8a", x"6b", x"3a", x"91", x"11", x"41", x"4f", x"67", x"dc", x"ea", x"97", x"f2", x"cf", x"ce", x"f0", x"b4", x"e6", x"73", x"96", x"ac", x"74", x"22", x"e7", x"ad", x"35", x"85", x"e2", x"f9", x"37", x"e8", x"1c", x"75", x"df", x"6e", x"47", x"f1", x"1a", x"71", x"1d", x"29", x"c5", x"89", x"6f", x"b7", x"62", x"0e", x"aa", x"18", x"be", x"1b", x"fc", x"56", x"3e", x"4b", x"c6", x"d2", x"79", x"20", x"9a", x"db", x"c0", x"fe", x"78", x"cd", x"5a", x"f4", x"1f", x"dd", x"a8", x"33", x"88", x"07", x"c7", x"31", x"b1", x"12", x"10", x"59", x"27", x"80", x"ec", x"5f", x"60", x"51", x"7f", x"a9", x"19", x"b5", x"4a", x"0d", x"2d", x"e5", x"7a", x"9f", x"93", x"c9", x"9c", x"ef", x"a0", x"e0", x"3b", x"4d", x"ae", x"2a", x"f5", x"b0", x"c8", x"eb", x"bb", x"3c", x"83", x"53", x"99", x"61", x"17", x"2b", x"04", x"7e", x"ba", x"77", x"d6", x"26", x"e1", x"69", x"14", x"63", x"55", x"21", x"0c", x"7d");
    
    -- Arrays used in GF2 multiplications
    constant GF_MULT2       : linear_array := (x"00", x"02", x"04", x"06", x"08", x"0a", x"0c", x"0e", x"10", x"12", x"14", x"16", x"18", x"1a", x"1c", x"1e", x"20", x"22", x"24", x"26", x"28", x"2a", x"2c", x"2e", x"30", x"32", x"34", x"36", x"38", x"3a", x"3c", x"3e", x"40", x"42", x"44", x"46", x"48", x"4a", x"4c", x"4e", x"50", x"52", x"54", x"56", x"58", x"5a", x"5c", x"5e", x"60", x"62", x"64", x"66", x"68", x"6a", x"6c", x"6e", x"70", x"72", x"74", x"76", x"78", x"7a", x"7c", x"7e", x"80", x"82", x"84", x"86", x"88", x"8a", x"8c", x"8e", x"90", x"92", x"94", x"96", x"98", x"9a", x"9c", x"9e", x"a0", x"a2", x"a4", x"a6", x"a8", x"aa", x"ac", x"ae", x"b0", x"b2", x"b4", x"b6", x"b8", x"ba", x"bc", x"be", x"c0", x"c2", x"c4", x"c6", x"c8", x"ca", x"cc", x"ce", x"d0", x"d2", x"d4", x"d6", x"d8", x"da", x"dc", x"de", x"e0", x"e2", x"e4", x"e6", x"e8", x"ea", x"ec", x"ee", x"f0", x"f2", x"f4", x"f6", x"f8", x"fa", x"fc", x"fe", x"1b", x"19", x"1f", x"1d", x"13", x"11", x"17", x"15", x"0b", x"09", x"0f", x"0d", x"03", x"01", x"07", x"05", x"3b", x"39", x"3f", x"3d", x"33", x"31", x"37", x"35", x"2b", x"29", x"2f", x"2d", x"23", x"21", x"27", x"25", x"5b", x"59", x"5f", x"5d", x"53", x"51", x"57", x"55", x"4b", x"49", x"4f", x"4d", x"43", x"41", x"47", x"45", x"7b", x"79", x"7f", x"7d", x"73", x"71", x"77", x"75", x"6b", x"69", x"6f", x"6d", x"63", x"61", x"67", x"65", x"9b", x"99", x"9f", x"9d", x"93", x"91", x"97", x"95", x"8b", x"89", x"8f", x"8d", x"83", x"81", x"87", x"85", x"bb", x"b9", x"bf", x"bd", x"b3", x"b1", x"b7", x"b5", x"ab", x"a9", x"af", x"ad", x"a3", x"a1", x"a7", x"a5", x"db", x"d9", x"df", x"dd", x"d3", x"d1", x"d7", x"d5", x"cb", x"c9", x"cf", x"cd", x"c3", x"c1", x"c7", x"c5", x"fb", x"f9", x"ff", x"fd", x"f3", x"f1", x"f7", x"f5", x"eb", x"e9", x"ef", x"ed", x"e3", x"e1", x"e7", x"e5");
    constant GF_MULT3       : linear_array := (x"00", x"03", x"06", x"05", x"0c", x"0f", x"0a", x"09", x"18", x"1b", x"1e", x"1d", x"14", x"17", x"12", x"11", x"30", x"33", x"36", x"35", x"3c", x"3f", x"3a", x"39", x"28", x"2b", x"2e", x"2d", x"24", x"27", x"22", x"21", x"60", x"63", x"66", x"65", x"6c", x"6f", x"6a", x"69", x"78", x"7b", x"7e", x"7d", x"74", x"77", x"72", x"71", x"50", x"53", x"56", x"55", x"5c", x"5f", x"5a", x"59", x"48", x"4b", x"4e", x"4d", x"44", x"47", x"42", x"41", x"c0", x"c3", x"c6", x"c5", x"cc", x"cf", x"ca", x"c9", x"d8", x"db", x"de", x"dd", x"d4", x"d7", x"d2", x"d1", x"f0", x"f3", x"f6", x"f5", x"fc", x"ff", x"fa", x"f9", x"e8", x"eb", x"ee", x"ed", x"e4", x"e7", x"e2", x"e1", x"a0", x"a3", x"a6", x"a5", x"ac", x"af", x"aa", x"a9", x"b8", x"bb", x"be", x"bd", x"b4", x"b7", x"b2", x"b1", x"90", x"93", x"96", x"95", x"9c", x"9f", x"9a", x"99", x"88", x"8b", x"8e", x"8d", x"84", x"87", x"82", x"81", x"9b", x"98", x"9d", x"9e", x"97", x"94", x"91", x"92", x"83", x"80", x"85", x"86", x"8f", x"8c", x"89", x"8a", x"ab", x"a8", x"ad", x"ae", x"a7", x"a4", x"a1", x"a2", x"b3", x"b0", x"b5", x"b6", x"bf", x"bc", x"b9", x"ba", x"fb", x"f8", x"fd", x"fe", x"f7", x"f4", x"f1", x"f2", x"e3", x"e0", x"e5", x"e6", x"ef", x"ec", x"e9", x"ea", x"cb", x"c8", x"cd", x"ce", x"c7", x"c4", x"c1", x"c2", x"d3", x"d0", x"d5", x"d6", x"df", x"dc", x"d9", x"da", x"5b", x"58", x"5d", x"5e", x"57", x"54", x"51", x"52", x"43", x"40", x"45", x"46", x"4f", x"4c", x"49", x"4a", x"6b", x"68", x"6d", x"6e", x"67", x"64", x"61", x"62", x"73", x"70", x"75", x"76", x"7f", x"7c", x"79", x"7a", x"3b", x"38", x"3d", x"3e", x"37", x"34", x"31", x"32", x"23", x"20", x"25", x"26", x"2f", x"2c", x"29", x"2a", x"0b", x"08", x"0d", x"0e", x"07", x"04", x"01", x"02", x"13", x"10", x"15", x"16", x"1f", x"1c", x"19", x"1a");
    constant GF_MULT9       : linear_array := (x"00", x"09", x"12", x"1b", x"24", x"2d", x"36", x"3f", x"48", x"41", x"5a", x"53", x"6c", x"65", x"7e", x"77", x"90", x"99", x"82", x"8b", x"b4", x"bd", x"a6", x"af", x"d8", x"d1", x"ca", x"c3", x"fc", x"f5", x"ee", x"e7", x"3b", x"32", x"29", x"20", x"1f", x"16", x"0d", x"04", x"73", x"7a", x"61", x"68", x"57", x"5e", x"45", x"4c", x"ab", x"a2", x"b9", x"b0", x"8f", x"86", x"9d", x"94", x"e3", x"ea", x"f1", x"f8", x"c7", x"ce", x"d5", x"dc", x"76", x"7f", x"64", x"6d", x"52", x"5b", x"40", x"49", x"3e", x"37", x"2c", x"25", x"1a", x"13", x"08", x"01", x"e6", x"ef", x"f4", x"fd", x"c2", x"cb", x"d0", x"d9", x"ae", x"a7", x"bc", x"b5", x"8a", x"83", x"98", x"91", x"4d", x"44", x"5f", x"56", x"69", x"60", x"7b", x"72", x"05", x"0c", x"17", x"1e", x"21", x"28", x"33", x"3a", x"dd", x"d4", x"cf", x"c6", x"f9", x"f0", x"eb", x"e2", x"95", x"9c", x"87", x"8e", x"b1", x"b8", x"a3", x"aa", x"ec", x"e5", x"fe", x"f7", x"c8", x"c1", x"da", x"d3", x"a4", x"ad", x"b6", x"bf", x"80", x"89", x"92", x"9b", x"7c", x"75", x"6e", x"67", x"58", x"51", x"4a", x"43", x"34", x"3d", x"26", x"2f", x"10", x"19", x"02", x"0b", x"d7", x"de", x"c5", x"cc", x"f3", x"fa", x"e1", x"e8", x"9f", x"96", x"8d", x"84", x"bb", x"b2", x"a9", x"a0", x"47", x"4e", x"55", x"5c", x"63", x"6a", x"71", x"78", x"0f", x"06", x"1d", x"14", x"2b", x"22", x"39", x"30", x"9a", x"93", x"88", x"81", x"be", x"b7", x"ac", x"a5", x"d2", x"db", x"c0", x"c9", x"f6", x"ff", x"e4", x"ed", x"0a", x"03", x"18", x"11", x"2e", x"27", x"3c", x"35", x"42", x"4b", x"50", x"59", x"66", x"6f", x"74", x"7d", x"a1", x"a8", x"b3", x"ba", x"85", x"8c", x"97", x"9e", x"e9", x"e0", x"fb", x"f2", x"cd", x"c4", x"df", x"d6", x"31", x"38", x"23", x"2a", x"15", x"1c", x"07", x"0e", x"79", x"70", x"6b", x"62", x"5d", x"54", x"4f", x"46");
    constant GF_MULT11      : linear_array := (x"00", x"0b", x"16", x"1d", x"2c", x"27", x"3a", x"31", x"58", x"53", x"4e", x"45", x"74", x"7f", x"62", x"69", x"b0", x"bb", x"a6", x"ad", x"9c", x"97", x"8a", x"81", x"e8", x"e3", x"fe", x"f5", x"c4", x"cf", x"d2", x"d9", x"7b", x"70", x"6d", x"66", x"57", x"5c", x"41", x"4a", x"23", x"28", x"35", x"3e", x"0f", x"04", x"19", x"12", x"cb", x"c0", x"dd", x"d6", x"e7", x"ec", x"f1", x"fa", x"93", x"98", x"85", x"8e", x"bf", x"b4", x"a9", x"a2", x"f6", x"fd", x"e0", x"eb", x"da", x"d1", x"cc", x"c7", x"ae", x"a5", x"b8", x"b3", x"82", x"89", x"94", x"9f", x"46", x"4d", x"50", x"5b", x"6a", x"61", x"7c", x"77", x"1e", x"15", x"08", x"03", x"32", x"39", x"24", x"2f", x"8d", x"86", x"9b", x"90", x"a1", x"aa", x"b7", x"bc", x"d5", x"de", x"c3", x"c8", x"f9", x"f2", x"ef", x"e4", x"3d", x"36", x"2b", x"20", x"11", x"1a", x"07", x"0c", x"65", x"6e", x"73", x"78", x"49", x"42", x"5f", x"54", x"f7", x"fc", x"e1", x"ea", x"db", x"d0", x"cd", x"c6", x"af", x"a4", x"b9", x"b2", x"83", x"88", x"95", x"9e", x"47", x"4c", x"51", x"5a", x"6b", x"60", x"7d", x"76", x"1f", x"14", x"09", x"02", x"33", x"38", x"25", x"2e", x"8c", x"87", x"9a", x"91", x"a0", x"ab", x"b6", x"bd", x"d4", x"df", x"c2", x"c9", x"f8", x"f3", x"ee", x"e5", x"3c", x"37", x"2a", x"21", x"10", x"1b", x"06", x"0d", x"64", x"6f", x"72", x"79", x"48", x"43", x"5e", x"55", x"01", x"0a", x"17", x"1c", x"2d", x"26", x"3b", x"30", x"59", x"52", x"4f", x"44", x"75", x"7e", x"63", x"68", x"b1", x"ba", x"a7", x"ac", x"9d", x"96", x"8b", x"80", x"e9", x"e2", x"ff", x"f4", x"c5", x"ce", x"d3", x"d8", x"7a", x"71", x"6c", x"67", x"56", x"5d", x"40", x"4b", x"22", x"29", x"34", x"3f", x"0e", x"05", x"18", x"13", x"ca", x"c1", x"dc", x"d7", x"e6", x"ed", x"f0", x"fb", x"92", x"99", x"84", x"8f", x"be", x"b5", x"a8", x"a3");
    constant GF_MULT13      : linear_array := (x"00", x"0d", x"1a", x"17", x"34", x"39", x"2e", x"23", x"68", x"65", x"72", x"7f", x"5c", x"51", x"46", x"4b", x"d0", x"dd", x"ca", x"c7", x"e4", x"e9", x"fe", x"f3", x"b8", x"b5", x"a2", x"af", x"8c", x"81", x"96", x"9b", x"bb", x"b6", x"a1", x"ac", x"8f", x"82", x"95", x"98", x"d3", x"de", x"c9", x"c4", x"e7", x"ea", x"fd", x"f0", x"6b", x"66", x"71", x"7c", x"5f", x"52", x"45", x"48", x"03", x"0e", x"19", x"14", x"37", x"3a", x"2d", x"20", x"6d", x"60", x"77", x"7a", x"59", x"54", x"43", x"4e", x"05", x"08", x"1f", x"12", x"31", x"3c", x"2b", x"26", x"bd", x"b0", x"a7", x"aa", x"89", x"84", x"93", x"9e", x"d5", x"d8", x"cf", x"c2", x"e1", x"ec", x"fb", x"f6", x"d6", x"db", x"cc", x"c1", x"e2", x"ef", x"f8", x"f5", x"be", x"b3", x"a4", x"a9", x"8a", x"87", x"90", x"9d", x"06", x"0b", x"1c", x"11", x"32", x"3f", x"28", x"25", x"6e", x"63", x"74", x"79", x"5a", x"57", x"40", x"4d", x"da", x"d7", x"c0", x"cd", x"ee", x"e3", x"f4", x"f9", x"b2", x"bf", x"a8", x"a5", x"86", x"8b", x"9c", x"91", x"0a", x"07", x"10", x"1d", x"3e", x"33", x"24", x"29", x"62", x"6f", x"78", x"75", x"56", x"5b", x"4c", x"41", x"61", x"6c", x"7b", x"76", x"55", x"58", x"4f", x"42", x"09", x"04", x"13", x"1e", x"3d", x"30", x"27", x"2a", x"b1", x"bc", x"ab", x"a6", x"85", x"88", x"9f", x"92", x"d9", x"d4", x"c3", x"ce", x"ed", x"e0", x"f7", x"fa", x"b7", x"ba", x"ad", x"a0", x"83", x"8e", x"99", x"94", x"df", x"d2", x"c5", x"c8", x"eb", x"e6", x"f1", x"fc", x"67", x"6a", x"7d", x"70", x"53", x"5e", x"49", x"44", x"0f", x"02", x"15", x"18", x"3b", x"36", x"21", x"2c", x"0c", x"01", x"16", x"1b", x"38", x"35", x"22", x"2f", x"64", x"69", x"7e", x"73", x"50", x"5d", x"4a", x"47", x"dc", x"d1", x"c6", x"cb", x"e8", x"e5", x"f2", x"ff", x"b4", x"b9", x"ae", x"a3", x"80", x"8d", x"9a", x"97");
    constant GF_MULT14      : linear_array := (x"00", x"0e", x"1c", x"12", x"38", x"36", x"24", x"2a", x"70", x"7e", x"6c", x"62", x"48", x"46", x"54", x"5a", x"e0", x"ee", x"fc", x"f2", x"d8", x"d6", x"c4", x"ca", x"90", x"9e", x"8c", x"82", x"a8", x"a6", x"b4", x"ba", x"db", x"d5", x"c7", x"c9", x"e3", x"ed", x"ff", x"f1", x"ab", x"a5", x"b7", x"b9", x"93", x"9d", x"8f", x"81", x"3b", x"35", x"27", x"29", x"03", x"0d", x"1f", x"11", x"4b", x"45", x"57", x"59", x"73", x"7d", x"6f", x"61", x"ad", x"a3", x"b1", x"bf", x"95", x"9b", x"89", x"87", x"dd", x"d3", x"c1", x"cf", x"e5", x"eb", x"f9", x"f7", x"4d", x"43", x"51", x"5f", x"75", x"7b", x"69", x"67", x"3d", x"33", x"21", x"2f", x"05", x"0b", x"19", x"17", x"76", x"78", x"6a", x"64", x"4e", x"40", x"52", x"5c", x"06", x"08", x"1a", x"14", x"3e", x"30", x"22", x"2c", x"96", x"98", x"8a", x"84", x"ae", x"a0", x"b2", x"bc", x"e6", x"e8", x"fa", x"f4", x"de", x"d0", x"c2", x"cc", x"41", x"4f", x"5d", x"53", x"79", x"77", x"65", x"6b", x"31", x"3f", x"2d", x"23", x"09", x"07", x"15", x"1b", x"a1", x"af", x"bd", x"b3", x"99", x"97", x"85", x"8b", x"d1", x"df", x"cd", x"c3", x"e9", x"e7", x"f5", x"fb", x"9a", x"94", x"86", x"88", x"a2", x"ac", x"be", x"b0", x"ea", x"e4", x"f6", x"f8", x"d2", x"dc", x"ce", x"c0", x"7a", x"74", x"66", x"68", x"42", x"4c", x"5e", x"50", x"0a", x"04", x"16", x"18", x"32", x"3c", x"2e", x"20", x"ec", x"e2", x"f0", x"fe", x"d4", x"da", x"c8", x"c6", x"9c", x"92", x"80", x"8e", x"a4", x"aa", x"b8", x"b6", x"0c", x"02", x"10", x"1e", x"34", x"3a", x"28", x"26", x"7c", x"72", x"60", x"6e", x"44", x"4a", x"58", x"56", x"37", x"39", x"2b", x"25", x"0f", x"01", x"13", x"1d", x"47", x"49", x"5b", x"55", x"7f", x"71", x"63", x"6d", x"d7", x"d9", x"cb", x"c5", x"ef", x"e1", x"f3", x"fd", x"a7", x"a9", x"bb", x"b5", x"9f", x"91", x"83", x"8d");
    
    constant RCON_ARRAY     : rconv_array  := (x"8d000000", x"01000000", x"02000000", x"04000000", x"08000000", x"10000000", x"20000000", x"40000000", x"80000000", x"1b000000", x"36000000", x"6c000000", x"d8000000", x"ab000000", x"4d000000", x"9a000000");
    ----------------------------------------------------------------
    -- Functions declarations for encryption
    ----------------------------------------------------------------
    function subBytes    ( sbox_inp : std_logic_vector(127 downto 0)) return std_logic_vector;
    function shiftRows   ( sr_inp   : std_logic_vector(127 downto 0)) return std_logic_vector;
    function mixColumns  ( mc_inp   : std_logic_vector(127 downto 0)) return std_logic_vector;
    function addRoundKey ( state    : std_logic_vector(127 downto 0); key_in1,key_in2,key_in3,key_in4 : std_logic_vector(31  downto 0)) return std_logic_vector;
    
    ----------------------------------------------------------------
    -- Functions declarations for decryption
    ----------------------------------------------------------------
    function inv_subBytes  (inv_sbox_inp : std_logic_vector(127 downto 0)) return std_logic_vector;
    function inv_shiftRows (inv_sr_inp   : std_logic_vector(127 downto 0)) return std_logic_vector;
    function inv_mixColumns(inv_mc_inp   : std_logic_vector(127 downto 0)) return std_logic_vector;

    ----------------------------------------------------------------
    -- Key schedule operations declarations
    ----------------------------------------------------------------
    function rotWord (rw_in  : std_logic_vector(31  downto 0)) return std_logic_vector;
    function subWord (sw_in  : std_logic_vector(31  downto 0)) return std_logic_vector;
    function keyExp  (key_in : std_logic_vector(255 downto 0)) return key_array;
    
    
    ----------------------------------------------------------------
    -- Encryption and Decryption methods declarations
    ----------------------------------------------------------------
    function encrypt (plain_text  : std_logic_vector(127 downto 0);
                      master_key  : std_logic_vector(255 downto 0)) return std_logic_vector;
                      
    function decrypt (cipher_text : std_logic_vector(127 downto 0);
                      master_key  : std_logic_vector(255 downto 0)) return std_logic_vector;  
                      
    function standard_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector;
    function last_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function inv_std_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector;
    function inv_last_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector;    
    
    function ARK (state, key : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function SWRW( val : std_logic_vector(31 downto 0);
                   ind : integer range 0 to 60) return std_logic_vector;
   
    ----------------------------------------------------------------
    -- methods declarations for masked encryption / Decryption
    ----------------------------------------------------------------
    
    function masked_sbox(s, m : std_logic_vector(7 downto 0)) return std_logic_vector;
    
    function masked_SubBytes(state, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function masked_round(state, k, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function masked_last_round(state, k, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function inv_masked_sbox(s, m : std_logic_vector(7 downto 0)) return std_logic_vector;
        
    function inv_masked_SubBytes(state, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function inv_masked_round(state, k, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
     
    function inv_masked_last_round(state, k, mask : std_logic_vector(127 downto 0)) return std_logic_vector;
           
    function mask_operation(mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
    function inv_mask_operation(mask : std_logic_vector(127 downto 0)) return std_logic_vector;
    
end aes256_pkg;




package body aes256_pkg is

    ----------------------------------------------------------------
    -- Functions implementations for encryption
    ----------------------------------------------------------------

    function subBytes(sbox_inp : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable sbox_out : std_logic_vector(127 downto 0);
    begin
        sbox_out(127 downto 120) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(127 downto 120))));
        sbox_out(119 downto 112) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(119 downto 112))));
        sbox_out(111 downto 104) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(111 downto 104))));
        sbox_out(103 downto 96 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(103 downto 96 ))));
        sbox_out(95  downto 88 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(95  downto 88 ))));
        sbox_out(87  downto 80 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(87  downto 80 ))));
        sbox_out(79  downto 72 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(79  downto 72 ))));
        sbox_out(71  downto 64 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(71  downto 64 ))));
        sbox_out(63  downto 56 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(63  downto 56 ))));
        sbox_out(55  downto 48 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(55  downto 48 ))));
        sbox_out(47  downto 40 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(47  downto 40 ))));
        sbox_out(39  downto 32 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(39  downto 32 ))));
        sbox_out(31  downto 24 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(31  downto 24 ))));
        sbox_out(23  downto 16 ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(23  downto 16 ))));
        sbox_out(15  downto 8  ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(15  downto 8  ))));
        sbox_out(7   downto 0  ) := SBOX_ARRAY(to_integer(unsigned(sbox_inp(7   downto 0  ))));
        
        return sbox_out;
    end function subBytes;
    
    
    function shiftRows  ( sr_inp   : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable sr_out : std_logic_vector(127 downto 0);
    begin
        sr_out(127 downto 120) := sr_inp(127 downto 120);   sr_out(95 downto 88) := sr_inp(95  downto 88);   sr_out(63 downto 56) := sr_inp(63  downto 56 );   sr_out(31 downto 24) := sr_inp(31  downto 24 );
        sr_out(119 downto 112) := sr_inp(87  downto 80 );   sr_out(87 downto 80) := sr_inp(55  downto 48);   sr_out(55 downto 48) := sr_inp(23  downto 16 );   sr_out(23 downto 16) := sr_inp(119 downto 112);
        sr_out(111 downto 104) := sr_inp(47  downto 40 );   sr_out(79 downto 72) := sr_inp(15  downto 8 );   sr_out(47 downto 40) := sr_inp(111 downto 104);   sr_out(15 downto 8 ) := sr_inp(79  downto 72 );
        sr_out(103 downto 96 ) := sr_inp(7   downto 0  );   sr_out(71 downto 64) := sr_inp(103 downto 96);   sr_out(39 downto 32) := sr_inp(71  downto 64 );   sr_out(7  downto 0 ) := sr_inp(39  downto 32 ); 
    
        return sr_out;
    end function shiftRows;
    
    
    function mixColumns ( mc_inp   : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable mc_out : std_logic_vector(127 downto 0);
    begin
        mc_out(127 downto 120) := GF_MULT2(to_integer(unsigned(mc_inp(127 downto 120)))) xor GF_MULT3(to_integer(unsigned(mc_inp(119 downto 112)))) xor mc_inp(111 downto 104) xor mc_inp(103 downto 96);
        mc_out(119 downto 112) := mc_inp(127 downto 120) xor GF_MULT2(to_integer(unsigned(mc_inp(119 downto 112)))) xor GF_MULT3(to_integer(unsigned(mc_inp(111 downto 104)))) xor mc_inp(103 downto 96);
        mc_out(111 downto 104) := mc_inp(127 downto 120) xor mc_inp(119 downto 112) xor GF_MULT2(to_integer(unsigned(mc_inp(111 downto 104)))) xor GF_MULT3(to_integer(unsigned(mc_inp(103 downto 96))));
        mc_out(103 downto 96 ) := GF_MULT3(to_integer(unsigned(mc_inp(127 downto 120)))) xor mc_inp(119 downto 112) xor mc_inp(111 downto 104) xor GF_MULT2(to_integer(unsigned(mc_inp(103 downto 96))));
    
        mc_out(95  downto 88 ) := GF_MULT2(to_integer(unsigned(mc_inp(95 downto 88)))) xor GF_MULT3(to_integer(unsigned(mc_inp(87 downto 80)))) xor mc_inp(79 downto 72) xor mc_inp(71 downto 64);
        mc_out(87  downto 80 ) := GF_MULT2(to_integer(unsigned(mc_inp(87 downto 80)))) xor GF_MULT3(to_integer(unsigned(mc_inp(79 downto 72)))) xor mc_inp(95 downto 88) xor mc_inp(71 downto 64);
        mc_out(79  downto 72 ) := GF_MULT2(to_integer(unsigned(mc_inp(79 downto 72)))) xor GF_MULT3(to_integer(unsigned(mc_inp(71 downto 64)))) xor mc_inp(95 downto 88) xor mc_inp(87 downto 80);
        mc_out(71  downto 64 ) := GF_MULT2(to_integer(unsigned(mc_inp(71 downto 64)))) xor GF_MULT3(to_integer(unsigned(mc_inp(95 downto 88)))) xor mc_inp(87 downto 80) xor mc_inp(79 downto 72);
    
        mc_out(63  downto 56 ) := GF_MULT2(to_integer(unsigned(mc_inp(63  downto 56)))) xor GF_MULT3(to_integer(unsigned(mc_inp(55  downto 48)))) xor mc_inp(47  downto 40) xor mc_inp(39  downto 32);
        mc_out(55  downto 48 ) := GF_MULT2(to_integer(unsigned(mc_inp(55  downto 48)))) xor GF_MULT3(to_integer(unsigned(mc_inp(47  downto 40)))) xor mc_inp(39  downto 32) xor mc_inp(63  downto 56);
        mc_out(47  downto 40 ) := GF_MULT2(to_integer(unsigned(mc_inp(47  downto 40)))) xor GF_MULT3(to_integer(unsigned(mc_inp(39  downto 32)))) xor mc_inp(63  downto 56) xor mc_inp(55  downto 48);
        mc_out(39  downto 32 ) := GF_MULT2(to_integer(unsigned(mc_inp(39  downto 32)))) xor GF_MULT3(to_integer(unsigned(mc_inp(63  downto 56)))) xor mc_inp(55  downto 48) xor mc_inp(47  downto 40);
        
        mc_out(31  downto 24 ) := GF_MULT2(to_integer(unsigned(mc_inp(31  downto 24)))) xor GF_MULT3(to_integer(unsigned(mc_inp(23  downto 16)))) xor mc_inp(15  downto 8)  xor mc_inp(7   downto 0);
        mc_out(23  downto 16 ) := GF_MULT2(to_integer(unsigned(mc_inp(23  downto 16)))) xor GF_MULT3(to_integer(unsigned(mc_inp(15  downto 8))))  xor mc_inp(7   downto 0)  xor mc_inp(31  downto 24);
        mc_out(15  downto 8  ) := GF_MULT2(to_integer(unsigned(mc_inp(15  downto 8)))) xor GF_MULT3(to_integer(unsigned(mc_inp(7   downto 0))))   xor mc_inp(31  downto 24) xor mc_inp(23  downto 16);
        mc_out(7   downto 0  ) := GF_MULT2(to_integer(unsigned(mc_inp(7   downto 0)))) xor GF_MULT3(to_integer(unsigned(mc_inp(31  downto 24))))  xor mc_inp(23  downto 16) xor mc_inp(15  downto 8); 
    
        return mc_out;
    end function mixColumns;
    
    function addRoundKey ( state    : std_logic_vector(127 downto 0); key_in1,key_in2,key_in3,key_in4 : std_logic_vector(31  downto 0)) return std_logic_vector is
        variable state_out : std_logic_vector(127 downto 0);
    begin
        state_out(127 downto 96) := state(127 downto 96) xor key_in1;
        state_out(95  downto 64) := state(95  downto 64) xor key_in2;
        state_out(63  downto 32) := state(63  downto 32) xor key_in3;
        state_out(31  downto 0 ) := state(31  downto 0 ) xor key_in4;  
        
        return state_out;
    end function addRoundKey;
    
    ----------------------------------------------------------------
    -- Functions implementations for decryption
    ----------------------------------------------------------------
    
    function inv_subBytes  (inv_sbox_inp : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable inv_sbox_out : std_logic_vector(127 downto 0);
    begin
        inv_sbox_out(127 downto 120) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(127 downto 120))));
        inv_sbox_out(119 downto 112) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(119 downto 112))));
        inv_sbox_out(111 downto 104) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(111 downto 104))));
        inv_sbox_out(103 downto 96 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(103 downto 96 ))));
        inv_sbox_out(95  downto 88 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(95  downto 88 ))));
        inv_sbox_out(87  downto 80 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(87  downto 80 ))));
        inv_sbox_out(79  downto 72 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(79  downto 72 ))));
        inv_sbox_out(71  downto 64 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(71  downto 64 ))));
        inv_sbox_out(63  downto 56 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(63  downto 56 ))));
        inv_sbox_out(55  downto 48 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(55  downto 48 ))));
        inv_sbox_out(47  downto 40 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(47  downto 40 ))));
        inv_sbox_out(39  downto 32 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(39  downto 32 ))));
        inv_sbox_out(31  downto 24 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(31  downto 24 ))));
        inv_sbox_out(23  downto 16 ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(23  downto 16 ))));
        inv_sbox_out(15  downto 8  ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(15  downto 8  ))));
        inv_sbox_out(7   downto 0  ) := INV_SBOX_ARRAY(to_integer(unsigned(inv_sbox_inp(7   downto 0  ))));
        
        return inv_sbox_out;
    end function inv_subBytes;
    
    
    function inv_shiftRows (inv_sr_inp   : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable inv_sr_out : std_logic_vector(127 downto 0);
    begin
        inv_sr_out(127 downto 120) := inv_sr_inp(127 downto 120);   inv_sr_out(95  downto 88 ) := inv_sr_inp(95  downto 88 );   inv_sr_out(63  downto 56 ) := inv_sr_inp(63  downto 56 );    inv_sr_out(31  downto 24 ) := inv_sr_inp(31  downto 24 );
        inv_sr_out(119 downto 112) := inv_sr_inp(23  downto 16 );   inv_sr_out(87  downto 80 ) := inv_sr_inp(119 downto 112);   inv_sr_out(55  downto 48 ) := inv_sr_inp(87  downto 80 );    inv_sr_out(23  downto 16 ) := inv_sr_inp(55  downto 48 );
        inv_sr_out(111 downto 104) := inv_sr_inp(47  downto 40 );   inv_sr_out(79  downto 72 ) := inv_sr_inp(15  downto 8  );   inv_sr_out(47  downto 40 ) := inv_sr_inp(111 downto 104);    inv_sr_out(15  downto 8  ) := inv_sr_inp(79  downto 72 );
        inv_sr_out(103 downto 96 ) := inv_sr_inp(71  downto 64 );   inv_sr_out(71  downto 64 ) := inv_sr_inp(39  downto 32 );   inv_sr_out(39  downto 32 ) := inv_sr_inp(7   downto 0  );    inv_sr_out(7   downto 0  ) := inv_sr_inp(103 downto 96 ); 
        
        return inv_sr_out;
    end function inv_shiftRows;
    
    
    function inv_mixColumns(inv_mc_inp   : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable inv_mc_out : std_logic_vector(127 downto 0);
    begin
    
        inv_mc_out(127 downto 120) := GF_MULT14(to_integer(unsigned(inv_mc_inp(127 downto 120)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(103 downto 96)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(119 downto 112)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(111 downto 104))));
        inv_mc_out(119 downto 112) := GF_MULT14(to_integer(unsigned(inv_mc_inp(119 downto 112)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(127 downto 120)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(111 downto 104)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(103 downto 96))));
        inv_mc_out(111 downto 104) := GF_MULT14(to_integer(unsigned(inv_mc_inp(111 downto 104)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(119 downto 112)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(103 downto 96)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(127 downto 120))));
        inv_mc_out(103 downto 96) := GF_MULT14(to_integer(unsigned(inv_mc_inp(103 downto 96))))   xor GF_MULT9(to_integer(unsigned(inv_mc_inp(111 downto 104)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(127 downto 120)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(119 downto 112))));
        
        inv_mc_out(95 downto 88) := GF_MULT14(to_integer(unsigned(inv_mc_inp(95 downto 88)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(71 downto 64)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(87 downto 80)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(79 downto 72))));
        inv_mc_out(87 downto 80) := GF_MULT14(to_integer(unsigned(inv_mc_inp(87 downto 80)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(95 downto 88)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(79 downto 72)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(71 downto 64))));
        inv_mc_out(79 downto 72) := GF_MULT14(to_integer(unsigned(inv_mc_inp(79 downto 72)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(87 downto 80)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(71 downto 64)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(95 downto 88))));
        inv_mc_out(71 downto 64) := GF_MULT14(to_integer(unsigned(inv_mc_inp(71 downto 64)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(79 downto 72)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(95 downto 88)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(87 downto 80))));
        
        inv_mc_out(63 downto 56) := GF_MULT14(to_integer(unsigned(inv_mc_inp(63 downto 56)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(39 downto 32)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(55 downto 48)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(47 downto 40))));
        inv_mc_out(55 downto 48) := GF_MULT14(to_integer(unsigned(inv_mc_inp(55 downto 48)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(63 downto 56)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(47 downto 40)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(39 downto 32))));
        inv_mc_out(47 downto 40) := GF_MULT14(to_integer(unsigned(inv_mc_inp(47 downto 40)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(55 downto 48)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(39 downto 32)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(63 downto 56))));
        inv_mc_out(39 downto 32) := GF_MULT14(to_integer(unsigned(inv_mc_inp(39 downto 32)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(47 downto 40)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(63 downto 56)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(55 downto 48))));
        
        inv_mc_out(31 downto 24) := GF_MULT14(to_integer(unsigned(inv_mc_inp(31 downto 24)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(7 downto 0)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp( 23 downto 16)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(15 downto 8))));
        inv_mc_out(23 downto 16) := GF_MULT14(to_integer(unsigned(inv_mc_inp(23 downto 16)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(31 downto 24)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp( 15 downto 8)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(7 downto 0))));
        inv_mc_out(15 downto 8) := GF_MULT14(to_integer(unsigned(inv_mc_inp(15 downto 8)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(23 downto 16)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(7 downto 0)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(31 downto 24))));
        inv_mc_out(7 downto 0)  := GF_MULT14(to_integer(unsigned(inv_mc_inp(7 downto 0)))) xor GF_MULT9(to_integer(unsigned(inv_mc_inp(15 downto 8)))) xor GF_MULT11(to_integer(unsigned(inv_mc_inp(31 downto 24)))) xor GF_MULT13(to_integer(unsigned(inv_mc_inp(23 downto 16))));
    
        return inv_mc_out;
    
    end function inv_mixColumns;
    
    ----------------------------------------------------------------
    -- Functions implementations for key expansion
    ----------------------------------------------------------------
    
    function rotWord (rw_in  : std_logic_vector(31  downto 0)) return std_logic_vector is
        variable rw_out : std_logic_vector(31 downto 0);
    begin
        rw_out(31 downto 24) := rw_in(23 downto 16);    rw_out(23 downto 16) := rw_in(15 downto 8 );    rw_out(15 downto 8 ) := rw_in(7  downto 0 );    rw_out(7  downto 0 ) := rw_in(31 downto 24);
        return rw_out;
    end function rotWord;
    
    
    function subWord (sw_in  : std_logic_vector(31  downto 0)) return std_logic_vector is
        variable sw_out : std_logic_vector(31 downto 0);
    begin
        sw_out(31 downto 24) := SBOX_ARRAY(to_integer(unsigned(sw_in(31 downto 24))));
        sw_out(23 downto 16) := SBOX_ARRAY(to_integer(unsigned(sw_in(23 downto 16))));
        sw_out(15 downto 8 ) := SBOX_ARRAY(to_integer(unsigned(sw_in(15 downto 8 ))));
        sw_out(7  downto 0 ) := SBOX_ARRAY(to_integer(unsigned(sw_in(7  downto 0 ))));
        
        return sw_out;
    end function subWord;
    
    function keyExp  (key_in : std_logic_vector(255 downto 0)) return key_array is
        variable outKeys    : key_array;
        variable subKeys    : key_array;
        variable i          : integer range 0 to 64;
        variable tmp,tmpbis : std_logic_vector(31 downto 0);
    begin
        subKeys(0) := key_in(255 downto 224) ; subKeys(1) := key_in(223 downto 192) ; subKeys(2) := key_in(191 downto 160) ; subKeys(3) := key_in(159 downto 128);
        subKeys(4) := key_in(127 downto 96 ) ; subKeys(5) := key_in(95  downto 64 ) ; subKeys(6) := key_in(63  downto 32 ) ; subKeys(7) := key_in(31  downto 0  );
        i := 8;
        while i < 60 loop
            tmp := subKeys(i-1);
            if ((i=8) or (i=16) or (i=24) or (i=32) or (i=40) or (i=48) or (i=56)) then
                tmpbis := rotWord(tmp);
                tmp    := subWord(tmpbis);
                tmpbis := tmp xor RCON_ARRAY(i/8);
                tmp := tmpbis;
            elsif((i=4) or (i=12) or (i=20) or (i=28) or (i=36) or (i=44) or (i=52)) then
                tmpbis := subWord(tmp);
                tmp    := tmpbis;
            end if;
            subKeys(i) := subKeys(i-8) xor tmp;
            i := i + 1;
       end loop;
       outKeys := subKeys;
       return outKeys;
       end function keyExp;
       
    ----------------------------------------------------------------
    -- Encryption and Decryption methods implementations
    ----------------------------------------------------------------
    
    function encrypt (plain_text  : std_logic_vector(127 downto 0);
                          master_key  : std_logic_vector(255 downto 0)) return std_logic_vector is
        variable cipher_output                  : std_logic_vector(127 downto 0);
        variable inter_state, inter_state_bis   : std_logic_vector(127 downto 0);
        variable subKeys                        : key_array;
    begin
        
        --Key expansion
        subKeys := keyExp(master_key);
        
        --First step : xor between plain_text and master_key
        inter_state := addRoundKey(plain_text,subKeys(0),subKeys(1),subKeys(2),subKeys(3));
        
        --Steps 1 to 13 :
        for i in 1 to 13 loop
            inter_state_bis := subBytes (inter_state);
            inter_state     := shiftRows(inter_state_bis);
            inter_state_bis := mixColumns(inter_state);
            inter_state     := addRoundKey(inter_state_bis, subKeys(4*i), subKeys(4*i+1), subKeys(4*i+2),subKeys(4*i+3)); 
        end loop;
        
        --Step 14
        inter_state_bis := subBytes (inter_state);
        inter_state     := shiftRows(inter_state_bis);
        cipher_output   := addRoundKey(inter_state, subKeys(56), subKeys(57), subKeys(58), subKeys(59));
    
        return cipher_output;
    
    end function encrypt;
    
    
    function decrypt (cipher_text : std_logic_vector(127 downto 0);
                      master_key  : std_logic_vector(255 downto 0)) return std_logic_vector is
        variable plain_output                   : std_logic_vector(127 downto 0);
        variable inter_state, inter_state_bis   : std_logic_vector(127 downto 0);
        variable subKeys                        : key_array;
        variable i                              : integer range 0 to 16 := 13;
    begin
    
    --Key expansion
    subKeys := keyExp(master_key);
    
    --First step of decryption
    inter_state := addRoundKey(cipher_text, subKeys(56), subKeys(57), subKeys(58), subKeys(59));
    
    --Steps 13 to 1
    while i > 0 loop
        inter_state_bis := inv_shiftRows(inter_state);
        inter_state     := inv_subBytes(inter_state_bis);
        inter_state_bis := addRoundKey(inter_state, subKeys(4*i), subKeys(4*i+1), subKeys(4*i+2),subKeys(4*i+3));
        inter_state     := inv_MixColumns(inter_state_bis);
        i               := i-1;
    end loop;
   
    -- Last Step of algorithm
    inter_state_bis := inv_shiftRows(inter_state);
    inter_state     := inv_subBytes(inter_state_bis);
    plain_output    := addRoundKey(inter_state, subKeys(0), subKeys(1), subKeys(2),subKeys(3));
    
    return plain_output;
    
    end function decrypt;
    
    function standard_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable inter_state : std_logic_vector(127 downto 0);
    begin
        inter_state := subBytes (state);
        inter_state := shiftRows(inter_state);
        inter_state := mixColumns(inter_state);
        inter_state := ARK(inter_state, key);
    
        return inter_state; 
        
    end function standard_round;
    
    function last_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector is
       variable inter_state : std_logic_vector(127 downto 0);
    begin
        inter_state := subBytes (state);
        inter_state := shiftRows(inter_state);
        inter_state := ARK(inter_state, key);
              
        return inter_state;
           
    end function last_round;
    
    function inv_std_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector is
          variable inter_state : std_logic_vector(127 downto 0);
      begin
        inter_state := inv_shiftRows(state);
        inter_state := inv_subBytes(inter_state);
        inter_state := ARK(inter_state, key);
        inter_state := inv_MixColumns(inter_state);
              
        return inter_state;
          
      end function inv_std_round;
      
    function inv_last_round (state, key : std_logic_vector(127 downto 0)) return std_logic_vector  is
         variable inter_state : std_logic_vector(127 downto 0);
     begin
        inter_state := inv_shiftRows(state);
        inter_state := inv_subBytes(inter_state);
        inter_state := ARK(inter_state, key);
        
        return inter_state;
     end function inv_last_round;
     
     function ARK (state, key : std_logic_vector(127 downto 0)) return std_logic_vector is
     begin
        return (state xor key);
     end function ARK;
     
     function SWRW( val : std_logic_vector(31 downto 0);
                    ind : integer range 0 to 60) return std_logic_vector is
        variable val_out : std_logic_vector(31 downto 0);
        variable indice : integer range 0 to 60;
     begin
        indice  := ind/8; 
        val_out := rotWord(val);
        val_out := subWord(val_out);
        val_out := val_out xor RCON_ARRAY(indice);
        return val_out;
    end function SWRW;
    
    function masked_sbox(s,m : std_logic_vector(7 downto 0)) 
        return std_logic_vector is
        variable state_out,inter : std_logic_vector(7 downto 0);
    begin
        inter := s xor m;
        state_out := SBOX_ARRAY(to_integer(unsigned(inter))) xor m;
        
        return state_out;
    end function masked_sbox;

    function inv_masked_sbox(s,m : std_logic_vector(7 downto 0))
        return std_logic_vector is
        variable s_out,inter : std_logic_vector(7 downto 0);
    begin
        inter := s xor m;
        s_out := INV_SBOX_ARRAY(to_integer(unsigned(inter))) xor m;
        return s_out;
    end function inv_masked_sbox;
    
    function masked_SubBytes(state, mask : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable state_out : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            state_out(8*i+7 downto 8*i) := masked_sBox(state(8*i+7 downto 8*i), mask(8*i+7 downto 8*i));
        end loop;
        return state_out;
    end function masked_SubBytes;
    
    function inv_masked_SubBytes(state, mask : std_logic_vector(127 downto 0))
            return std_logic_vector is
            variable state_out : std_logic_vector(127 downto 0);
        begin
            for i in 0 to 15 loop
                state_out(8*i+7 downto 8*i) := inv_masked_sBox(state(8*i+7 downto 8*i), mask(8*i+7 downto 8*i));
            end loop;
            return state_out;
        end function inv_masked_SubBytes;
        
    function masked_round(state, k, mask : std_logic_vector(127 downto 0))     
        return std_logic_vector is
        variable inter_state : std_logic_vector(127 downto 0);
    begin
        inter_state := masked_subBytes (state, mask);
        inter_state := shiftRows(inter_state);
        inter_state := mixColumns(inter_state);
        inter_state := ARK(inter_state, k);
    
        return inter_state; 
            
    end function masked_round;
    
    function masked_last_round(state, k, mask : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable inter_state : std_logic_vector(127 downto 0);
    begin
        inter_state := masked_SubBytes(state, mask);
        inter_state := shiftRows(inter_state);
        inter_state := ARK(inter_state, k);
        
        return inter_state;
    end function masked_last_round;
    
    function inv_masked_round(state, k, mask : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable inter_state : std_logic_vector(127 downto 0);
    begin
    
        inter_state := inv_masked_subBytes(state, mask);
        inter_state := inv_shiftRows(inter_state);
        inter_state := inv_MixColumns(inter_state);
        inter_state := ARK(inter_state, k);
              
        return inter_state;
          
    end function inv_masked_round;
    
    function inv_masked_last_round(state, k, mask : std_logic_vector(127 downto 0))
        return std_logic_vector is
        variable inter_state : std_logic_vector(127 downto 0);
    begin
    
        inter_state := inv_masked_subBytes(state, mask);
        inter_state := inv_shiftRows(inter_state);
        inter_state := ARK(inter_state, k);
              
        return inter_state;
          
    end function inv_masked_last_round;
        
    function mask_operation(mask : std_logic_vector(127 downto 0)) 
        return std_logic_vector is
        variable mask_out : std_logic_vector(127 downto 0);
    begin
    
        mask_out := shiftRows(mask);
        mask_out := MixColumns(mask_out);
        
        return mask_out;
        
    end function mask_operation;
    
        
    function inv_mask_operation(mask : std_logic_vector(127 downto 0)) 
        return std_logic_vector is
        variable mask_out : std_logic_vector(127 downto 0);
    begin
    
        mask_out := inv_shiftRows(mask);
        mask_out := inv_MixColumns(mask);
        
        return mask_out;
        
    end function inv_mask_operation;

end package body aes256_pkg;