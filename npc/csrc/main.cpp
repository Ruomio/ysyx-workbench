
#include <cstdio>
#include <climits>
#include <verilated.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

#include "memory/memory.h"
#include "include/define.h"

char *img_file = NULL;
npc_state u_npc_state = {.state=NPC_RUNNING, .pc=0x80000000, .ret = true};


void ebreak() {
  u_npc_state.state = NPC_STOP;
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

extern int parse_args(int argc, char *argv[]);

int main(int argc, char **argv) {

  parse_args(argc, argv);

  init_memory();

  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  
  Vtop *top = new Vtop(contextp);
  contextp->traceEverOn(true);
  top->trace(tfp, 0);
  tfp->open("build/wave.vcd");

  top->rst = 0;
  
  while(!contextp->gotFinish()) {
      if(u_npc_state.state != NPC_RUNNING) {
        u_npc_state.pc = top->pc;
        break;
      }
      top->clk ^= 1;
      static int i = 0;
      if(i++>1000) break;
      if(i>20) top->rst = 1;
      top->eval();
      // printf("pc  = 0x%x\n",top->pc);

      tfp->dump(contextp->time());
      contextp->timeInc(1);
  }
  free_memory();
  check_trap(u_npc_state);
  top->final();
  delete top;
  tfp->close();
  delete contextp;
  return 0;
}




