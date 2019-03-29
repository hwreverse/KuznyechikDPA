CONTENT OF THE FOLDER
---------------------

The VHDL codes and Vivado constraints files of Grasshopper regular and masked algorithms are stored in this folder. The bitstreams that you will find in the "Bitstreams" folder were built using these files

HOW TO COMPILE ?
----------------

- Using Vivado : Create a new project, add all the files, and click "Generate the Bitstream". If you are using a different board, you will have to change the constraints assignements.

- not Using Vivado : I'm sorry, but I don't know the commands in order to generate the bitstream. Moreover, the ".xdc" constraint file is made to be used with Vivado, so if using another program, the constraint file may not be usable.

FILES
----------------

- tUART.vhd and rUART.vhd : UART transmitter and receiver modules
- Tx_collecteur.vhd and Rx_collecteur.vhd : Registers allowing to store 128 bits vectors before and after encryption/decryption (because the UART can transmit only 8 bits of data at a time)
- constraint_file.xdc : Vivado constraint file, allowing the user to map the inputs and outputs of vhdl design with the physical elements of the target board.
- Sub_Key_Schedule.vhd : method for sub_keys generation
- lfsr.vhd (masked algorithm only) : generates a pseudo-random number that is the mask for the encryption/decryption
- masked_complete_encryption.vhd and standard_complete_encryption.vhd : encryption/decryption methods for standard and masked implementations
- uart_standard_complete.vhd and uart_masked_complete.vhd : top files, that instanciate and connect each modules of the algorithms