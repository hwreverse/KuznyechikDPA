/* This Grasshopper implementation is based on https://github.com/gostru/grasshopper */

/*

This is an implementation of the masked Kuznyechik algorithm.

The implementation is verified against the test vectors in:
  Cryptographic Protection of Information Through Bloc Encryption (translated standard of the Kuznyechik algorithm)

----------

  plain-text:
    1122334455667700ffeeddccbbaa9988

  key:
    8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef

  resulting cipher:
    7f679d90bebc24305a468d42b9d4edcd

*/


/*****************************************************************************/
/* Includes:                                                                 */
/*****************************************************************************/
#include <stdint.h>
#include <string.h> // CBC mode, for memset
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

#include "kuznyechik_masked.h"


/*****************************************************************************/
/* Defines:                                                                  */
/*****************************************************************************/
// State length in bytes [128 bits]
#define STATELEN 16
// Key length in bytes [256 bits]
#define KEYLEN 32

/*****************************************************************************/
/* Private variables:                                                        */
/*****************************************************************************/
// state - array holding the intermediate results during decryption.
typedef uint8_t state_t[16];
static state_t* state;
static state_t stateDuringKS;

//mask
static state_t mask;

// The array that stores the round keys.
static state_t RoundKey[66];
static state_t trueRoundKey[10] = {
  {0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77},
  {0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10, 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef},
  {0xdb, 0x31, 0x48, 0x53, 0x15, 0x69, 0x43, 0x43, 0x22, 0x8d, 0x6a, 0xef, 0x8c, 0xc7, 0x8c, 0x44},
  {0x3d, 0x45, 0x53, 0xd8, 0xe9, 0xcf, 0xec, 0x68, 0x15, 0xeb, 0xad, 0xc4, 0x0a, 0x9f, 0xfd, 0x04},
  {0x57, 0x64, 0x64, 0x68, 0xc4, 0x4a, 0x5e, 0x28, 0xd3, 0xe5, 0x92, 0x46, 0xf4, 0x29, 0xf1, 0xac},
  {0xbd, 0x07, 0x94, 0x35, 0x16, 0x5c, 0x64, 0x32, 0xb5, 0x32, 0xe8, 0x28, 0x34, 0xda, 0x58, 0x1b},
  {0x51, 0xe6, 0x40, 0x75, 0x7e, 0x87, 0x45, 0xde, 0x70, 0x57, 0x27, 0x26, 0x5a, 0x00, 0x98, 0xb1},
  {0x5a, 0x79, 0x25, 0x01, 0x7b, 0x9f, 0xdd, 0x3e, 0xd7, 0x2a, 0x91, 0xa2, 0x22, 0x86, 0xf9, 0x84},
  {0xbb, 0x44, 0xe2, 0x53, 0x78, 0xc7, 0x31, 0x23, 0xa5, 0xf3, 0x2f, 0x73, 0xcd, 0xb6, 0xe5, 0x17},
  {0x72, 0xe9, 0xdd, 0x74, 0x16, 0xbc, 0xf4, 0x5b, 0x75, 0x5d, 0xba, 0xa8, 0x8e, 0x4a, 0x40, 0x43}
};

// The Key input to the Kuznyechik Program
static uint8_t* Key;

/*****************************************************************************/
/*      S-Boxes declarations                                                 */
/*****************************************************************************/

MASKED_KUZNYECHIK_CONST_VAR uint8_t sbox[256] =   {
  252, 238, 221,  17, 207, 110,  49,  22, 251, 196, 250, 218,  35, 197,   4,  77, 
  233, 119, 240, 219, 147,  46, 153, 186,  23,  54, 241, 187,  20, 205,  95, 193, 
  249,  24, 101,  90, 226,  92, 239,  33, 129,  28,  60,  66, 139,   1, 142,  79, 
  5, 132,   2, 174, 227, 106, 143, 160,   6,  11, 237, 152, 127, 212, 211,  31, 
  235,  52,  44,  81, 234, 200,  72, 171, 242,  42, 104, 162, 253,  58, 206, 204, 
  181, 112,  14,  86,   8,  12, 118,  18, 191, 114,  19,  71, 156, 183,  93, 135, 
  21, 161, 150,  41,  16, 123, 154, 199, 243, 145, 120, 111, 157, 158, 178, 177, 
  50, 117,  25,  61, 255,  53, 138, 126, 109,  84, 198, 128, 195, 189,  13,  87, 
  223, 245,  36, 169,  62, 168,  67, 201, 215, 121, 214, 246, 124,  34, 185,   3, 
  224,  15, 236, 222, 122, 148, 176, 188, 220, 232,  40,  80,  78,  51,  10,  74, 
  167, 151,  96, 115,  30,   0,  98,  68,  26, 184,  56, 130, 100, 159,  38,  65, 
  173,  69,  70, 146,  39,  94,  85,  47, 140, 163, 165, 125, 105, 213, 149,  59, 
  7,  88, 179,  64, 134, 172,  29, 247,  48,  55, 107, 228, 136, 217, 231, 137, 
  225,  27, 131,  73,  76,  63, 248, 254, 141,  83, 170, 144, 202, 216, 133,  97, 
  32, 113, 103, 164,  45,  43,   9,  91, 203, 155,  37, 208, 190, 229, 108,  82, 
  89, 166, 116, 210, 230, 244, 180, 192, 209, 102, 175, 194, 57, 75, 99, 182 };

