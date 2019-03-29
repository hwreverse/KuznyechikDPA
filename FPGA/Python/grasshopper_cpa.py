#coding: utf-8

#this script is the CPA-attack towards the Grasshopper Encryption

##imports

import numpy as np
import grasshopper_data as grdata
import os.path

cur_dir = os.path.dirname(__file__)

#first step : load the traces and the plain/ciphers

#knownkey = [0x72, 0xE9, 0xDD, 0x74, 0x16, 0xbc, 0xf4, 0x5b, 0x75, 0x5d, 0xba, 0xa8, 0x8e, 0x4a, 0x40, 0x43]
knownkey = [0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77]

PGE = [256]*16


""" loading traces coming from ChipWhisperer """

traces1 = np.load(os.path.join(cur_dir,'../DPA_traces/traces_1.npy'))
traces2 = np.load(os.path.join(cur_dir,'../DPA_traces/traces_2.npy'))
traces3 = np.load(os.path.join(cur_dir,'../DPA_traces/traces_3.npy'))
traces4 = np.load(os.path.join(cur_dir,'../DPA_traces/traces_4.npy'))

traces = np.zeros((100000,650))

traces[0:10000,0:] = traces1
traces[10000:20000,0:] = traces2
traces[20000:60000,0:] = traces3
traces[60000:,0:] = traces4


numtraces = np.shape(traces)[0]
numpoints = np.shape(traces)[1]


pt = [] #list of plaintexts
ct = [] #list of ciphertexts


""" Storing the plaintexts and ciphertexts """
file = open(os.path.join(cur_dir,'../DPA_traces/clair_chiffre.txt'),'r')
lignes = file.readlines()
for i in range(len(lignes)):
    inter_nb=lignes[i][33:66] #indices for the cipher text, which is a str format
    inter_nb_bis=lignes[i][0:32] #indices for the plaintext, wich is a str format

    #special format is used during the cpa attack, so let's adapt to this format
      
    """ct.append(int(inter_nb,16)) #append the cipher in 'integer' mode
       pt.append(int(inter_nb_bis,16))"""

    """ version if working on each byte of the subkey """
    ct_format = []
    pt_format = []
    for g in range(16):
      ct_format.append(int(inter_nb[2*g:2*g+2],16))
      pt_format.append(int(inter_nb_bis[2*g:2*g+2],16))
    ct.append(ct_format)
    pt.append(pt_format)
      
file.close()

#print("pt[0] : {}".format(pt[0]))



#Hamming weight definition

HW = [bin(n).count("1") for n in range(0,256)]




#Last step of Grasshopper algorithm (just a xor between the state and the sub key)
def intermediate(data, keyguess):
    return (data ^ keyguess)

#Definition of Hamming Distance between 2 numbers
def Hamming_distance(a,b):
    cha = bin(a)[2:]
    chb = bin(b)[2:]
    hd = 0
    if(len(cha)>len(chb)):
      chb = '0'*(len(cha)-len(chb)) + chb
    elif(len(chb)>len(cha)):
      cha = '0'*(len(chb)-len(cha)) + cha

    for i in range(len(cha)):
      if(cha[i] != chb[i]):
        hd += 1

    return hd


#attack

bestguess = [0]*16 #best guessed last sub key


for bnum in range(16): #bnum means byte_number
    print("byte number : {}".format(bnum))
    cpaoutput = [0]*256
    maxcpa = [0]*256

    for kguess in range(256): #as we are working byte per byte, we have 256 possibilities for each byte

        hyp_key = kguess << 8*(15-bnum)

        #initialize the arrays for Pearson correlation coefficient
        sumnum  = np.zeros(numpoints)
        sumden1 = np.zeros(numpoints)
        sumden2 = np.zeros(numpoints)

        hyp = np.zeros(numtraces)


        for tnum in range(numtraces):
            hyp[tnum] = HW[intermediate(ct[tnum][bnum], kguess)] #First Leakage model
            #hyp[tnum] = Hamming_distance(grdata.first_step(pt[tnum][bnum], kguess),pt[tnum][bnum])

        #Mean of hypothesis
        meanh = np.mean(hyp, dtype=np.float64)

        #Mean of all points in trace
        meant = np.mean(traces, axis=0, dtype=np.float64)

        #For each trace, do the following
        for tnum in range(0, numtraces):
            hdiff = (hyp[tnum] - meanh)
            tdiff = traces[tnum,:] - meant

            sumnum  = sumnum  + (hdiff*tdiff)
            sumden1 = sumden1 + hdiff*hdiff
            sumden2 = sumden2 + tdiff*tdiff

        cpaoutput[kguess] = sumnum / np.sqrt(sumden1*sumden2)
        maxcpa[kguess] = max(abs(cpaoutput[kguess]))

        #print(maxcpa[kguess])

    bestguess[bnum] = np.argmax(maxcpa)

    cparefs = np.argsort(maxcpa)[::-1]

    PGE[bnum] = list(cparefs).index(knownkey[bnum])

    #print("best guess : {:02x}".format(bestguess[bnum]))
    #print("PGE : {:02x}".format(PGE[bnum]))


print("Best Key Guess : ")
for b in bestguess:
    print("%02x"%b)

print("Partial Guessing Entropy : ")
for j in PGE:
    print(j)