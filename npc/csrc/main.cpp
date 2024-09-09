
#include <cstdio>
#include <climits>
#include "Vtop.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include <verilated.h>
#include "verilated_vcd_c.h"


static TOP_NAME dut;

void ebreak() {return;}


int main(int argc, char **argv) {
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    
    Vtop *top = new Vtop(contextp);
    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("wave.vcd");

    while(!contextp->gotFinish()) {
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