MASKED_KUZNYECHIK_CONST_VAR uint8_t rsbox[256] ={ 
  165,  45,  50, 143,  14,  48,  56, 192,  84, 230, 158,  57,  85, 126,  82, 145,
  100,   3,  87,  90,  28,  96,   7,  24,  33, 114, 168, 209,  41, 198, 164,  63,
  224,  39, 141,  12, 130, 234, 174, 180, 154,  99,  73, 229,  66, 228,  21, 183,
  200,   6, 112, 157,  65, 117,  25, 201, 170, 252,  77, 191,  42, 115, 132, 213,
  195, 175,  43, 134, 167, 177, 178,  91,  70, 211, 159, 253, 212,  15, 156,  47,
  155,  67, 239, 217, 121, 182,  83, 127, 193, 240,  35, 231,  37,  94, 181,  30,
  162, 223, 166, 254, 172,  34, 249, 226,  74, 188,  53, 202, 238, 120,   5, 107,
  81, 225,  89, 163, 242, 113,  86,  17, 106, 137, 148, 101, 140, 187, 119,  60,
  123,  40, 171, 210,  49, 222, 196,  95, 204, 207, 118,  44, 184, 216,  46,  54,
  219, 105, 179,  20, 149, 190,  98, 161,  59,  22, 102, 233,  92, 108, 109, 173,
  55,  97,  75, 185, 227, 186, 241, 160, 133, 131, 218,  71, 197, 176,  51, 250,
  150, 111, 110, 194, 246,  80, 255,  93, 169, 142,  23,  27, 151, 125, 236,  88,
  247,  31, 251, 124,   9,  13, 122, 103,  69, 135, 220, 232,  79,  29,  78,   4,
  235, 248, 243,  62,  61, 189, 138, 136, 221, 205,  11,  19, 152,   2, 147, 128,
  144, 208,  36,  52, 203, 237, 244, 206, 153,  16,  68,  64, 146,  58,   1,  38,
  18, 26, 72, 104, 245, 129, 139, 199, 214, 32, 10, 8, 0, 76, 215, 116 };

/*****************************************************************************/
/* Private functions related to Sbox:                                        */
/*****************************************************************************/


static uint8_t getSBoxValue(uint8_t num)
{
  return sbox[num];
}

/*
static uint8_t getSBoxInvert(uint8_t num)
{
  return rsbox[num];
}
*/

static uint8_t getMaskedSBoxValue(uint8_t num, uint8_t mas)
{
  return (sbox[num ^ mas] ^ mas);
}

static uint8_t getMaskedSBoxInvert(uint8_t num, uint8_t mas)
{
  return (rsbox[num ^ mas] ^ mas);
}

/*****************************************************************************/
/* Mask generation                                                           */
/*****************************************************************************/

static void genMask(void)
{
  int i = 0;
  srand((*state)[10] ^ (*state)[11] ^ (*state)[14]);

  for(i = 0; i<16; i++){
      mask[i] = rand(); //this is a test
  }
}

static void maskState(void)
{
  int i;
  for(i=0; i<16; ++i)
  {
    (*state)[i] ^= mask[i];
  }
}

/*****************************************************************************/
/* GF-2 Multiplication :                                                     */
/*****************************************************************************/

