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

#include <isa.h>
#include "local-include/reg.h"
#include <memory/paddr.h>

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
    printf("reg name\treg addr\t\treg val\n");
    for(int i=0; i<sizeof(regs)/sizeof(regs[0]); i++) {
        uint32_t *addr_32 = &gpr(i);
        uint8_t *addr_8 = (uint8_t *)addr_32;
        printf("%s:\t\t%0x%0x%0x%0x\t\t%08x\n", regs[i], host_to_guest(addr_8),host_to_guest(addr_8+1),host_to_guest(addr_8+2),host_to_guest(addr_8+3), gpr(i) );
    }
}

word_t isa_reg_str2val(const char *s, bool *success) {
  return 0;
}
