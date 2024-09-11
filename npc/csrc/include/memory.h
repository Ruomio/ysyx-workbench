#ifndef __MEMORY_H__
#define __MEMORY_H__

#include <cassert>
#include <stdint.h>
#include "define.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

typedef  uint32_t word_t;
typedef  uint32_t paddr_t;


static uint8_t memory[MSIZE];

uint8_t* guest_to_host(paddr_t paddr) { return memory + paddr - MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - memory + MBASE; }

static inline word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    // IFDEF(CONFIG_ISA64, case 8: return *(uint64_t *)addr);
    // default: MUXDEF(CONFIG_RT_CHECK, assert(0), return 0);
    default: assert(0); break;
  }
}

static inline void host_write(void *addr, int len, word_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 4: *(uint32_t *)addr = data; return;
    // IFDEF(CONFIG_ISA64, case 8: *(uint64_t *)addr = data; return);
    // IFDEF(CONFIG_RT_CHECK, default: assert(0));
    default: assert(0); break;
  }
}

#endif