
#include <cstdio>
#include <climits>
#include <verilated.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

static bool run_flag=0;

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
        printf("pc  = 0x%x\n",top->pc);

        tfp->dump(contextp->time());
        contextp->timeInc(1);
    }
    top->final();
    delete top;
    tfp->close();
    delete contextp;
    return 0;
}
