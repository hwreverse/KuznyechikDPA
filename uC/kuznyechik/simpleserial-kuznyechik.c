#include "kuznyechik.h"
#include "hal.h"
#include "simpleserial.h"
#include <stdint.h>
#include <stdlib.h>

uint8_t get_key(uint8_t* k)
{
	kuznyechik_setkey(k);
	return 0x00;
}

uint8_t get_pt(uint8_t* pt)
{
	trigger_high();
	kuznyechik_crypto(pt); /* encrypting the data block */
	trigger_low();
	simpleserial_put('r', 16, pt);
	return 0x00;
}

uint8_t get_dc(uint8_t* pt)
{
    trigger_high();
    kuznyechik_decrypto(pt);
    trigger_low();
    simpleserial_put('r', 16, pt);
    return 0x00;
}

uint8_t reset(uint8_t* x)
{
    // Reset key here if needed
	return 0x00;
}

int main(void)
{
	uint8_t tmp[32] = {0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10, 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef}; //Default key

    platform_init();
    init_uart();
    trigger_setup();

	kuznyechik_setkey((uint8_t*) tmp);

    /* Uncomment this to get a HELLO message for debug */
    
    putch('h');
    putch('e');
    putch('l');
    putch('l');
    putch('o');
    putch('\n');
    
	
    simpleserial_init();
    simpleserial_addcmd('k', 32, get_key);
    simpleserial_addcmd('p', 16,  get_pt);
    simpleserial_addcmd('d', 16,  get_dc);
    simpleserial_addcmd('x',  0,   reset);
    //simpleserial_addcmd('m', 18, get_mask);
    while(1)
        simpleserial_get();
}
