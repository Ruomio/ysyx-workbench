#include "memory/memory.h"
#include "define.h"
#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "debug.h"
#include "memory/paddr.h"


uint8_t *memory = NULL;
extern char *img_file;
extern long img_size;
extern npc_state u_npc_state;

extern uint32_t g_pc;

#ifdef CONFIG_PSRAM
uint8_t psram[CONFIG_PSRAM_SIZE] = {};
#endif
#ifdef CONFIG_SDRAM
uint8_t sdram[CONFIG_SDRAM_SIZE] = {};
#endif

#ifdef CONFIG_MTRACE
  struct MtraceBuf {
    uint8_t m_buffer[64][64];
    int idx;
  }MtraceBuf = {.m_buffer={}, .idx = 0};

  void MtraceBuf_write(paddr_t addr, int len, word_t data) {
    int idx = MtraceBuf.idx;
    memset(MtraceBuf.m_buffer[idx], 0, 64);
    memset(MtraceBuf.m_buffer[idx], ' ', 3);
    sprintf((char *)MtraceBuf.m_buffer[idx]+3, "0x%08x    %d    0x%08x", addr, len, data);
    MtraceBuf.idx = (idx+1)%64;
  }

  void MtraceBuf_add_arrow() {
    int idx = (MtraceBuf.idx + 63) % 64;
    memcpy(MtraceBuf.m_buffer[idx], "-> ", 3);
  }

  void MtraceBuf_save() {
    FILE *fp = fopen("/home/papillon/Documents/All_codes/ysyx-workbench/npc/build/mtrace-log.txt", "w");
    for(int i=0; i<MtraceBuf.idx; i++) {
      if(strlen((char *)MtraceBuf.m_buffer[i]) != 0) {
        fprintf(fp, "%s\n", MtraceBuf.m_buffer[i]);
      }
    }
    fclose(fp);
  }

#endif

static void out_of_bound(paddr_t addr) {
  IFDEF(CONFIG_MTRACE, MtraceBuf_add_arrow(); MtraceBuf_save());
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, g_pc);
}