static uint8_t mult_mod_poly[8][256] = {
    {   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,
        32,  33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,  46,  47,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,  63,
        64,  65,  66,  67,  68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  90,  91,  92,  93,  94,  95,
        96,  97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
        128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
        160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191,
        192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
        224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255},
    {   0,  16,  32,  48,  64,  80,  96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 195, 211, 227, 243, 131, 147, 163, 179,  67,  83,  99, 115,   3,  19,  35,  51,
        69,  85, 101, 117,   5,  21,  37,  53, 197, 213, 229, 245, 133, 149, 165, 181, 134, 150, 166, 182, 198, 214, 230, 246,   6,  22,  38,  54,  70,  86, 102, 118,
        138, 154, 170, 186, 202, 218, 234, 250,  10,  26,  42,  58,  74,  90, 106, 122,  73,  89, 105, 121,   9,  25,  41,  57, 201, 217, 233, 249, 137, 153, 169, 185,
        207, 223, 239, 255, 143, 159, 175, 191,  79,  95, 111, 127,  15,  31,  47,  63,  12,  28,  44,  60,  76,  92, 108, 124, 140, 156, 172, 188, 204, 220, 236, 252,
        215, 199, 247, 231, 151, 135, 183, 167,  87,  71, 119, 103,  23,   7,  55,  39,  20,   4,  52,  36,  84,  68, 116, 100, 148, 132, 180, 164, 212, 196, 244, 228,
        146, 130, 178, 162, 210, 194, 242, 226,  18,   2,  50,  34,  82,  66, 114,  98,  81,  65, 113,  97,  17,   1,  49,  33, 209, 193, 241, 225, 145, 129, 177, 161,
        93,  77, 125, 109,  29,  13,  61,  45, 221, 205, 253, 237, 157, 141, 189, 173, 158, 142, 190, 174, 222, 206, 254, 238,  30,  14,  62,  46,  94,  78, 126, 110,
        24,   8,  56,  40,  88,  72, 120, 104, 152, 136, 184, 168, 216, 200, 248, 232, 219, 203, 251, 235, 155, 139, 187, 171,  91,  75, 123, 107,  27,  11,  59,  43},
    {   0,  32,  64,  96, 128, 160, 192, 224, 195, 227, 131, 163,  67,  99,   3,  35,  69, 101,   5,  37, 197, 229, 133, 165, 134, 166, 198, 230,   6,  38,  70, 102,
        138, 170, 202, 234,  10,  42,  74, 106,  73, 105,   9,  41, 201, 233, 137, 169, 207, 239, 143, 175,  79, 111,  15,  47,  12,  44,  76, 108, 140, 172, 204, 236,
        215, 247, 151, 183,  87, 119,  23,  55,  20,  52,  84, 116, 148, 180, 212, 244, 146, 178, 210, 242,  18,  50,  82, 114,  81, 113,  17,  49, 209, 241, 145, 177,
        93, 125,  29,  61, 221, 253, 157, 189, 158, 190, 222, 254,  30,  62,  94, 126,  24,  56,  88, 120, 152, 184, 216, 248, 219, 251, 155, 187,  91, 123,  27,  59,
        109,  77,  45,  13, 237, 205, 173, 141, 174, 142, 238, 206,  46,  14, 110,  78,  40,   8, 104,  72, 168, 136, 232, 200, 235, 203, 171, 139, 107,  75,  43,  11,
        231, 199, 167, 135, 103,  71,  39,   7,  36,   4, 100,  68, 164, 132, 228, 196, 162, 130, 226, 194,  34,   2,  98,  66,  97,  65,  33,   1, 225, 193, 161, 129,
        186, 154, 250, 218,  58,  26, 122,  90, 121,  89,  57,  25, 249, 217, 185, 153, 255, 223, 191, 159, 127,  95,  63,  31,  60,  28, 124,  92, 188, 156, 252, 220,
        48,  16, 112,  80, 176, 144, 240, 208, 243, 211, 179, 147, 115,  83,  51,  19, 117,  85,  53,  21, 245, 213, 181, 149, 182, 150, 246, 214,  54,  22, 118,  86},
    {   0, 133, 201,  76,  81, 212, 152,  29, 162,  39, 107, 238, 243, 118,  58, 191, 135,   2,  78, 203, 214,  83,  31, 154,  37, 160, 236, 105, 116, 241, 189,  56,
        205,  72,   4, 129, 156,  25,  85, 208, 111, 234, 166,  35,  62, 187, 247, 114,  74, 207, 131,   6,  27, 158, 210,  87, 232, 109,  33, 164, 185,  60, 112, 245,
        89, 220, 144,  21,   8, 141, 193,  68, 251, 126,  50, 183, 170,  47,  99, 230, 222,  91,  23, 146, 143,  10,  70, 195, 124, 249, 181,  48,  45, 168, 228,  97,
        148,  17,  93, 216, 197,  64,  12, 137,  54, 179, 255, 122, 103, 226, 174,  43,  19, 150, 218,  95,  66, 199, 139,  14, 177,  52, 120, 253, 224, 101,  41, 172,
        178,  55, 123, 254, 227, 102,  42, 175,  16, 149, 217,  92,  65, 196, 136,  13,  53, 176, 252, 121, 100, 225, 173,  40, 151,  18,  94, 219, 198,  67,  15, 138,
        127, 250, 182,  51,  46, 171, 231,  98, 221,  88,  20, 145, 140,   9,  69, 192, 248, 125,  49, 180, 169,  44,  96, 229,  90, 223, 147,  22,  11, 142, 194,  71,
        235, 110,  34, 167, 186,  63, 115, 246,  73, 204, 128,   5,  24, 157, 209,  84, 108, 233, 165,  32,  61, 184, 244, 113, 206,  75,   7, 130, 159,  26,  86, 211,
        38, 163, 239, 106, 119, 242, 190,  59, 132,   1,  77, 200, 213,  80,  28, 153, 161,  36, 104, 237, 240, 117,  57, 188,   3, 134, 202,  79,  82, 215, 155,  30},
    {   0, 148, 235, 127,  21, 129, 254, 106,  42, 190, 193,  85,  63, 171, 212,  64,  84, 192, 191,  43,  65, 213, 170,  62, 126, 234, 149,   1, 107, 255, 128,  20,
        168,  60,  67, 215, 189,  41,  86, 194, 130,  22, 105, 253, 151,   3, 124, 232, 252, 104,  23, 131, 233, 125,   2, 150, 214,  66,  61, 169, 195,  87,  40, 188,
        147,   7, 120, 236, 134,  18, 109, 249, 185,  45,  82, 198, 172,  56,  71, 211, 199,  83,  44, 184, 210,  70,  57, 173, 237, 121,   6, 146, 248, 108,  19, 135,
        59, 175, 208,  68,  46, 186, 197,  81,  17, 133, 250, 110,   4, 144, 239, 123, 111, 251, 132,  16, 122, 238, 145,   5,  69, 209, 174,  58,  80, 196, 187,  47,
        229, 113,  14, 154, 240, 100,  27, 143, 207,  91,  36, 176, 218,  78,  49, 165, 177,  37,  90, 206, 164,  48,  79, 219, 155,  15, 112, 228, 142,  26, 101, 241,
        77, 217, 166,  50,  88, 204, 179,  39, 103, 243, 140,  24, 114, 230, 153,  13,  25, 141, 242, 102,  12, 152, 231, 115,  51, 167, 216,  76,  38, 178, 205,  89,
        118, 226, 157,   9,  99, 247, 136,  28,  92, 200, 183,  35,  73, 221, 162,  54,  34, 182, 201,  93,  55, 163, 220,  72,   8, 156, 227, 119,  29, 137, 246,  98,
        222,  74,  53, 161, 203,  95,  32, 180, 244,  96,  31, 139, 225, 117,  10, 158, 138,  30,  97, 245, 159,  11, 116, 224, 160,  52,  75, 223, 181,  33,  94, 202},
    {   0, 192,  67, 131, 134,  70, 197,   5, 207,  15, 140,  76,  73, 137,  10, 202,  93, 157,  30, 222, 219,  27, 152,  88, 146,  82, 209,  17,  20, 212,  87, 151,
        186, 122, 249,  57,  60, 252, 127, 191, 117, 181,  54, 246, 243,  51, 176, 112, 231,  39, 164, 100,  97, 161,  34, 226,  40, 232, 107, 171, 174, 110, 237,  45,
        183, 119, 244,  52,  49, 241, 114, 178, 120, 184,  59, 251, 254,  62, 189, 125, 234,  42, 169, 105, 108, 172,  47, 239,  37, 229, 102, 166, 163,  99, 224,  32,
        13, 205,  78, 142, 139,  75, 200,   8, 194,   2, 129,  65,  68, 132,   7, 199,  80, 144,  19, 211, 214,  22, 149,  85, 159,  95, 220,  28,  25, 217,  90, 154,
        173, 109, 238,  46,  43, 235, 104, 168,  98, 162,  33, 225, 228,  36, 167, 103, 240,  48, 179, 115, 118, 182,  53, 245,  63, 255, 124, 188, 185, 121, 250,  58,
        23, 215,  84, 148, 145,  81, 210,  18, 216,  24, 155,  91,  94, 158,  29, 221,  74, 138,   9, 201, 204,  12, 143,  79, 133,  69, 198,   6,   3, 195,  64, 128,
        26, 218,  89, 153, 156,  92, 223,  31, 213,  21, 150,  86,  83, 147,  16, 208,  71, 135,   4, 196, 193,   1, 130,  66, 136,  72, 203,  11,  14, 206,  77, 141,
        160,  96, 227,  35,  38, 230, 101, 165, 111, 175,  44, 236, 233,  41, 170, 106, 253,  61, 190, 126, 123, 187,  56, 248,  50, 242, 113, 177, 180, 116, 247,  55},
    {   0, 194,  71, 133, 142,  76, 201,  11, 223,  29, 152,  90,  81, 147,  22, 212, 125, 191,  58, 248, 243,  49, 180, 118, 162,  96, 229,  39,  44, 238, 107, 169,
        250,  56, 189, 127, 116, 182,  51, 241,  37, 231,  98, 160, 171, 105, 236,  46, 135,  69, 192,   2,   9, 203,  78, 140,  88, 154,  31, 221, 214,  20, 145,  83,
        55, 245, 112, 178, 185, 123, 254,  60, 232,  42, 175, 109, 102, 164,  33, 227,  74, 136,  13, 207, 196,   6, 131,  65, 149,  87, 210,  16,  27, 217,  92, 158,
        205,  15, 138,  72,  67, 129,   4, 198,  18, 208,  85, 151, 156,  94, 219,  25, 176, 114, 247,  53,  62, 252, 121, 187, 111, 173,  40, 234, 225,  35, 166, 100,
        110, 172,  41, 235, 224,  34, 167, 101, 177, 115, 246,  52,  63, 253, 120, 186,  19, 209,  84, 150, 157,  95, 218,  24, 204,  14, 139,  73,  66, 128,   5, 199,
        148,  86, 211,  17,  26, 216,  93, 159,  75, 137,  12, 206, 197,   7, 130,  64, 233,  43, 174, 108, 103, 165,  32, 226,  54, 244, 113, 179, 184, 122, 255,  61,
        89, 155,  30, 220, 215,  21, 144,  82, 134,  68, 193,   3,   8, 202,  79, 141,  36, 230,  99, 161, 170, 104, 237,  47, 251,  57, 188, 126, 117, 183,  50, 240,
        163,  97, 228,  38,  45, 239, 106, 168, 124, 190,  59, 249, 242,  48, 181, 119, 222,  28, 153,  91,  80, 146,  23, 213,   1, 195,  70, 132, 143,  77, 200,  10},
    {   0, 251,  53, 206, 106, 145,  95, 164, 212,  47, 225,  26, 190,  69, 139, 112, 107, 144,  94, 165,   1, 250,  52, 207, 191,  68, 138, 113, 213,  46, 224,  27,
        214,  45, 227,  24, 188,  71, 137, 114,   2, 249,  55, 204, 104, 147,  93, 166, 189,  70, 136, 115, 215,  44, 226,  25, 105, 146,  92, 167,   3, 248,  54, 205,
        111, 148,  90, 161,   5, 254,  48, 203, 187,  64, 142, 117, 209,  42, 228,  31,   4, 255,  49, 202, 110, 149,  91, 160, 208,  43, 229,  30, 186,  65, 143, 116,
        185,  66, 140, 119, 211,  40, 230,  29, 109, 150,  88, 163,   7, 252,  50, 201, 210,  41, 231,  28, 184,  67, 141, 118,   6, 253,  51, 200, 108, 151,  89, 162,
        222,  37, 235,  16, 180,  79, 129, 122,  10, 241,  63, 196,  96, 155,  85, 174, 181,  78, 128, 123, 223,  36, 234,  17,  97, 154,  84, 175,  11, 240,  62, 197,
        8, 243,  61, 198,  98, 153,  87, 172, 220,  39, 233,  18, 182,  77, 131, 120,  99, 152,  86, 173,   9, 242,  60, 199, 183,  76, 130, 121, 221,  38, 232,  19,
        177,  74, 132, 127, 219,  32, 238,  21, 101, 158,  80, 171,  15, 244,  58, 193, 218,  33, 239,  20, 176,  75, 133, 126,  14, 245,  59, 192, 100, 159,  81, 170,
        103, 156,  82, 169,  13, 246,  56, 195, 179,  72, 134, 125, 217,  34, 236,  23,  12, 247,  57, 194, 102, 157,  83, 168, 216,  35, 237,  22, 178,  73, 135, 124}
};

