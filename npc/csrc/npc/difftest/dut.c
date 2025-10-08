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

#include "define.h"
#include <dlfcn.h>
#include <cpu/difftest.h>
#include <difftest-def.h>
#include <isa.h>
#include <memory/paddr.h>
#include <debug.h>


typedef void (*ref_difftest_memcpy_type)(paddr_t addr, void *buf, size_t n, bool direction);
typedef void (*ref_difftest_regcpy_type)(void *dut, bool direction);
typedef void (*ref_difftest_exec_type)(uint64_t n);
typedef void (*ref_difftest_raise_intr_type)(uint64_t NO);
ref_difftest_memcpy_type ref_difftest_memcpy = NULL;
ref_difftest_regcpy_type ref_difftest_regcpy = NULL;
ref_difftest_exec_type ref_difftest_exec = NULL;
ref_difftest_raise_intr_type ref_difftest_raise_intr = NULL;
// void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
// void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
// void (*ref_difftest_exec)(uint64_t n) = NULL;
// void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

#ifdef CONFIG_DIFFTEST



static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;

extern npc_state u_npc_state;
extern CPU_state npc_cpu;
extern uint32_t last_pc, g_pc;

extern void update_npc_cpu();
extern uint32_t g_get_reg(int i);
extern uint32_t g_get_csrs(int i);

// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.
  skip_dut_nr_inst = 0;
}

// this is used to deal with instruction packing in QEMU.
// Sometimes letting QEMU step once will execute multiple instructions.
// We should skip checking until NEMU's pc catches up with QEMU's pc.
// The semantic is
//   Let REF run `nr_ref` instructions first.
//   We expect that DUT will catch up with REF within `nr_dut` instructions.
void difftest_skip_dut(int nr_ref, int nr_dut) {
  skip_dut_nr_inst += nr_dut;

  while (nr_ref -- > 0) {
    ref_difftest_exec(1);
  }
}

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  printf("img_size = %lu\n", img_size);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (ref_difftest_memcpy_type)dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (ref_difftest_regcpy_type)dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (ref_difftest_exec_type)dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (ref_difftest_raise_intr_type)dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  typedef void (*ref_difftest_init_type)(int n);
  ref_difftest_init_type ref_difftest_init = NULL;
  ref_difftest_init = (ref_difftest_init_type)dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  update_npc_cpu();
  npc_cpu.pc = CONFIG_MBASE;
  ref_difftest_regcpy(&npc_cpu, DIFFTEST_TO_REF);
}

const char *regs_name[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

const char *csrs_name[] = {
    "mepc", "mstatus", "mcause", "mtvec", "mvendorid", "marchid"
};

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  bool flag = true;
  if(g_pc != ref_r->pc) { printf("pc is diff, should be: 0x%x, but get: 0x%x\n", ref_r->pc, g_pc); flag = false;}
  for(int i=0; i<sizeof(ref_r->gpr)/sizeof(ref_r->gpr[0]); i++) {
    if(ref_r->gpr[i] != npc_cpu.gpr[i]) {
      printf("The %s reg is diff, shoud be %#x  but get %#x.\n", regs_name[i], ref_r->gpr[i], g_get_reg(i));
      flag = false;
      // break;
    }
  }
  for(int i=0; i<sizeof(ref_r->csrs)/sizeof(ref_r->csrs[0]); i++) {
    if(ref_r->csrs[i] != npc_cpu.csrs[i]) {
      printf("The %s csr is diff, shoud be %#x  but get %#x.\n", csrs_name[i], ref_r->csrs[i], g_get_csrs(i));
      flag = false;
      // break;
    }
  }
  return flag;
}

static void checkregs(CPU_state *ref, vaddr_t pc) {
  if (!isa_difftest_checkregs(ref, pc)) {
    u_npc_state.state = NPC_ABORT;
    u_npc_state.pc = pc;
    u_npc_state.ret = true;

    isa_reg_display();
  }
  // printf("ref n_pc: 0x%x, dut execd: 0x%x, dut n_pc: 0x%x\n", ref->pc, last_pc, g_pc);
}

void difftest_step(vaddr_t pc, vaddr_t npc) {
  CPU_state ref_r;

  if (skip_dut_nr_inst > 0) {
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    if (ref_r.pc == npc) {
      skip_dut_nr_inst = 0;
      checkregs(&ref_r, npc);
      return;
    }
    skip_dut_nr_inst --;
    if (skip_dut_nr_inst == 0)
      panic("can not catch up with ref.pc = " FMT_WORD " at pc = " FMT_WORD, ref_r.pc, pc);
    return;
  }

  if (is_skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    update_npc_cpu();
    ref_difftest_regcpy(&npc_cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
    return;
  }

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  checkregs(&ref_r, pc);
}

#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif
