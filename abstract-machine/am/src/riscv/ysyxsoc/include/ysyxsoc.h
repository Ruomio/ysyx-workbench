#ifndef YSYXSOC_H__
#define YSYXSOC_H__

#include <klib-macros.h>

#include ISA_H // the macro `ISA_H` is defined in CFLAGS
               // it will be expanded as "x86/x86.h", "mips/mips32.h", ...

#if defined(__ISA_X86__)
# define nemu_trap(code) asm volatile ("int3" : :"a"(code))
#elif defined(__ISA_MIPS32__)
# define nemu_trap(code) asm volatile ("move $v0, %0; sdbbp" : :"r"(code))
#elif defined(__riscv)
# define nemu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))
#elif defined(__ISA_LOONGARCH32R__)
# define nemu_trap(code) asm volatile("move $a0, %0; break 0" : :"r"(code))
#else
# error unsupported ISA __ISA__
#endif

#if defined(__ARCH_X86_NEMU)
# define DEVICE_BASE 0x0
#else
# define DEVICE_BASE 0xa0000000
#endif

#define MMIO_BASE 0xa0000000

#define CLINT_ADDR            (0x02000000)
#define SERIAL_ADDR           (0x10000000)
#define KBD_ADDR              (0x10011000)
#define VGACTL_ADDR           (0x21000000)
#define AUDIO_ADDR            (0x00002000)
#define DISK_ADDR             (0x00003000)
#define SPI_ADDR              (0x10001000)
#define GPIO_ADDR             (0x10002000)
#define SRAM_ADDR             (0x0f000000)
#define MROM_ADDR             (0x20000000)
#define FLASH_ADDR            (0x30000000)
#define CHIPLINK_MMIO_ADDR    (0x40000000)
#define CHIPLINK_MEM_ADDR     (0xc0000000)
#define PSRAM_ADDR            (0x80000000)
#define SDRAM_ADDR            (0xa0000000)
// #define RTC_ADDR              (DEVICE_BASE + 0x0000048)
// #define FB_ADDR               (MMIO_BASE   + 0x1000000)
// #define AUDIO_SBUF_ADDR       (MMIO_BASE   + 0x1200000)

extern char _pmem_start;
#define PMEM_SIZE (32 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)
#define NEMU_PADDR_SPACE \
  RANGE(&_pmem_start, PMEM_END), \
  RANGE(FB_ADDR, FB_ADDR + 0x200000), \
  RANGE(MMIO_BASE, MMIO_BASE + 0x1000) /* serial, rtc, screen, keyboard */

typedef uintptr_t PTE;

#define PGSIZE    4096

#endif
