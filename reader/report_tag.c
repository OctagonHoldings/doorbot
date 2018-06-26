#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stddef.h>
#include<syslog.h>
#include<unistd.h>
#include<time.h>

// libnfc includes
#include<nfc/nfc.h>
#include<nfc/nfc-types.h>

// libfreefare includes
#include<freefare.h>

#define err_chk(cond) if(cond) { goto err; }
#define BUF_LEN 512

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
    char * buffer;
    char * piece;
    struct timeval start;
    struct timeval end;
    struct timeval res;

    nfc_init(&context);
    dev = nfc_open(context, NULL);
    nfc_initiator_init(dev);
    success = 0;
    piece = calloc(BUF_LEN,1); // Should be big enough >_<
    if(!piece) { syslog(LOG_ERR, "Cannot allocate memory"); exit(1); }
    buffer = calloc(BUF_LEN,1); // Should be big enough >_<
    if(!buffer) { syslog(LOG_ERR, "Cannot allocate memory"); exit(1); }
    while(1)
    {
reset:
        i = nfc_initiator_poll_target(dev, modulations, modulations_size, 20, 1, &target);
        if(i != 1)
        {
            syslog(LOG_ERR, "nfc_initiator_poll_target returned %d instead of 1!\n", i);
            if(i == -90)
                goto reset;
            return -1;
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
            snprintf(buffer, BUF_LEN, "%d", clipper_id);
            printf("t:c%s\n", buffer);
            fflush(stdout);
            syslog(LOG_NOTICE, "clipper card successfully read (c%s)\n", buffer);
            success = 1;
not_valid:
            if(aids) { mifare_desfire_free_application_ids(aids); }
            if(clipper && clipper != (void *) -1) { freefare_free_tags(clipper); }
            if(!success)
            {
                syslog(LOG_NOTICE, "mifare read failed\n");
                goto reset;
            }
            success = 0;
        }
        else if(target.nti.nai.abtAtqa[0] == 0)
        {
            syslog(LOG_NOTICE, "Attempting to read generic RFID... ");
            snprintf(piece, BUF_LEN, "0x");
            strncpy(buffer, piece, BUF_LEN);
            for(i = 0;i < target.nti.nai.szUidLen;i++)
            {
                snprintf(piece, BUF_LEN, "%0x", target.nti.nai.abtUid[i]);
                strncat(buffer, piece, BUF_LEN);
            }
            printf("t:%s\n", buffer);
            fflush(stdout);
            syslog(LOG_NOTICE, "read RFID %s", buffer);
        }
        syslog(LOG_NOTICE, "Waiting to determine if card is held...");
        gettimeofday(&start, NULL);
        usleep(500000);
        while(nfc_initiator_target_is_present(dev, NULL) == 0) { usleep(100000); }
        gettimeofday(&end, NULL);
        timersub(&end, &start, &res);
        syslog(LOG_NOTICE, "tag held for %d seconds and %d microseconds", res.tv_sec, res.tv_usec);
        if(res.tv_sec >= 3)
        {
            if(clipper_id)
                printf("h:c%s\n", buffer);
            else
                printf("h:%s\n", buffer);
            syslog(LOG_NOTICE, "tag (%s) held for at least 3 seconds, sending hold signal", buffer);
        }
        clipper_id = 0;
        memset(buffer, '\0', BUF_LEN);
    }

err:
    exit(EXIT_FAILURE);
}