/*****************************************************************************/
/* Key Expansion       :                                                     */
/*****************************************************************************/

static state_t C[32] = {
    {0x6e, 0xa2, 0x76, 0x72, 0x6c, 0x48, 0x7a, 0xb8, 0x5d, 0x27, 0xbd, 0x10, 0xdd, 0x84, 0x94, 0x01},
    {0xdc, 0x87, 0xec, 0xe4, 0xd8, 0x90, 0xf4, 0xb3, 0xba, 0x4e, 0xb9, 0x20, 0x79, 0xcb, 0xeb, 0x02},
    {0xb2, 0x25, 0x9a, 0x96, 0xb4, 0xd8, 0x8e, 0x0b, 0xe7, 0x69, 0x04, 0x30, 0xa4, 0x4f, 0x7f, 0x03},
    {0x7b, 0xcd, 0x1b, 0x0b, 0x73, 0xe3, 0x2b, 0xa5, 0xb7, 0x9c, 0xb1, 0x40, 0xf2, 0x55, 0x15, 0x04},
    {0x15, 0x6f, 0x6d, 0x79, 0x1f, 0xab, 0x51, 0x1d, 0xea, 0xbb, 0x0c, 0x50, 0x2f, 0xd1, 0x81, 0x05},
    {0xa7, 0x4a, 0xf7, 0xef, 0xab, 0x73, 0xdf, 0x16, 0x0d, 0xd2, 0x08, 0x60, 0x8b, 0x9e, 0xfe, 0x06},
    {0xc9, 0xe8, 0x81, 0x9d, 0xc7, 0x3b, 0xa5, 0xae, 0x50, 0xf5, 0xb5, 0x70, 0x56, 0x1a, 0x6a, 0x07},
    {0xf6, 0x59, 0x36, 0x16, 0xe6, 0x05, 0x56, 0x89, 0xad, 0xfb, 0xa1, 0x80, 0x27, 0xaa, 0x2a, 0x08},
    {0x98, 0xfb, 0x40, 0x64, 0x8a, 0x4d, 0x2c, 0x31, 0xf0, 0xdc, 0x1c, 0x90, 0xfa, 0x2e, 0xbe, 0x09},
    {0x2a, 0xde, 0xda, 0xf2, 0x3e, 0x95, 0xa2, 0x3a, 0x17, 0xb5, 0x18, 0xa0, 0x5e, 0x61, 0xc1, 0x0a},
    {0x44, 0x7c, 0xac, 0x80, 0x52, 0xdd, 0xd8, 0x82, 0x4a, 0x92, 0xa5, 0xb0, 0x83, 0xe5, 0x55, 0x0b},
    {0x8d, 0x94, 0x2d, 0x1d, 0x95, 0xe6, 0x7d, 0x2c, 0x1a, 0x67, 0x10, 0xc0, 0xd5, 0xff, 0x3f, 0x0c},
    {0xe3, 0x36, 0x5b, 0x6f, 0xf9, 0xae, 0x07, 0x94, 0x47, 0x40, 0xad, 0xd0, 0x08, 0x7b, 0xab, 0x0d},
    {0x51, 0x13, 0xc1, 0xf9, 0x4d, 0x76, 0x89, 0x9f, 0xa0, 0x29, 0xa9, 0xe0, 0xac, 0x34, 0xd4, 0x0e},
    {0x3f, 0xb1, 0xb7, 0x8b, 0x21, 0x3e, 0xf3, 0x27, 0xfd, 0x0e, 0x14, 0xf0, 0x71, 0xb0, 0x40, 0x0f},
    {0x2f, 0xb2, 0x6c, 0x2c, 0x0f, 0x0a, 0xac, 0xd1, 0x99, 0x35, 0x81, 0xc3, 0x4e, 0x97, 0x54, 0x10},
    {0x41, 0x10, 0x1a, 0x5e, 0x63, 0x42, 0xd6, 0x69, 0xc4, 0x12, 0x3c, 0xd3, 0x93, 0x13, 0xc0, 0x11},
    {0xf3, 0x35, 0x80, 0xc8, 0xd7, 0x9a, 0x58, 0x62, 0x23, 0x7b, 0x38, 0xe3, 0x37, 0x5c, 0xbf, 0x12},
    {0x9d, 0x97, 0xf6, 0xba, 0xbb, 0xd2, 0x22, 0xda, 0x7e, 0x5c, 0x85, 0xf3, 0xea, 0xd8, 0x2b, 0x13},
    {0x54, 0x7f, 0x77, 0x27, 0x7c, 0xe9, 0x87, 0x74, 0x2e, 0xa9, 0x30, 0x83, 0xbc, 0xc2, 0x41, 0x14},
    {0x3a, 0xdd, 0x01, 0x55, 0x10, 0xa1, 0xfd, 0xcc, 0x73, 0x8e, 0x8d, 0x93, 0x61, 0x46, 0xd5, 0x15},
    {0x88, 0xf8, 0x9b, 0xc3, 0xa4, 0x79, 0x73, 0xc7, 0x94, 0xe7, 0x89, 0xa3, 0xc5, 0x09, 0xaa, 0x16},
    {0xe6, 0x5a, 0xed, 0xb1, 0xc8, 0x31, 0x09, 0x7f, 0xc9, 0xc0, 0x34, 0xb3, 0x18, 0x8d, 0x3e, 0x17},
    {0xd9, 0xeb, 0x5a, 0x3a, 0xe9, 0x0f, 0xfa, 0x58, 0x34, 0xce, 0x20, 0x43, 0x69, 0x3d, 0x7e, 0x18},
    {0xb7, 0x49, 0x2c, 0x48, 0x85, 0x47, 0x80, 0xe0, 0x69, 0xe9, 0x9d, 0x53, 0xb4, 0xb9, 0xea, 0x19},
    {0x05, 0x6c, 0xb6, 0xde, 0x31, 0x9f, 0x0e, 0xeb, 0x8e, 0x80, 0x99, 0x63, 0x10, 0xf6, 0x95, 0x1a},
    {0x6b, 0xce, 0xc0, 0xac, 0x5d, 0xd7, 0x74, 0x53, 0xd3, 0xa7, 0x24, 0x73, 0xcd, 0x72, 0x01, 0x1b},
    {0xa2, 0x26, 0x41, 0x31, 0x9a, 0xec, 0xd1, 0xfd, 0x83, 0x52, 0x91, 0x03, 0x9b, 0x68, 0x6b, 0x1c},
    {0xcc, 0x84, 0x37, 0x43, 0xf6, 0xa4, 0xab, 0x45, 0xde, 0x75, 0x2c, 0x13, 0x46, 0xec, 0xff, 0x1d},
    {0x7e, 0xa1, 0xad, 0xd5, 0x42, 0x7c, 0x25, 0x4e, 0x39, 0x1c, 0x28, 0x23, 0xe2, 0xa3, 0x80, 0x1e},
    {0x10, 0x03, 0xdb, 0xa7, 0x2e, 0x34, 0x5f, 0xf6, 0x64, 0x3b, 0x95, 0x33, 0x3f, 0x27, 0x14, 0x1f},
    {0x5e, 0xa7, 0xd8, 0x58, 0x1e, 0x14, 0x9b, 0x61, 0xf1, 0x6a, 0xc1, 0x45, 0x9c, 0xed, 0xa8, 0x20}};

