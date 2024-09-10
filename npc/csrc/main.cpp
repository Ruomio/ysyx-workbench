
#include <cstdio>
#include <climits>
#include <verilated.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

#include "include/define.h"

static bool run_flag=0;
char *img_file = NULL;

static uint8_t memory[MSIZE];

void ebreak() {
    run_flag = 1;
    return;
}


int main(int argc, char **argv) {
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    
    Vtop *top = new Vtop(contextp);
    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("build/wave.vcd");

    top->rst = 0;
    
    while(!contextp->gotFinish()) {
        if(run_flag) break;
        top->clk ^= 1;
        static int i = 0;
        if(i++>1000) break;
        if(i>20) top->rst = 1;
        top->eval();
        // printf("pc  = 0x%x\n",top->pc);

        tfp->dump(contextp->time());
        contextp->timeInc(1);
    }
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