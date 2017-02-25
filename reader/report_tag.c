#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stddef.h>

// libnfc includes
#include<nfc/nfc.h>
#include<nfc/nfc-types.h>

// libfreefare includes
#include<freefare.h>

#define err_chk(cond) if(cond) { goto err; }

int main()
{
    nfc_context * context = NULL;
    nfc_device * dev = NULL;
    nfc_modulation modulations[1] = {
        { .nmt = NMT_ISO14443A, .nbr = NBR_106 },
    };
    size_t modulations_size = 1;
    nfc_target target;
    MifareTag * clipper;
    int i, j, ret;
    uint32_t clipper_id;

    nfc_init(&context);
    dev = nfc_open(context, NULL);
    nfc_initiator_init(dev);
    while(1)
    {
        i = nfc_initiator_poll_target(dev, modulations, modulations_size, 20, 1, &target);
        if(i != 1)
            continue;
        if(target.nti.nai.abtAtqa[0] == 3 && target.nti.nai.abtAtqa[1] == 68) // mifare desfire card.  Probably.
        {
            MifareDESFireAID * aids = 0;
	    clipper = 0;
            clipper_id = 0;
            clipper = freefare_get_tags(dev);
	    if(clipper == -1) { goto not_valid; }
            ret = mifare_desfire_connect(clipper[0]);
	    if(ret == -1) { goto not_valid; }
            ret = mifare_desfire_get_application_ids(clipper[0], &aids, &j);
	    if(ret == -1) { goto not_valid; }
            ret = mifare_desfire_select_application(clipper[0], aids[0]);
	    if(ret == -1) { goto not_valid; }
            ret = mifare_desfire_read_data(clipper[0], 8, 1, 4, &clipper_id);
	    if(ret != 4) { goto not_valid; }
            clipper_id = ntohl(clipper_id);
	    if(clipper_id == 0) { goto not_valid; }
            printf("c%d\n", clipper_id);
            fflush(stdout);
not_valid:
            if(aids) { mifare_desfire_free_application_ids(aids); }
            if(clipper && clipper != -1) { freefare_free_tags(clipper); }
        }
        else if(target.nti.nai.abtAtqa[0] == 0)
        {
            printf("0x");
            for(i = 0;i < target.nti.nai.szUidLen;i++)
                printf("%0x", target.nti.nai.abtUid[i]);
            printf("\n");
            fflush(stdout);
        }
        while(nfc_initiator_target_is_present(dev, NULL) == 0) {}
    }

err:
    exit(EXIT_FAILURE);
}
