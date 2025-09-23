#include <am.h>
#include <nemu.h>

extern char _heap_start;
int main(const char *args);

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  outb(SERIAL_PORT, ch);
}

void __am_uart_rx(AM_UART_RX_T *rx) {
  char ch = inb(SERIAL_PORT);
  if(ch < (char)128 && ch != 0) {
    rx->data = ch;
  } else { rx->data = 0xff; }
}

void halt(int code) {
  nemu_trap(code);

  // should not reach here
  while (1);
}

void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}
