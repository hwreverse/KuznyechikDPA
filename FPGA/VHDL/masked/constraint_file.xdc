set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 [get_ports clk]
	
##USB-RS232 Interface
set_property PACKAGE_PIN B18 [get_ports rx]                        
    set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PACKAGE_PIN A18 [get_ports tx]                        
    set_property IOSTANDARD LVCMOS33 [get_ports tx]
    
##ChipWhisperer Trigger pin
set_property PACKAGE_PIN J1 [get_ports cw_trigger]
    set_property IOSTANDARD LVCMOS33 [get_ports cw_trigger]
    
##Encryption/Decryption Selecter
set_property PACKAGE_PIN R2 [get_ports enc_dec_sel]
    set_property IOSTANDARD LVCMOS33 [get_ports enc_dec_sel]
    
##Buttons
set_property PACKAGE_PIN U18 [get_ports reset]                        
    set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_property CONFIG_MODE SPIx4 [current_design]
