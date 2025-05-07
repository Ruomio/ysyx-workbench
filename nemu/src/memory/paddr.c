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

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif
#ifdef CONFIG_IS_SRAM
static uint8_t sram[CONFIG_SRAM_SIZE] = {};
#endif
#ifdef CONFIG_IS_PSRAM
static uint8_t psram[CONFIG_PSRAM_SIZE] = {};
#endif
#ifdef CONFIG_IS_SDRAM
static uint8_t sdram[CONFIG_SDRAM_SIZE] = {};
#endif

#ifdef CONFIG_MTRACE_COND
  struct MtraceBuf {
    uint8_t m_buffer[64][64];
    int idx;
  }MtraceBuf = {.m_buffer={}, .idx = 0};

  void MtraceBuf_write(paddr_t addr, int len, word_t data, bool flag) {
    // do not record insts.
  #if defined(CONFIG_IS_SRAM) || defined(CONFIG_IS_PSRAM) || defined(CONFIG_IS_SDRAM)
    if(addr >= CONFIG_MBASE && addr <= CONFIG_MBASE + CONFIG_MSIZE) return;
  #endif

    int idx = MtraceBuf.idx;
    memset(MtraceBuf.m_buffer[idx], 0, 64);
    memset(MtraceBuf.m_buffer[idx], ' ', 3);
    if(flag) {
      sprintf((char *)MtraceBuf.m_buffer[idx]+3, "0x%08x  w:%d    0x%08x", addr, len, data);
    }
    else {
      sprintf((char *)MtraceBuf.m_buffer[idx]+3, "0x%08x  r:%d", addr, len);
    }

    MtraceBuf.idx = (idx+1)%64;

    FILE *fp = fopen("/home/papillon/Documents/All_codes/ysyx-workbench/nemu/build/mtrace-full-log.txt", "a");
    fseek(fp, 0, SEEK_END);
    fprintf(fp, "%s\n", MtraceBuf.m_buffer[idx]);
    fclose(fp);
  }

  void MtraceBuf_add_arrow() {
    int idx = (MtraceBuf.idx + 63) % 64;
    memcpy(MtraceBuf.m_buffer[idx], "-> ", 3);
  }

  void MtraceBuf_save() {
    FILE *fp = fopen("/home/papillon/Documents/All_codes/ysyx-workbench/nemu/build/mtrace-log.txt", "w+");
    for(int i=0; i<MtraceBuf.idx; i++) {
      if(strlen((char *)MtraceBuf.m_buffer[i]) != 0) {
        fprintf(fp, "%s\n", MtraceBuf.m_buffer[i]);
      }
    }
    fclose(fp);
  }

#endif

uint8_t* guest_to_host(paddr_t paddr) {
#if defined(CONFIG_IS_SRAM) || defined(CONFIG_IS_PSRAM) || defined(CONFIG_IS_SDRAM)
  if(paddr >= CONFIG_SRAM_BASE && paddr <= CONFIG_SRAM_BASE + CONFIG_SRAM_SIZE) return sram + paddr - CONFIG_SRAM_BASE;
  if(paddr >= CONFIG_PSRAM_BASE && paddr <= CONFIG_PSRAM_BASE + CONFIG_PSRAM_SIZE) return psram + paddr - CONFIG_PSRAM_BASE;
  if(paddr >= CONFIG_SDRAM_BASE && paddr <= CONFIG_SDRAM_BASE + CONFIG_SDRAM_SIZE) return sdram + paddr - CONFIG_SDRAM_BASE;
  if(paddr >= CONFIG_MBASE && paddr <= CONFIG_MBASE + CONFIG_MSIZE) return pmem + paddr - CONFIG_MBASE;
  Assert(0, "paddr are not in mrom, sram or psram: 0x%x", paddr);
#else
  return pmem + paddr - CONFIG_MBASE;
#endif
}
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

#ifdef CONFIG_ADAPT_SOC
static uint64_t u_time = 0;

static word_t soc_ioe_read(paddr_t addr, int len) {
  if(addr >= 0x02000000 && addr <= 0x0200ffff) {
    // clint
    if(addr == 0x02000000) {
      return u_time;
    }
    else if(addr == 0x02000004) {
      u_time = get_time();
      return u_time >> 32;
    }
  }
  else if(addr >= 0x10000000 && addr <= 0x10000fff) {
    // uart
    // lsr,
    if(addr == 0x10000005) {
      return 0x21;
    }
  }
  else printf("can not read from soc device, addr: 0x%x\n", addr);

  return 0;
}

static void soc_ioe_write(paddr_t addr, int len, word_t data) {
  if(addr >= 0x02000000 && addr <= 0x0200ffff) {
    // clint
    printf("clint can not write!\n");
  }
  else if(addr >= 0x10000000 && addr <= 0x10000fff) {
    // uart
    if(addr == 0x10000000) {
      putchar(data);
      fflush(stdout);
    }
  }
  else printf("can not write from soc device, addr: 0x%x\n", addr);
}
#endif

static void out_of_bound(paddr_t addr) {
  IFDEF(CONFIG_MTRACE_COND, MtraceBuf_add_arrow(); MtraceBuf_save());
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
#ifdef CONFIG_MEM_RANDOM
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
#endif
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);


#ifdef CONFIG_MTRACE_COND
  // clear file
  FILE *fp = fopen("/home/papillon/Documents/All_codes/ysyx-workbench/nemu/build/mtrace-full-log.txt", "w");
  fclose(fp);
#endif
}

word_t paddr_read(paddr_t addr, int len) {
  IFDEF(CONFIG_MTRACE_COND, MtraceBuf_write(addr, len, 0, 0));
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  IFDEF(CONFIG_ADAPT_SOC, return soc_ioe_read(addr, len));
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  IFDEF(CONFIG_MTRACE_COND, MtraceBuf_write(addr, len, data, 1));
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  IFDEF(CONFIG_ADAPT_SOC, soc_ioe_write(addr, len, data); return);
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
