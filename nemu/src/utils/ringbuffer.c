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
    memset(buffer->buf[buffer->idx], 0, 128);
    strcpy(buffer->buf[(buffer->idx++)%buffer->length]+3, data);
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
            printf("%s\n", buffer->buf[i]);
        }
    }
}

int RingBuffer_add_arrow(int idx) {
    char *str = buffer->buf[idx];
    memcpy(str, "-->", 3);
    return 0;
}
