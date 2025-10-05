/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#ifndef __ISA_RISCV32_H__
#define __ISA_RISCV32_H__

#include <common.h>

#define MEPC_ADDR 0x341
#define MSTATUS_ADDR 0x300
#define MCAUSE_ADDR 0x342
#define MTVEC_ADDR 0x305
#define MVENDORID_ADDR 0xf11
#define MARCHID_ADDR 0xf12

enum {
  EVENT_NULL = 0,
  EVENT_YIELD = 0xb, EVENT_SYSCALL = 0x9, EVENT_PAGEFAULT = 0xc, EVENT_ERROR = 0xffffffff,
  EVENT_IRQ_TIMER = 0x80000007, EVENT_IRQ_IODEV = 0x8000000b,
};

enum {
  mepc = 0x0,
  mstatus,
  mcause,
  mtvec,
  mvendorid,
  marchid
};

typedef struct {
#ifdef CONFIG_E_EXTENSION
  word_t gpr[16];
#else
  word_t gpr[32];
#endif
  vaddr_t pc;
  word_t csrs[6];   // 0: mepc, 0x341;   1: mstatus, 0x300;   2: mcause, 0x342;  3: mtvec, 0x305; 4: mvendorid, 0xf11;  5: marchid, 0xf12
} riscv32_CPU_state;

// decode
typedef struct {
  union {
    uint32_t val;
  } inst;
} riscv32_ISADecodeInfo;

#define isa_mmu_check(vaddr, len, type) (MMU_DIRECT)

#endif
