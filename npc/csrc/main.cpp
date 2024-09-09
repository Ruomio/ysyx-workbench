
#include <cstdio>
#include <climits>
#include <verilated.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"


void ebreak() {return;}


int main(int argc, char **argv) {
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    
    Vtop *top = new Vtop(contextp);
    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("build/wave.vcd");

    top->rst = 0;
    top->clk = 0;
    top->rst = 1;
    while(!contextp->gotFinish()) {
        top->clk = ~top->clk;
        static int i = 0;
        if(i++>6000) break;
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
