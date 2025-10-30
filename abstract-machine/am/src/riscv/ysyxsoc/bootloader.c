#include <am.h>
#include <klib.h>

extern char _data_start, _data_end, _data_load;

extern char _text_start, _text_end, _text_load;

extern char _bss_start;
extern char _bss_end;

extern char _ssbl_start, _ssbl_end, _ssbl_load;

extern char _sram_base, _psram_base, _flash_base, _sdram_base;

extern void _start();

__attribute__((noinline, unused, section(".ssbl"))) void ssbl() {
  // copy .text  from flash to sdram
  memcpy((void *)(uintptr_t)&_text_start, (void *)(uintptr_t)&_text_load, ((volatile uintptr_t)&_text_end - (volatile uintptr_t)&_text_start));

  // copy .data  from flash to sdram
  memcpy((void *)(uintptr_t)&_data_start, (void *)(uintptr_t)&_data_load, ((volatile uintptr_t)&_data_end - (volatile uintptr_t)&_data_start));


  // init .bss
  uint32_t *start = (uint32_t *)(uintptr_t)&_bss_start;
  memset(start, 0, (uintptr_t)&_bss_end - (uintptr_t)&_bss_start);

  // call _start
  _start();
}

__attribute__((noinline, section(".fsbl"))) void fsbl() {
// void fsbl() {
  // copy ssbl from flash to sram
  memcpy((void *)(uintptr_t)&_ssbl_start, (void *)(uintptr_t)&_ssbl_load, (uintptr_t)&_ssbl_end - (uintptr_t)&_ssbl_start);

  ssbl();

}
