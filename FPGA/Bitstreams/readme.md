BITSTREAMS
----------

This folder contains bitstreams of Regular and Masked Grasshopper Algorithms.


HOW DOES IT WORK ?
------------------

- SW15 (R2) is the encryption/decryption mode selector. It allows you to choose wether you want to encode (SW on 0) or decode (SW on 1) the received data.
- The data to be encrypted (or decrypted) is received on the Rx of the Serial Port. When the process of encryption (or decryption) is done, the data is sent to the PC on the Tx of the Serial Port.
- Each time the encryption (or decryption) starts, a trigger is sent through the pin 1 of the JA P-mod. Actually, it was my trigger for trace capture in order to run the DPA attack.
- BUTC (U18) is a reset button. 