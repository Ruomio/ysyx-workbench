
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

#include <common.h>
#include <elf.h>

void init_ftrace(const char *img_file, const char *ftrace_file) {
  Log("entry init_ftrace");
  if(!img_file) return;
  if(!ftrace_file) {
    ftrace_file = "/home/papillon/Documents/All_codes/ysyx-workbench/nemu/build/ftrace-log.txt";
  }
  FILE *file = fopen(img_file, "rb");
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
        } else if (shdrs[i].sh_type == 3) { // SHT_STRTAB
            strtab_index = i;
        }
    }

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
            printf("Function: %s, Address: 0x%x\n", strtab + symbols[i].st_name, symbols[i].st_value);
        }
    }

    free(shdrs);
    free(symbols);
    free(strtab);
    fclose(file);

  Log("leave init_ftrace");
}