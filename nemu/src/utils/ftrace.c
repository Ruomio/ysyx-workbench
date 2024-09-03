
/***************************************************************************************
* Copyright (c) 2024-2024 Peizhi Peng
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

#include "memory/paddr.h"
#include <common.h>
#include <elf.h>

void init_ftrace(const char *img_file, const char *ftrace_file) {
  if(!img_file) return;
  char *elf_file = calloc(1, strlen(img_file) + 1);
  strcpy(elf_file, img_file);
  memcpy((char *)(elf_file+strlen(elf_file)-3), "elf", 3);
  Log("entry init_ftrace, %s\n", elf_file);

  if(!ftrace_file) {
    ftrace_file = "/home/papillon/Documents/All_codes/ysyx-workbench/nemu/build/ftrace-log.txt";
  }
  FILE *file = fopen(elf_file, "rb");
  assert(file);

  Elf32_Ehdr ehdr;
  fread(&ehdr, sizeof(ehdr), 1, file);
  
  // 读取节头
  fseek(file, ehdr.e_shoff, SEEK_SET);
  Elf32_Shdr *shdrs = malloc(ehdr.e_shnum * sizeof(Elf32_Shdr));
  fread(shdrs, sizeof(Elf32_Shdr), ehdr.e_shnum, file);

  // 找到符号表和字符串表
  int symtab_index = -1;
  int strtab_index = -1;

  for (int i = 0; i < ehdr.e_shnum; i++) {
    if (shdrs[i].sh_type == 2) { // SHT_SYMTAB
      symtab_index = i;
  printf("%d %d \n", symtab_index, strtab_index);
    } else if (shdrs[i].sh_type == 3) { // SHT_STRTAB
      strtab_index = i;
  printf("%d %d \n", symtab_index, strtab_index);
    }
  }
  printf("%d %d \n", symtab_index, strtab_index);
  strtab_index -= 1;
  // 读取符号表
  Elf32_Sym *symbols = malloc(shdrs[symtab_index].sh_size);
  fseek(file, shdrs[symtab_index].sh_offset, SEEK_SET);
  fread(symbols, shdrs[symtab_index].sh_size, 1, file);

  // 读取字符串表
  char *strtab = malloc(shdrs[strtab_index].sh_size);
  fseek(file, shdrs[strtab_index].sh_offset, SEEK_SET);
  fread(strtab, shdrs[strtab_index].sh_size, 1, file);

  // 打印函数名和地址
  for (int i = 0; i < shdrs[symtab_index].sh_size / sizeof(Elf32_Sym); i++) {
    if (ELF32_ST_TYPE(symbols[i].st_info) == STT_FUNC) {
      printf("Offset: %x, Index: %u ,Function: %10s, Address: 0x%x    \n",symbols[i].st_size, symbols[i].st_name, (strtab + symbols[i].st_name), symbols[i].st_value);
    }
  }

  free(shdrs);
  free(symbols);
  free(strtab);
  fclose(file);
  free(elf_file);

  Log("leave init_ftrace");
}