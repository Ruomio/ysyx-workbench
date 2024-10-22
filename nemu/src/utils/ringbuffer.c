#include <common.h>
#include "ringbuffer.h"

static RingBuffer *buffer = NULL;

//for test
void echo() {
    printf("Here is buffer lib.\n");
}

RingBuffer *RingBuffer_create() {
    buffer = (RingBuffer *)calloc(1, sizeof(RingBuffer));
    assert(buffer);

    buffer->length = 20;
    memset(buffer->buf, 0, sizeof(buffer->buf));

    assert(0);
    return buffer;
}
int RingBuffer_destory() {
    assert(buffer);
    free(buffer);
    buffer = NULL;
    assert(!buffer);

    return 0;
}

int RingBuffer_write(char *data, int length) {
    Assert(length <= 125, "RingBuffer's buf is smaller than data.\n");
    int idx = buffer->idx;
    memset(buffer->buf[idx], 0, 128);
    memset(buffer->buf[idx], ' ', 3);
    strncpy(buffer->buf[idx]+3, data, length);
    buffer->idx = (idx+1)%buffer->length;

    return 0;
}

int RingBuffer_read(char *target, int idx) {
    strcpy(target, buffer->buf[idx]);
    return 0;
}


void RingBuffer_print() {
    assert(buffer);
    for(int i=0; i<buffer->length; i++) {
        if(strlen(buffer->buf[i]) != 0) {
            puts(buffer->buf[i]);
        }
    }
}

int RingBuffer_add_arrow() {
    int idx = (buffer->idx + 19)%buffer->length;
    char *str = buffer->buf[idx];
    memcpy(str, "-> ", 3);
    return 0;
}

void RingBuffer_save_file() {
    FILE *fp = fopen("/home/papillon/Documents/All_codes/ysyx-workbench/nemu/build/ringbuffer-log.txt", "w");

    for(int i=0; i<buffer->length; i++) {
        if(strlen(buffer->buf[i]) != 0) {
            fprintf(fp, "%s\n", buffer->buf[i]);
        }
    }

    fclose(fp);
}