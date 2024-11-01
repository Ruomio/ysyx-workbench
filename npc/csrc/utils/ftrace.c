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
#include "utils.h"
#include "debug.h"
#include <elf.h>

#ifdef CONFIG_FTRACE
#define NR_FT (1024)

struct Ftrace_struct{
  uint32_t addr;
  char name[64];
  size_t size;
}Ftrace_tab[NR_FT];


static FILE *out = NULL;

void init_ftrace(const char *img_file, const char *ftrace_file) {
  printf("img_file = %s,    ftrace_file = %s\n", img_file, ftrace_file);
  if(!img_file) return;
  char *elf_file = (char *)calloc(1, strlen(img_file) + 1);
  strcpy(elf_file, img_file);
  memcpy((char *)(elf_file+strlen(elf_file)-3), "elf", 3);

  Log("Get function name and address from %s", elf_file);


  if(!ftrace_file) {
    ftrace_file = "/home/papillon/Documents/All_codes/ysyx-workbench/npc/build/ftrace-log.txt";
  }
  FILE *ftrace_log = fopen(ftrace_file, "w");
  out = ftrace_log;

  FILE *file = fopen(elf_file, "rb");
  assert(file);

  Elf32_Ehdr ehdr;
  fread(&ehdr, sizeof(ehdr), 1, file);
  
  // 读取节头
  fseek(file, ehdr.e_shoff, SEEK_SET);
  Elf32_Shdr *shdrs = (Elf32_Shdr *)malloc(ehdr.e_shnum * sizeof(Elf32_Shdr));
  fread(shdrs, sizeof(Elf32_Shdr), ehdr.e_shnum, file);

  // 找到符号表和字符串表
  int symtab_index = -1;
  int strtab_index = -1;

  for (int i = 0; i < ehdr.e_shnum; i++) {
    if (shdrs[i].sh_type == 2 && symtab_index == -1) { // SHT_SYMTAB
      symtab_index = i;
    } else if (shdrs[i].sh_type == 3 && strtab_index == -1) { // SHT_STRTAB
      strtab_index = i;
    }
  }
  // printf("%d %d \n", symtab_index, strtab_index);
  // 读取符号表
  Elf32_Sym *symbols = (Elf32_Sym *)malloc(shdrs[symtab_index].sh_size);
  fseek(file, shdrs[symtab_index].sh_offset, SEEK_SET);
  fread(symbols, shdrs[symtab_index].sh_size, 1, file);

  // 读取字符串表
  char *strtab = (char *)malloc(shdrs[strtab_index].sh_size);
  fseek(file, shdrs[strtab_index].sh_offset, SEEK_SET);
  fread(strtab, shdrs[strtab_index].sh_size, 1, file);

  memset(Ftrace_tab, 0, sizeof(Ftrace_tab));
  printf("init ftrace 1\n");
  // 打印函数名和地址
  for (int i = 0; i < shdrs[symtab_index].sh_size / sizeof(Elf32_Sym); i++) {
    if (ELF32_ST_TYPE(symbols[i].st_info) == STT_FUNC) {
      // printf("Function: %10s, Address: 0x%x  Size: %d  \n",(strtab + symbols[i].st_name), symbols[i].st_value, symbols[i].st_size);
      strcpy(Ftrace_tab[i].name, strtab + symbols[i].st_name);
      Ftrace_tab[i].addr = symbols[i].st_value;
      Ftrace_tab[i].size = symbols[i].st_size; 
    }
  }
  printf("init ftrace 2\n");

  free(shdrs);
  free(symbols);
  free(strtab);
  fclose(file);
  free(elf_file);
}


int update_ftrace(uint32_t pc, uint32_t addr, uint32_t rs1, uint32_t rd) {
  static int top = 0;

  char str[512] = {};
  int idx=0;

  // printf("rs1 = %x, rd = %x\n", rs1, rd);
  for(int i=0; i<NR_FT; i++) {
    if(addr >= Ftrace_tab[i].addr && addr < Ftrace_tab[i].addr + Ftrace_tab[i].size) {
      // pc
      sprintf(str+idx, "0x%x: ", pc);
      idx += strlen(str+idx);
      

      // type: call or ret
      if(rs1 == 1 && rd == 0) {
        // space
        for(int i=0; i<2*top; i++) {
          sprintf(str+idx, " ");
          idx += strlen(str+idx);
        }
        if(top > 0) top--;
        sprintf(str+idx, "ret  ");
        idx += strlen(str+idx);
        // function name
        sprintf(str+idx, "[%s]", Ftrace_tab[i].name);
        idx += strlen(str+idx);
      }
      else {
        top ++;
        // space
        if(2*top > 450) top--;
        for(int i=0; i<2*top; i++) {
          sprintf(str+idx, " ");
          idx += strlen(str+idx);
        }
        sprintf(str+idx, "call ");
        idx += strlen(str+idx);
        // function name
        sprintf(str+idx, "[%s@0x%x]", Ftrace_tab[i].name, Ftrace_tab[i].addr);
        idx += strlen(str+idx);
      }

      break;

    }
  }
  fprintf(out, "%s\n", str);
  // printf("%s\n", str);

  return 0;
}

int close_ftrace() {
  if(out) {
    fclose(out);
  }

  return 0;
}
#endif