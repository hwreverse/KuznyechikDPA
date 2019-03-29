# How to flash Atmel XMEGA with Kuznyechik Cipher Algorithm (works with Chipwhisperer Capture) ###

## First step ##

Build the binary --> command "make PLATFORM=CW303" in the 'kuznyechik' directory (Platform CW303 is the Atmel XMEGA board)

see at the end of the README for the available platforms (The algorithm was tested for XMEGA, not sure it can work with oher platforms, feel free to test)

## Second step ##

In ChipWhisperer Capture, initialize the serial communication
	-> launch connect_cwlite_simpleserial.py
	-> launch setup_cwlte_xmega.py

## Third step ## 

Flash the card : Tools -> CW-Lite XMEGA Programmer
		 then select your built hex file, and "Erase/Program/Verify FLASH"

## Fourth step ##

Open the terminal : Tools -> Terminal -> Connect

## Encrypting / Decrypting ##

The default key is the default key of the standard example

	-> to encrypt 	 : send 'p[PLAINTEXT]'  / ex : "p1122334455667700ffeeddccbbaa9988"
	-> to decrypt 	 : send 'd[CIPHERTEXT]' / ex : "d7f679d90bebc24305a468d42b9d4edcd"
	-> to change key : send 'k[NEWKEY]'	/ ex : "k8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef"
<hr>
	
## AVAILABLE PLATFORMS

<table>
<thead>
<tr>
	<th style="text-align:left"><h2><ul>PLATFORM</ul></h2></th>
	<th style="text-align:left"><h2><ul>DESCRIPTION</ul></h2></th>
</tr>
</thead>
<tbody>
<tr>
<td><b>CW301_AVR</b></td>
<td>Multi-Target Board, AVR Target</td>
</tr>
<tr>
<td><b>CW303</b></td>
<td>XMEGA Target (CWLite), Also works<br>for CW308T-XMEGA</td>
</tr>
<tr>
<td><b>CW303</b></td>
<td>XMEGA Target (CWLite), Also works<br>for CW308T-XMEGA</td>
</tr>
<tr>
<td><b>CW304</b></td>
<td>ATMega328P (NOTDUINO), Also works<br>for CW308T-AVR</td>
</tr>
	<tr><td><b>CW308_MEGARF</b></td><td>ATMega2564RFR2 Target for CW308T</td></tr> 
<tr><td><b>CW308_SAM4L</b></td><td>CW308T-SAM4L (Atmel SAM4L)</td></tr>        
<tr><td><b>CW308_STM32F0</b></td><td>CW308T-STM32F0 (ST Micro STM32F0)</td></tr> 
<tr><td><b>CW308_STM32F1</b></td><td>CW308T-STM32F0 (ST Micro STM32F1)</td></tr> 
<tr><td><b>CW308_STM32F2</b></td><td>CW308T-STM32F2 (ST Micro STM32F2)</td></tr> 
<tr><td><b>CW308_STM32F3</b></td><td>CW308T-STM32F3 (ST Micro STM32F3)</td></tr> 
<tr><td><b>CW308_STM32F4</b></td><td>CW308T-STM32F4 (ST Micro STM32F4)</td></tr> 
<tr><td><b>CW308_CC2538</b></td><td>CW308-CC2538 (TI CC2538)</td></tr>          
<tr><td><b>CW308_K24F</b></td><td>CW308-K24F (NXP Kinetis K24F)</td></tr>    
</tbody></table> 
