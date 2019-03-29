/* This Grasshopper implementation is based on https://github.com/gostru/grasshopper */

#ifndef _KUZNYECHIK_H_
#define _KUZNYECHIK_H_

#include <stdint.h>

#ifndef KUZNYECHIK_CONST_VAR
//#define KUZNYECHIK_CONST_VAR static const
#define KUZNYECHIK_CONST_VAR
#endif


//void kuznyechik_encrypt(uint8_t* input, uint8_t* key, uint8_t *output);
//void kuznyechik_decrypt(uint8_t* input, uint8_t* key, uint8_t *output);

void kuznyechik_setkey(uint8_t* key);
void kuznyechik_crypto(uint8_t* input);
void kuznyechik_decrypto(uint8_t* input);



#endif //_KUZNYECHIK_H_