static void AddRoundKey_KS(uint8_t round)
{
    uint8_t i;
    for(i=0;i<16;++i)
  {
    stateDuringKS[i] ^= C[round][i];
  }
}


static void Sstep_KS(void)
{
    uint8_t i;
    for(i = 0; i < 16; ++i)
  {
    stateDuringKS[i] = getSBoxValue(stateDuringKS[i]);
  }
}

static void Rstep_KS(void)
{
    uint8_t i;
    state_t stateCopy;
    for(i=0;i<16;i++)
    {
      stateCopy[i] = stateDuringKS[i];
    }
    for(i=0;i<16;i++)
    {
        if(i==0)
        {
            stateDuringKS[i] = mult_mod_poly[4][stateCopy[0]] ^ mult_mod_poly[2][stateCopy[1]] ^ mult_mod_poly[3][stateCopy[2]] ^ mult_mod_poly[1][stateCopy[3]] ^ mult_mod_poly[6][stateCopy[4]] ^ mult_mod_poly[5][stateCopy[5]] ^ mult_mod_poly[0][stateCopy[6]] ^ mult_mod_poly[7][stateCopy[7]] ^ mult_mod_poly[0][stateCopy[8]] ^ mult_mod_poly[5][stateCopy[9]] ^ mult_mod_poly[6][stateCopy[10]] ^ mult_mod_poly[1][stateCopy[11]] ^ mult_mod_poly[3][stateCopy[12]] ^ mult_mod_poly[2][stateCopy[13]] ^ mult_mod_poly[4][stateCopy[14]] ^ mult_mod_poly[0][stateCopy[15]];
        }
        else
        {
            stateDuringKS[i] = stateCopy[i-1];
        }    
    }
}


