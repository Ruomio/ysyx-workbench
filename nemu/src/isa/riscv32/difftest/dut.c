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
#include <cpu/difftest.h>
#include "../local-include/reg.h"

#define CHECKCSRS(csr) do {\
                            if(ref_r->csrs[csr] != cpu.csrs[csr]) { \
                              printf("csrs diff at %dth, ref = 0x%x, dut = 0x%x\n", csr, ref_r->csrs[csr], cpu.csrs[csr]);   \
                              return false; \
                            }\
                        } while(0)

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for(int i = 0; i < sizeof(cpu.gpr)/sizeof(cpu.gpr[0]); i++) {
    if(ref_r->gpr[i] != cpu.gpr[i]) { 
      printf("reg diff at %d, ref_val = 0x%x, dut_val = 0x%x\n",i, ref_r->gpr[i] ,cpu.gpr[i] );
      return false;
    };
  }
  CHECKCSRS(mepc);
  CHECKCSRS(mstatus);
  CHECKCSRS(mcause);
  CHECKCSRS(mtvec);
  return true;
}

void isa_difftest_attach() {
}