void init_memory() {
  if (img_file == NULL) {
    printf("No image is given. \n");
    u_npc_state.state = NPC_STOP;
    u_npc_state.ret = true;
    return; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  assert(fp);

  fseek(fp, 0, SEEK_END);
  img_size = ftell(fp);

  assert(img_size <= CONFIG_MSIZE);
  printf("The image is %s, size = %ld\n", img_file, img_size);

  fseek(fp, 0, SEEK_SET);

  memory = (uint8_t *)calloc(1, CONFIG_MSIZE);
  // printf("memory addr is %p\n", memory);
  int ret = fread(memory, img_size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return;
}

void free_memory() {
  if(memory) {
    free(memory);
    memory = NULL;
  }
}

uint8_t* guest_to_host(paddr_t paddr) {
#if defined(CONFIG_PSRAM) || defined(CONFIG_SDRAM)
  if(paddr >= CONFIG_PSRAM_BASE && paddr < CONFIG_PSRAM_BASE + CONFIG_PSRAM_SIZE) {
    return psram + paddr - CONFIG_PSRAM_BASE;
  }
  else if(paddr >= CONFIG_SDRAM_BASE && paddr < CONFIG_SDRAM_BASE + CONFIG_SDRAM_SIZE) {
    return sdram + paddr - CONFIG_SDRAM_BASE;
  }
  else if(paddr >= CONFIG_MBASE && paddr < CONFIG_MBASE + CONFIG_MSIZE) {
    return memory + paddr - CONFIG_MBASE;
  }
  Assert(0,"paddr invalid!");
#endif
  return memory + paddr - CONFIG_MBASE;
}
paddr_t host_to_guest(uint8_t *haddr) { return haddr - memory + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static uint64_t u_time;
word_t paddr_read(paddr_t addr, int len) {
  IFDEF(CONFIG_MTRACE, MtraceBuf_write(addr, len, 0));
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  IFDEF(CONFIG_DEVICE,
    if(addr == 0xa0000048 + 4) { u_time = get_time(); return u_time >> 32;}
    else if(addr == 0xa0000048) { return (uint32_t)u_time;}
    // return mmio_read(addr, len)
    return 0;
  );
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  IFDEF(CONFIG_MTRACE, MtraceBuf_write(addr, len, data));
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  IFDEF(CONFIG_DEVICE,
    // mmio_write(addr, len, data);
    if(addr == 0xa00003f8) {putchar(data); fflush(stdout); } return;
  );
  out_of_bound(addr);
}

extern "C" int read_memory(int addr, int len) {
  // printf("read_mem: addr: 0x%x, len: %d, data: 0x%x\n", addr, len, paddr_read(addr,len));
  return paddr_read(addr, len);
}

 extern "C" void write_memory(int addr, int len, int data) {
  paddr_write(addr, len, data);
}

extern "C" void flash_read(int32_t addr, int32_t *data) {
  // read inst
  *data = paddr_read(addr | 0x30000000, 4);
}
extern "C" void flash_write(int32_t addr, int32_t strb, int32_t data) {
  int len = 0;
  if((strb & 0b1111) == 0b1111) {
    len = 4;
  }
  else if((strb & 0b11) == 0b11) {
    len = 2;
  }
  else if((strb & 0b1) == 0b1) {
    len = 1;
  }
  paddr_write(addr | 0x30000000, len, data);
  // printf("flash_write addr: 0x%x, len: %d, data: 0x%x\n", addr | 0x30000000, len, data);
}

extern "C" void mrom_read(int32_t addr, int32_t *data) {
  assert(addr != 0);
  *data = paddr_read(addr, 4);
}

extern "C" int psram_read(int raddr) {
  return paddr_read(raddr|0x80000000, 4);
}
extern "C" void psram_write(int waddr, int wdata, int wstrb) {
  // printf("psram_write addr:0x%x, data: 0x%x\n", waddr|0x80000000, wdata);
  switch(wstrb) {
    case 0xf: paddr_write(waddr|0x80000000, 4, wdata); break;
    case 0x3: paddr_write(waddr|0x80000000, 2, wdata); break;
    case 0x1: paddr_write(waddr|0x80000000, 1, wdata); break;
    default: break;
  }
}

extern "C" void sdram_read(char id, char ba, int row_addr, int col_addr, int wstrb, int *rdata) {
  uint32_t addr = (ba << 10) | (row_addr << 12) | (col_addr << 1);
  addr |= 0xa0000000;

  if(id == 0 || id == 2 && wstrb == 0xffffffff) {
    addr += 2;
  }
  *rdata = (uint16_t)paddr_read(addr, 2) & wstrb;
  // printf("sdram read, id:%d, addr: 0x%x,  rdata: 0x%x, wstrb:0x%x\n", id, addr, *rdata & wstrb, wstrb);
}

extern "C" void sdram_write(char id, char ba, int row_addr, int col_addr, int wstrb, int wdata) {
  char len = 0;
  uint32_t addr = (ba << 10) | (row_addr << 12) | (col_addr << 1);
  addr |= 0xa0000000;

  if(id == 0 && (wstrb == 0x0000ffff || wstrb == 0xff || wstrb == 0xff00)) {
    return;
  }
  if((id == 0 || id == 2) && ((wstrb) == 0xffffffff ) ) {
    addr += 2;
  }
  if((wstrb & 0xffff) == 0xffff) {
    len = 2;
  }
  else if((wstrb & 0xff) == 0xff) {
    len = 1;
  }
  else if((wstrb & 0xff00) == 0xff00) {
    len = 1;
    wdata >>= 8;
    addr += 1;
  }
  if(len) {
    paddr_write(addr, len, wdata);
    // printf("sdram write, id:%d, addr: 0x%x,  data: 0x%x,  wstrb:0x%x,  len:%d\n", id, addr, wdata, wstrb, len);
  }

  assert(col_addr < 512);
#if defined(CONFIG_SDRAM)
  Assert((addr >= CONFIG_SDRAM_BASE && addr < CONFIG_SDRAM_BASE + CONFIG_SDRAM_SIZE), "OUT OF SDARM ADDR");
#endif
}
