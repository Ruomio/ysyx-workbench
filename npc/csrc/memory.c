#include "include/memory.h"
#include <stdint.h>
#include <stdio.h>
#include <assert.h>

extern bool run_flag;
extern char *img_file;

void init_memory(const svOpenArrayHandle memory) {
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

  assert(size <= 4*8*1024); // 4kB
  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);

  // 获取数组的指针
  svBitVecVal* mem_ptr = (svBitVecVal*)svGetArrayPtr(memory);
  if(mem_ptr == NULL) {
    printf("memory addr is %p\n", memory);
    printf("mem_ptr is NULL\n");
    assert(0);
  }
  int ret = fread((uint8_t *)mem_ptr, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return;
}