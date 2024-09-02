#ifndef __RANG_BUFFER__H
#define __RANG_BUFFER__H

#include <string.h>

typedef struct RingBuffer {
    char buf[20][128];
    int length;
    int idx;
}RingBuffer;


RingBuffer *RingBuffer_create();
int RingBuffer_destory();

/**
 * return: 0 or -1
 */
int RingBuffer_read(char *target, int idx);

/**
 * return: >0 : write length; < 0 : fail
 *
 */
int RingBuffer_write(char *data, int length);

void RingBuffer_print();

int RingBuffer_add_arrow();

void RingBuffer_save_file();
// for test
void echo();

// macro
#define RingBuffer_puts(B, D) (RingBuffer_write((B), (D), strlen(D))


#endif
