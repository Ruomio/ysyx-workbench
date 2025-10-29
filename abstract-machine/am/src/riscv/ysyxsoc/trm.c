#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>
#include <klib.h>
#include ISA_H


extern char _heap_start;
int main(const char *args);

extern char _data_start, _data_end, _data_load;

extern char _text_start, _text_end, _text_load;

extern char _bss_start;
extern char _bss_end;

extern char _ssbl_start, _ssbl_end, _ssbl_load;

extern char _sram_base, _psram_base, _flash_base, _sdram_base;

// extern char _pmem_start;
// #define PMEM_SIZE (16 * 1024 * 1024)
// #define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

// Area heap = RANGE(&_heap_start, PMEM_END);
#define HEAP_SIZE (16 * 1024 * 1024)
#define HEAP_END ((uintptr_t)&_heap_start + HEAP_SIZE)
Area heap = RANGE(&_heap_start, HEAP_END);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  // lsr, offset = 0x5
  while(!(inb(SERIAL_ADDR + 0x5) & 0x20));
  outb(SERIAL_ADDR, ch);
}

void __am_uart_rx(AM_UART_RX_T *rx) {
  while(!(inb(SERIAL_ADDR+0x5) & 0x01));
  char ch = inb(SERIAL_ADDR);
  if(ch < (char)128 && ch != 0) {
    rx->data = ch;
  } else { rx->data = 0xff; }
}

void halt(int code) {
  // ebreak inst;
  asm volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}

__attribute__((unused, section(".ssbl"))) void ssbl() {
  // copy .text  from flash to sdram
  memcpy((void *)(uintptr_t)&_text_start, (void *)(uintptr_t)&_text_load, ((volatile uintptr_t)&_text_end - (volatile uintptr_t)&_text_start));

  // copy .data  from flash to sdram
  memcpy((void *)(uintptr_t)&_data_start, (void *)(uintptr_t)&_data_load, ((volatile uintptr_t)&_data_end - (volatile uintptr_t)&_data_start));


  // init .bss
  uint32_t *start = (uint32_t *)(uintptr_t)&_bss_start;
  memset(start, 0, (uintptr_t)&_bss_end - (uintptr_t)&_bss_start);

}

// __attribute__((section(".fsbl"))) void fsbl() {
void fsbl() {
  // copy ssbl from flash to sram
  memcpy((void *)(uintptr_t)&_ssbl_start, (void *)(uintptr_t)&_ssbl_load, (uintptr_t)&_ssbl_end - (uintptr_t)&_ssbl_start);

  ssbl();
}

void init_uart(int baud_rate) {
  // set Line Control, offset = 0x3
  uint8_t lc = 0;
  lc = lc | 0x03; // 8bit
  lc = lc & ~0x04; // 1 stop
  lc = lc & ~0x08; // parity disable
  lc = lc & ~0x10; // parity type: odd or even
  lc = lc & ~0x20; // stick parity bit
  lc = lc & ~0x40; // break control bit
  lc = lc | 0x80; // divisor latch access bit, enable access: 1;   disable access: 0;
  outb(SERIAL_ADDR+0x3, lc);

  // set baud rate, offset = 0x1 and 0x2
  // div = freq / (16 * baud rate)
  uint16_t baud_div = 3686400 / (32 * baud_rate);
  outb(SERIAL_ADDR, (uint8_t)baud_div);
  outb(SERIAL_ADDR+0x1, (uint8_t)(baud_div >> 8));

  // set divisor latch no access
  lc = lc & ~0x80;
  outb(SERIAL_ADDR+0x3, lc);
}

void show_stu_no() {
  uint32_t mvendorid;
  uint32_t marchid;
  __asm__ volatile ("csrr %0, %1" : "=r" (mvendorid) : "i" (0xf11));
  __asm__ volatile ("csrr %0, %1" : "=r" (marchid) : "i" (0xf12));
  printf("%c%c%c%c_%d\n", mvendorid>>24, mvendorid>>16, mvendorid>>8, mvendorid, marchid);
}

void _trm_init() {
  fsbl();
  init_uart(115200);
  show_stu_no();
  int ret = main(mainargs);
  halt(ret);
}