static void Lstep_KS(void)
{
    uint8_t i;
    for(i=0;i<16;i++)
    {
        Rstep_KS();
    }
}



// This function produces the algorithm round keys. The round keys are used in each round to decrypt the states. 
static void KeyExpansion(void)
{
  uint8_t i,j;
  uint8_t div = 0x2;
  state_t tempState2;

  // The first two round keys are the first and second half of the key.
  for(i=0;i<16;i++)
  {
    RoundKey[0][i] = Key[i];
  }
  
  for(i=0;i<16;i++)
  {
    RoundKey[1][i] = Key[i+16];  
  }

  for(i=2;i<65;i=i+2)
  {
    for(j=0; j<16; j++)
    {
      stateDuringKS[j] = RoundKey[i-2][j];
      tempState2[j] = RoundKey[i-1][j];
      RoundKey[i+1][j] = stateDuringKS[j];
    }
    uint8_t k = (uint8_t)((i/div)-1);
    AddRoundKey_KS(k);
    Sstep_KS();
    Lstep_KS();

    for(j=0; j<16; j++)
    {
        stateDuringKS[j] ^= tempState2[j];
    }
    for(j=0; j<16; j++)
    {
      RoundKey[i][j] = stateDuringKS[j];
    }
  }
  
  for(j=0; j<16; j++)
  {
    trueRoundKey[0][j] = RoundKey[0][j];
    trueRoundKey[1][j] = RoundKey[1][j];
    trueRoundKey[2][j] = RoundKey[16][j];
    trueRoundKey[3][j] = RoundKey[17][j];
    trueRoundKey[4][j] = RoundKey[32][j];
    trueRoundKey[5][j] = RoundKey[33][j];
    trueRoundKey[6][j] = RoundKey[48][j];
    trueRoundKey[7][j] = RoundKey[49][j];
    trueRoundKey[8][j] = RoundKey[64][j];
    trueRoundKey[9][j] = RoundKey[65][j];
  }


}


