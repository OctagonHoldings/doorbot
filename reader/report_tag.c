#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stddef.h>
#include<syslog.h>
#include<unistd.h>
#include<time.h>
#include<setjmp.h>
#include<signal.h>

// libnfc includes
#include<nfc/nfc.h>
#include<nfc/nfc-types.h>

// libfreefare includes
#include<freefare.h>

#define err_chk(cond) if(cond) { goto err; }
#define BUF_LEN 512

#define WATCHDOG_GUARD setitimer(ITIMER_REAL, &trigger, NULL);
#define WATCHDOG_REST setitimer(ITIMER_REAL, &disable, NULL);

void freak_out(int i);
jmp_buf fuck_this_we_are_out;

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
    struct itimerval trigger, disable;
    trigger.it_value.tv_usec = 100000;
    trigger.it_value.tv_sec = trigger.it_interval.tv_sec = trigger.it_interval.tv_usec = 0;
    disable.it_value.tv_usec = disable.it_value.tv_sec = disable.it_interval.tv_sec = disable.it_interval.tv_usec = 0;
    int logjmp = 0;
    struct sigaction action;
    action.sa_handler = &freak_out;

    /* Do some init */
    nfc_init(&context);
    dev = nfc_open(context, NULL);
    nfc_initiator_init(dev);
    success = 0;
    piece = calloc(BUF_LEN,1); // Should be big enough >_<
    if(!piece) { syslog(LOG_ERR, "Cannot allocate memory"); exit(1); }
    buffer = calloc(BUF_LEN,1); // Should be big enough >_<
    if(!buffer) { syslog(LOG_ERR, "Cannot allocate memory"); exit(1); }

    /* Set up signal handling before setjmp so the signal mask is right */
    sigaction(SIGALRM, &action, NULL);

    /* Set up watchdog reset point */
    setjmp(fuck_this_we_are_out);
    if(logjmp)
        syslog(LOG_ERR, "WATCHDOG TRIGGERED - reset\n");
    logjmp = 1;

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
            syslog(LOG_NOTICE, "attempting to get tags");
            WATCHDOG_GUARD;
            clipper = freefare_get_tags(dev);
            WATCHDOG_REST;
            if(!clipper) { goto not_valid; }
            if(clipper[0] == NULL) { goto not_valid; }
            syslog(LOG_NOTICE, "attempting desfire_connect");
            WATCHDOG_GUARD;
            ret = mifare_desfire_connect(clipper[0]);
            WATCHDOG_REST;
            if(ret == -1) { goto not_valid; }
            syslog(LOG_NOTICE, "attempting to get application IDs");
            WATCHDOG_GUARD;
            ret = mifare_desfire_get_application_ids(clipper[0], &aids, &j);
            WATCHDOG_REST;
            if(ret == -1) { goto not_valid; }
            syslog(LOG_NOTICE, "attempting to select application");
            WATCHDOG_GUARD;
            ret = mifare_desfire_select_application(clipper[0], aids[0]);
            WATCHDOG_REST;
            if(ret == -1) { goto not_valid; }
            syslog(LOG_NOTICE, "attempting to read clipper data");
            WATCHDOG_GUARD;
            ret = mifare_desfire_read_data(clipper[0], 8, 1, 4, &clipper_id);
            WATCHDOG_REST;
            if(ret != 4) { goto not_valid; }
            syslog(LOG_NOTICE, "clipper data returned");
            clipper_id = ntohl(clipper_id);
            if(clipper_id == 0) { goto not_valid; }
            snprintf(buffer, BUF_LEN, "%d", clipper_id);
            printf("t:c%s\n", buffer);
            fflush(stdout);
            syslog(LOG_NOTICE, "clipper card successfully read (c%s)\n", buffer);
            success = 1;
not_valid:
            if(!success) // new more aggressive failure handling
            {
                syslog(LOG_NOTICE, "mifare read failed\n");
            }
            if(aids) { mifare_desfire_free_application_ids(aids); }
            WATCHDOG_GUARD;
            if(clipper && clipper != (void *) -1) { freefare_free_tags(clipper); }
            WATCHDOG_REST;
            if(!success)
            {
                syslog(LOG_NOTICE, "resetting...\n");
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

void freak_out(int i)
{
    longjmp(fuck_this_we_are_out, 1);
}
