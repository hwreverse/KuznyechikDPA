/* This Grasshopper implementation is based on https://github.com/gostru/grasshopper */

#ifndef _KUZNYECHIK_MASKED_H_
#define _KUZNYECHIK_MASKED_H_

#include <stdint.h>
#include <stdlib.h>

#ifndef MASKED_KUZNYECHIK_CONST_VAR
//#define KUZNYECHIK_CONST_VAR static const
#define MASKED_KUZNYECHIK_CONST_VAR
#endif


//void kuznyechik_encrypt(uint8_t* input, uint8_t* key, uint8_t *output);
//void kuznyechik_decrypt(uint8_t* input, uint8_t* key, uint8_t *output);

void kuznyechik_setkey(uint8_t* key);
void masked_kuznyechik_crypto(uint8_t* input);
void masked_kuznyechik_decrypto(uint8_t* input);



#endif //_KUZNYECHIK_MASKED_H_