/*****************************************************************************/
/* X-STEP                                                                    */
/*****************************************************************************/

// This function adds the round key to state.
// The round key is added to the state by an XOR function.
static void AddRoundKey(uint8_t round)
{
  uint8_t i;
  for(i=0;i<16;++i)
  {
    (*state)[i] ^= trueRoundKey[round][i];
  }
}

/*****************************************************************************/
/* S-STEP                                                                    */
/*****************************************************************************/

// The SStep Function Substitutes the values in the current state with values in an S-box.

/*
static void Sstep(void)
{
  uint8_t i;
  for(i = 0; i < 16; ++i)
  {
    (*state)[i] = getSBoxValue((*state)[i]);
  }
}
*/
/*
// Inverse Sstep
static void InvSstep(void)
{
  uint8_t i;
  for(i=0;i<16;++i)
  {
    (*state)[i] = getSBoxInvert((*state)[i]);
  }
}
*/
static void masked_Sstep(void)
{
  uint8_t i;
  for(i = 0; i<16; i++)
  {
    (*state)[i] = getMaskedSBoxValue((*state)[i], mask[i]);
  }
}

static void masked_InvSstep(void)
{
  uint8_t i;
  for(i = 0; i<16; ++i)
  {
    (*state)[i] = getMaskedSBoxInvert((*state)[i], mask[i]);
  }
}

/*****************************************************************************/
/* R-STEP                                                                    */
/*****************************************************************************/

static void Rstep(void)
{
    state_t stateCopy;
    for(int j=0; j<16; j++)
    {
      stateCopy[j] = (*state)[j];
    }
    for(int i=0;i<16;i++)
    {
        if(i==0)
        {
            (*state)[i] = mult_mod_poly[4][stateCopy[0]] ^ mult_mod_poly[2][stateCopy[1]] ^ mult_mod_poly[3][stateCopy[2]] ^ mult_mod_poly[1][stateCopy[3]] ^ mult_mod_poly[6][stateCopy[4]] ^ mult_mod_poly[5][stateCopy[5]] ^ mult_mod_poly[0][stateCopy[6]] ^ mult_mod_poly[7][stateCopy[7]] ^ mult_mod_poly[0][stateCopy[8]] ^ mult_mod_poly[5][stateCopy[9]] ^ mult_mod_poly[6][stateCopy[10]] ^ mult_mod_poly[1][stateCopy[11]] ^ mult_mod_poly[3][stateCopy[12]] ^ mult_mod_poly[2][stateCopy[13]] ^ mult_mod_poly[4][stateCopy[14]] ^ mult_mod_poly[0][stateCopy[15]];
        }
        else
        {
            (*state)[i] = stateCopy[i-1];
        }    
    }
}

static void InvRstep(void)
{
    uint8_t i;
    state_t stateCopy;
    for(int j=0; j<16; j++)
    {
      stateCopy[j] = (*state)[j];
    }
    for(i=0;i<16;i++)
    {
        if(i==15)
        {
            (*state)[i] = mult_mod_poly[4][stateCopy[1]] ^ mult_mod_poly[2][stateCopy[2]] ^ mult_mod_poly[3][stateCopy[3]] ^ mult_mod_poly[1][stateCopy[4]] ^ mult_mod_poly[6][stateCopy[5]] ^ mult_mod_poly[5][stateCopy[6]] ^ mult_mod_poly[0][stateCopy[7]] ^ mult_mod_poly[7][stateCopy[8]] ^ mult_mod_poly[0][stateCopy[9]] ^ mult_mod_poly[5][stateCopy[10]] ^ mult_mod_poly[6][stateCopy[11]] ^ mult_mod_poly[1][stateCopy[12]] ^ mult_mod_poly[3][stateCopy[13]] ^ mult_mod_poly[2][stateCopy[14]] ^ mult_mod_poly[4][stateCopy[15]] ^ mult_mod_poly[0][stateCopy[0]];
            
        }
        else
        {
            (*state)[i] = stateCopy[i+1];
        }
        
    }
}

