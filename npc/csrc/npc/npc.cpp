#include <cstdint>
#include <readline/chardefs.h>
#include "define.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"


extern int argc;
extern char **argv;
extern npc_state u_npc_state;

Vtop *top = NULL;
VerilatedVcdC *tfp = NULL;
VerilatedContext *contextp = NULL;

static uint32_t last_pc;

void check_trap(npc_state u_npc_state);

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