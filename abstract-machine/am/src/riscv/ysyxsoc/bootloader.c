#include <am.h>
#include <klib.h>

extern char _data_start, _data_end, _data_load;
extern char _rodata_start, _rodata_end, _rodata_load;

extern char _text_start, _text_end, _text_load;

extern char _bss_start;
extern char _bss_end;

extern char _ssbl_start, _ssbl_end, _ssbl_load;

extern char _sram_base, _psram_base, _flash_base, _sdram_base;

extern char _stack_pointer;

extern void _start();

__attribute__((noinline, unused, section(".ssbl"))) void ssbl() {
  // copy .text  from flash to sdram
  // memcpy((void *)(uintptr_t)&_text_start, (void *)(uintptr_t)&_text_load, ((volatile uintptr_t)&_text_end - (volatile uintptr_t)&_text_start));
  char *text_start = &_text_start;
  char *text_end = &_text_end;
  char *text_load = &_text_load;
  int text_size = text_end - text_start;
  for(int i = 0; i < text_size; i++) {
    text_start[i] = text_load[i];
  }

  // copy .rodata  from flash to sdram
  char *rodata_start = &_rodata_start;
  char *rodata_end = &_rodata_end;
  char *rodata_load = &_rodata_load;
  int rodata_size = rodata_end - rodata_start;
  for(int i = 0; i < rodata_size; i++) {
    rodata_start[i] = rodata_load[i];
  }

  // copy .data  from flash to sdram
  // memcpy((void *)(uintptr_t)&_data_start, (void *)(uintptr_t)&_data_load, ((volatile uintptr_t)&_data_end - (volatile uintptr_t)&_data_start));
  char *data_start = &_data_start;
  char *data_end = &_data_end;
  char *data_load = &_data_load;
  int data_size = data_end - data_start;
  for(int i = 0; i < data_size; i++) {
    data_start[i] = data_load[i];
  }

  // init .bss
  char *start = (char *)(uintptr_t)&_bss_start;
  int bss_size = (uintptr_t)&_bss_end - (uintptr_t)&_bss_start;
  // memset(start, 0, (uintptr_t)&_bss_end - (uintptr_t)&_bss_start);
  for(int i = 0; i < bss_size; i++) {
    start[i] = 0;
  }

  // call _start
  _start();
}

__attribute__((naked, noinline, section(".fsbl"))) void fsbl() {
// void fsbl() {

  // mv s0, zero - 将帧指针清零
  __asm volatile("mv s0, zero");

  // la sp, _stack_pointer - 加载栈指针
  __asm volatile("la sp, %0" : : "i"(&_stack_pointer));

  // can not use memcpy because it not in sdram now
  // memcpy((void *)(uintptr_t)&_ssbl_start, (void *)(uintptr_t)&_ssbl_load, (uintptr_t)&_ssbl_end - (uintptr_t)&_ssbl_start);

  // copy ssbl from flash to sram
  __asm volatile(
    "la a0, _ssbl_start\n"             // 目标地址 (SRAM)
    "la a1, _ssbl_load\n"              // 源地址 (Flash)
    "la a2, _ssbl_end\n"               // 结束地址
    "la a3, _ssbl_start\n"             // 开始地址
    "sub a2, a2, a3\n"                 // 计算大小

    "1:\n"                             // 循环开始
    "beqz a2, 2f\n"                    // 如果大小为0，跳转到结束
    "lb t0, 0(a1)\n"                   // 从源加载1字节
    "sb t0, 0(a0)\n"                   // 存储到目标
    "addi a0, a0, 1\n"                 // 目标地址+1
    "addi a1, a1, 1\n"                 // 源地址+1
    "addi a2, a2, -1\n"                // 计数器-1
    "j 1b\n"                           // 跳回循环开始

    "2:\n"                             // 复制完成
  );

  // call ssbl
  __asm volatile(
      "tail ssbl"
  );
}
