#include "memory/memory.h"
#include "define.h"
#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "debug.h"
#include "memory/paddr.h"
#include "utils.h"


uint8_t *memory = NULL;
extern char *img_file;
extern long img_size;
extern npc_state u_npc_state;

extern uint32_t g_get_pc();

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
      addr, PMEM_LEFT, PMEM_RIGHT, g_get_pc());
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
  printf("memory addr is %p\n", memory);
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

uint8_t* guest_to_host(paddr_t paddr) { return memory + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - memory + CONFIG_MBASE; }

int read_memory(int addr, int len) {
  if(addr == 0xa0000048) { return get_time(); }
  else if(addr == 0xa0000048 + 0x4) { return get_time() >> 32;}

  if(!in_pmem(addr)) {
    out_of_bound(addr);
    u_npc_state.state = NPC_ABORT;
    u_npc_state.ret = true;
    return 0;
  }
  IFDEF(CONFIG_MTRACE, MtraceBuf_write(addr, len, 0));
  return host_read(guest_to_host(addr), len);
}

void write_memory(int addr, int len, int data) {
  if(addr == 0xa00003f8) {printf("%c\n",data);} return;

  if(!in_pmem(addr)) {
    out_of_bound(addr);
    u_npc_state.state = NPC_ABORT;
    u_npc_state.ret = true;
    return;
  }
  IFDEF(CONFIG_MTRACE, MtraceBuf_write(addr, len, data));
  host_write(guest_to_host(addr), len, data);
}
