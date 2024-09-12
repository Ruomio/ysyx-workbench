#include "memory/memory.h"
#include "define.h"
#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>


uint8_t* guest_to_host(paddr_t paddr) { return memory + paddr - MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - memory + MBASE; }

int read_memory(int addr, int len) {
  return host_read(guest_to_host(addr), len);
}

void write_memory(int addr, int len, int data) {
  host_write(guest_to_host(addr), len, data);
}


