#include <am.h>
#include <klib-macros.h>
#include <npc.h>
#include <stdint.h>
#include <klib.h>
#include ISA_H

#define SERIAL_ADDR 0xa00003f8

extern char _heap_start;
extern char _bss_start, _bss_end;
int main(const char *args);

// extern char _pmem_start;
// #define PMEM_SIZE (128 * 1024 * 1024)
// #define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  outb(SERIAL_ADDR, ch);
}

void halt(int code) {
  nemu_trap(code);
  while (1);
}

void fsbl() {
  memset((void *)(uintptr_t)&_bss_start, 0, (uintptr_t)&_bss_end - (uintptr_t)&_bss_start);
}

void _trm_init() {
  fsbl();
  int ret = main(mainargs);
  halt(ret);
}
