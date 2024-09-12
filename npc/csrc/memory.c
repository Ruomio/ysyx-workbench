#include "include/memory.h"
#include "include/define.h"
#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

extern bool run_flag;
extern char *img_file;

uint8_t* guest_to_host(paddr_t paddr) { return memory + paddr - MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - memory + MBASE; }

int read_memory(int addr, int len) {
  printf("addr = 0x%x, len = %d.\n", addr, len);
  return host_read(guest_to_host(addr), len);
}

void write_memory(int addr, int len, int data) {
  // host_write(guest_to_host(addr), len, data);
}




void init_memory() {
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.");
    run_flag = true;
    return; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  assert(fp);
  // printf("Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  assert(size <= MSIZE); 
  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);

  printf("memory addr is %p\n", memory);
  int ret = fread(memory, size, 1, fp);
  assert(ret == 1);

  for(int i =0; i < size; i++) {
    printf("memory [%d] = 0x%x\n", i, memory[i]);
  }

  fclose(fp);
  return;
}

