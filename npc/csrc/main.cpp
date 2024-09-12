
#include <cstdio>
#include <climits>
#include <verilated.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

#include "include/memory.h"
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
    printf("\33[1;31mNPC: HIT BAD TRAP. at pc=%u\033[0m\n",u_npc_state.pc);
  }
  else {
    printf("\33[1;32mNPC: HIT GOOD TRAP. at pc=%u\033[0m\n",u_npc_state.pc);
  }
}

static int parse_args(int argc, char *argv[]);

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
    check_trap(u_npc_state);
    top->final();
    delete top;
    tfp->close();
    delete contextp;
    return 0;
}


static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {"ftrace"   , required_argument, NULL, 'f'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhf:l:d:p:", table, NULL)) != -1) {
    switch (o) {
      // case 'b': sdb_set_batch_mode(); break;
      // case 'p': sscanf(optarg, "%d", &difftest_port); break;
      // case 'l': log_file = optarg; break;
      // case 'd': diff_so_file = optarg; break;
      // case 'f': ftrace_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\t-f,--ftrace=FILE        run with function trace\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

