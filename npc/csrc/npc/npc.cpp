#include <cstdint>
#include <readline/chardefs.h>
#include "Vtop.h"
#include "Vtop___024root.h"
#include "define.h"
#include "memory/paddr.h"
#include "verilated_vcd_c.h"
#include "Vtop__Dpi.h"
#include "common.h"
#include "ringbuffer.h"


extern int argc;
extern char **argv;
extern npc_state u_npc_state;
extern uint8_t *memory;

extern "C" disassemble(char*, int, unsigned long, unsigned char*, int);

Vtop *top = NULL;
VerilatedVcdC *tfp = NULL;
VerilatedContext *contextp = NULL;

static uint32_t last_pc;

char inst_buf[1024];

void check_trap(npc_state u_npc_state);
uint32_t g_get_snpc();

void init_npc() {
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  tfp = new VerilatedVcdC;
  
  top = new Vtop(contextp);
  contextp->traceEverOn(true);
  top->trace(tfp, 0);
  tfp->open("build/wave.vcd");

  int i = 0;
  top->rst = 0;
  while(!contextp->gotFinish()) {
    top->clk ^= 1;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    if(i++ > 20) {
      top->rst = 1;
      break;
    }
  }
}

void exec_once_npc(uint32_t pc) {
  printf("exec once, pc = %#x\n", pc);
  last_pc = pc;
  while(!contextp->gotFinish()) {
    if(u_npc_state.state != NPC_RUNNING) {
      u_npc_state.pc = pc;
      return;
    }
    top->clk ^= 1;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    if(last_pc != top->pc) {
      printf("last_pc = %#x, pc = %#x\n", last_pc, top->pc);
      break;
    }
  }
#ifdef CONFIG_ITRACE
  char *p = inst_buf;
  p += snprintf(p, sizeof(inst_buf), FMT_WORD ":", top->pc);
  int ilen = g_get_snpc() - top->pc;
  int i;
  uint8_t *inst = (uint8_t *)guest_to_host(last_pc);
  for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

#ifndef CONFIG_ISA_loongarch32r
  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, inst_buf + sizeof(inst_buf) - p,
      MUXDEF(CONFIG_ISA_x86, g_get_snpc(), top->pc), (uint8_t *)guest_to_host(last_pc), ilen);
#else
  p[0] = '\0'; // the upstream llvm does not support loongarch32r
#endif
  RingBuffer_write(inst_buf, strlen(inst_buf));
#endif
}

void exec_all_npc() {
  printf("exec all\n");
  while(!contextp->gotFinish()) {
    if(u_npc_state.state != NPC_RUNNING) {
      u_npc_state.pc = top->pc;
      return;
    }
    top->clk ^= 1;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
  }
}

void exec_npc(int n) {
  switch (u_npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: u_npc_state.state = NPC_RUNNING;
  }
  if(n < 0) {
    exec_all_npc();
  }
  else {
    for(; n>0; n--) {
      if (u_npc_state.state != NPC_RUNNING) break;
      exec_once_npc(top->pc);
    }
  }
  switch(u_npc_state.state) {
    case NPC_END: case NPC_ABORT:
      check_trap(u_npc_state);
      break;

    case NPC_QUIT: break;;
    default: break;;
  }
}

void free_npc() {
  check_trap(u_npc_state);
  if(top) {
    top->final();
    delete top;
    top = NULL;
  }
  if(tfp) {
    tfp->close();
  }
  if(contextp) {
    delete contextp;
    contextp = NULL;
  }
}


void ebreak() {
  u_npc_state.state = NPC_END;
  u_npc_state.ret = true;
}

void invalid_inst() {
  u_npc_state.state = NPC_ABORT;
  u_npc_state.ret = false;
  printf("Unknown inst.\n");
}

void halt() {
  ebreak();
}

void check_trap(npc_state u_npc_state) {
  if(!u_npc_state.ret) {
    printf("\33[1;31mNPC: HIT BAD TRAP. at pc=%#x\033[0m\n",u_npc_state.pc);
  }
  else {
    printf("\33[1;32mNPC: HIT GOOD TRAP. at pc=%#x\033[0m\n",u_npc_state.pc);
  }
}

uint32_t g_get_pc() {
  return top->pc;
}

uint32_t g_get_reg(int i) {
  return (top->rootp->top__DOT__u_npc__DOT__u_reg__DOT__regs[i]);
}

uint32_t g_get_snpc() {
  return top->rootp->top__DOT__u_npc__DOT__ifu__DOT__snpc_reg;
}