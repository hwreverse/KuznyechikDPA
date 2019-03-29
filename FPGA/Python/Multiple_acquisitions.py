#coding: utf-8

#Python script to encrypt a number of plaintexts in order to acquire power traces

#imports
import serial
import random
import time

#lists declarations
liste_clairs = []    #plaintexts
liste_chiffres = []  #ciphertexts

NUMBER_OF_PAIRS = 50000 #number of pairs we want

#The line under opens the serial port for the communication with the FPGA board
s = serial.Serial(port='COM6',baudrate=115200) #it may not be COM6 on every PC

clair = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

#the idea is to send random plaintexts, and store the ciphers

for data in range(NUMBER_OF_PAIRS):
    
    for k in range(16): #randomizing the plaintext to send
        clair[k] = random.randint(0,255)

    b = bytearray(clair) #transforming the list into a byte_array in order to be sent through serial port
    

    sent = s.write(bytes(b)) #Sending the plaintext
    res  = s.read(17) #Receiving the cipher (16 bytes plus a 0x00)

    time.sleep(1)  #This pause is made to allow the ChipWhisperer Capture. You can remove it if your trace capture if faster

    clair_decode = 0
    chiffre_decode = 0

    #byte_array transformation in order to be easily treated afterwards
    for i in range(16):
        clair_decode = clair_decode + (clair[i] << 8*(15-i))   #bytes is not easy to read, let's transform it to integer
        chiffre_decode = chiffre_decode + (ord(res[i]) << 8*(15-i)) #same comment

    liste_clairs.append(clair_decode) #append the plaintext to the list of plaintexts
    liste_chiffres.append(chiffre_decode) #append the ciphertext to the list of ciphertexts


#now, let's store the data in a txt
fichier = open("clair_chiffre.txt",'w')

for k in range(len(liste_clairs)):
    fichier.write("{:032x} {:032x}\n".format(liste_clairs[k],liste_chiffres[k]))  #couples written in hexadecimal format

fichier.close()