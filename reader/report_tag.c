#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stddef.h>
#include<syslog.h>
#include<unistd.h>

// libnfc includes
#include<nfc/nfc.h>
#include<nfc/nfc-types.h>

// libfreefare includes
#include<freefare.h>

#define err_chk(cond) if(cond) { goto err; }

int main()
{
    openlog("doorbot-reader", LOG_NDELAY | LOG_PID, LOG_USER);
    nfc_context * context = NULL;
    nfc_device * dev = NULL;
    nfc_modulation modulations[1] = {
        { .nmt = NMT_ISO14443A, .nbr = NBR_106 },
    };
    size_t modulations_size = 1;
    nfc_target target;
    MifareTag * clipper;
    int i, j, ret;
    int success;
    uint32_t clipper_id;

    nfc_init(&context);
    dev = nfc_open(context, NULL);
    nfc_initiator_init(dev);
    success = 0;
    while(1)
    {
        i = nfc_initiator_poll_target(dev, modulations, modulations_size, 20, 1, &target);
        if(i != 1)
        {
            syslog(LOG_ERR, "nfc_initiator_poll_target returned %d instead of 1!\n", i);
            continue;
        }
        if(target.nti.nai.abtAtqa[0] == 3 && target.nti.nai.abtAtqa[1] == 68) // mifare desfire card.  Probably.
        {
            syslog(LOG_NOTICE, "Attempting to read mifare card... ");
            MifareDESFireAID * aids = 0;
            clipper = 0;
            clipper_id = 0;
            clipper = freefare_get_tags(dev);
            if(!clipper) { goto not_valid; }
            if(clipper[0] == NULL) { goto not_valid; }
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
            printf("t:c%d\n", clipper_id);
            fflush(stdout);
            syslog(LOG_NOTICE, "clipper card successfully read (c%d)\n", clipper_id);
            success = 1;
not_valid:
            if(aids) { mifare_desfire_free_application_ids(aids); }
            if(clipper && clipper != (void *) -1) { freefare_free_tags(clipper); }
            if(!success)
                syslog(LOG_NOTICE, "mifare read failed\n");
            success = 0;
        }
        else if(target.nti.nai.abtAtqa[0] == 0)
        {
            syslog(LOG_NOTICE, "Attempting to read generic RFID... ");
            printf("t:0x");
            for(i = 0;i < target.nti.nai.szUidLen;i++)
                printf("%0x", target.nti.nai.abtUid[i]);
            printf("\n");
            fflush(stdout);
            syslog(LOG_NOTICE, "read RFID");
        }
        usleep(500000);
        while(nfc_initiator_target_is_present(dev, NULL) == 0) { syslog(LOG_NOTICE, "Card still present, sleeping...\n"); usleep(500000); }
    }

err:
    exit(EXIT_FAILURE);
}
