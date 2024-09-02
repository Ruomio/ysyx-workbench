#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "ringbuffer.h"
#include "debug.h"

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
        if(strlen(buffer->buf[i]+3) != 0) {
            puts(buffer->buf[i]);
        }
    }
}

int RingBuffer_add_arrow() {
    char *str = buffer->buf[buffer->idx-1];
    memcpy(str, "-> ", 3);
    return 0;
}