static void maskRstep(void)
{
    state_t maskCopy;
    for(int j=0; j<16; j++)
    {
      maskCopy[j] = mask[j];
    }
    for(int i=0;i<16;i++)
    {
        if(i==0)
        {
            mask[i] = mult_mod_poly[4][maskCopy[0]] ^ mult_mod_poly[2][maskCopy[1]] ^ mult_mod_poly[3][maskCopy[2]] ^ mult_mod_poly[1][maskCopy[3]] ^ mult_mod_poly[6][maskCopy[4]] ^ mult_mod_poly[5][maskCopy[5]] ^ mult_mod_poly[0][maskCopy[6]] ^ mult_mod_poly[7][maskCopy[7]] ^ mult_mod_poly[0][maskCopy[8]] ^ mult_mod_poly[5][maskCopy[9]] ^ mult_mod_poly[6][maskCopy[10]] ^ mult_mod_poly[1][maskCopy[11]] ^ mult_mod_poly[3][maskCopy[12]] ^ mult_mod_poly[2][maskCopy[13]] ^ mult_mod_poly[4][maskCopy[14]] ^ mult_mod_poly[0][maskCopy[15]];
        }
        else
        {
            mask[i] = maskCopy[i-1];
        }    
    }
}

static void maskInvRstep(void)
{
    uint8_t i;
    state_t maskCopy;
    for(int j=0; j<16; j++)
    {
      maskCopy[j] = mask[j];
    }
    for(i=0;i<16;i++)
    {
        if(i==15)
        {
            mask[i] = mult_mod_poly[4][maskCopy[1]] ^ mult_mod_poly[2][maskCopy[2]] ^ mult_mod_poly[3][maskCopy[3]] ^ mult_mod_poly[1][maskCopy[4]] ^ mult_mod_poly[6][maskCopy[5]] ^ mult_mod_poly[5][maskCopy[6]] ^ mult_mod_poly[0][maskCopy[7]] ^ mult_mod_poly[7][maskCopy[8]] ^ mult_mod_poly[0][maskCopy[9]] ^ mult_mod_poly[5][maskCopy[10]] ^ mult_mod_poly[6][maskCopy[11]] ^ mult_mod_poly[1][maskCopy[12]] ^ mult_mod_poly[3][maskCopy[13]] ^ mult_mod_poly[2][maskCopy[14]] ^ mult_mod_poly[4][maskCopy[15]] ^ mult_mod_poly[0][maskCopy[0]];
        }
        else
        {
            mask[i] = maskCopy[i+1];
        }
        
    }
}



/*****************************************************************************/
/* L-STEP                                                                    */
/*****************************************************************************/

static void Lstep(void)
{
    uint8_t i;
    for(i=0;i<16;i++)
    {
        Rstep();
    }
}

static void InvLstep(void)
{
    uint8_t i;
    for(i=0;i<16;i++)
    {
        InvRstep();
    }
}

static void mask_Lstep(void)
{
    uint8_t i;
    for(i=0;i<16;i++)
    {
        maskRstep();
    }
}

static void mask_InvLstep(void)
{
    uint8_t i;
    for(i=0;i<16;i++)
    {
        maskInvRstep();
    }
}



/*****************************************************************************/
/* Encryption and Decrytion                                                  */
/*****************************************************************************/

// Cipher is the main function that encrypts the PlainText.
static void Cipher(void)
{
  uint8_t round;

  for(round = 0; round < 9; round++)
  {
    AddRoundKey(round);
    masked_Sstep();
    Lstep();
    mask_Lstep();
  }
  
  AddRoundKey(9);

}

static void InvCipher(void)
{
  uint8_t round=0;

  for(round=9;round>0;round--)
  {
    mask_InvLstep();
    AddRoundKey(round);
    InvLstep();
    masked_InvSstep();
  }
  AddRoundKey(0);
  
}

/*
static void BlockCopy(uint8_t* output, const uint8_t* input)
{
  uint8_t i;
  for (i=0;i<STATELEN;i++)
  {
    output[i] = input[i];
  }
}
*/


/*****************************************************************************/
/* Public functions:                                                         */
/*****************************************************************************/

void kuznyechik_setkey(uint8_t* key)
{
  Key = key;

  KeyExpansion();
}

void masked_kuznyechik_crypto(uint8_t* input)
{
  state = (state_t*)input;

  genMask();

  maskState();

  Cipher();

  maskState();
}

void masked_kuznyechik_decrypto(uint8_t* input)
{
  state = (state_t*)input;

  genMask();

  maskState();

  InvCipher();

  maskState();
}


/*
void kuznyechik_encrypt(uint8_t* input, uint8_t* key, uint8_t* output)
{ 
  // 
  //for(int i=0; i<16; i++)
  //{
  //  output[i] = input[i];
  //}
  output = input;

  state = (state_t*)output;

  Key = key;
  KeyExpansion();

  // The next function call encrypts the PlainText with the Key using AES algorithm.
  Cipher();
}

void kuznyechik_decrypt(uint8_t* input, uint8_t* key, uint8_t *output)
{
  // Copy input to output, and work in-memory on output
  BlockCopy(output, input);
  state = (state_t*)output;

  // The KeyExpansion routine must be called before encryption.
  Key = key;
  KeyExpansion();

  InvCipher();
}
*/