#include "memory/memory.h"
#include "define.h"
#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>


uint8_t *memory = NULL;
extern char *img_file;
extern npc_state u_npc_state;


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
  long size = ftell(fp);

  assert(size <= MSIZE); 
  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);

  memory = (uint8_t *)calloc(1, MSIZE);
  printf("memory addr is %p\n", memory);
  int ret = fread(memory, size, 1, fp);
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

uint8_t* guest_to_host(paddr_t paddr) { return memory + paddr - MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - memory + MBASE; }

int read_memory(int addr, int len) {
  return host_read(guest_to_host(addr), len);
}

void write_memory(int addr, int len, int data) {
  host_write(guest_to_host(addr), len, data);
}


