#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stddef.h>

// libnfc includes
#include<nfc/nfc.h>
#include<nfc/nfc-types.h>

// libfreefare includes


#define err_chk(cond) if(cond) { goto err; }

int main()
{
    nfc_context * context = NULL;
    nfc_device * dev = NULL;
    nfc_modulation modulations[5] = {
        { .nmt = NMT_ISO14443A, .nbr = NBR_106 },
        { .nmt = NMT_ISO14443B, .nbr = NBR_106 },
        { .nmt = NMT_FELICA, .nbr = NBR_212 },
        { .nmt = NMT_FELICA, .nbr = NBR_424 },
        { .nmt = NMT_JEWEL, .nbr = NBR_106 },
    };
    size_t modulations_size = 5;
    nfc_target target;
    
    nfc_init(&context);
    dev = nfc_open(context, NULL);
    nfc_initiator_init(dev);
    while(1)
    {
        nfc_initiator_poll_target(dev, modulations, modulations_size, 20, 1, &target);
        printf("NFC tagged, type %d\n", target.nm.nmt);
        while(nfc_initiator_target_is_present(dev, NULL) == 0) {}
    }

err:
    exit(EXIT_FAILURE);
}
