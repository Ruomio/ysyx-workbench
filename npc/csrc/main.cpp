#include <cstdio>
#include <verilated.h>
#include "verilated_vcd_c.h"
#include "Vexample.h"

int main(int argc, char **argv) {
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    
    Vexample *top = new Vexample(contextp);
    contextp->traceEverOn(true);
    top->trace(tfp, 0);
    tfp->open("wave.vcd");

    while(!contextp->gotFinish()) {
        static int i = 0;
        if(i++>50) break;
        top->a = rand()&1;
        top->b = rand()&1;
        top->eval();
        printf("top->a = %d\n",top->a);
        printf("top->b = %d\n",top->b);
        printf("top->f = %d\n",top->f);

        tfp->dump(contextp->time());
        contextp->timeInc(1);
    }
    top->final();
    delete top;
    tfp->close();
    delete contextp;
    return 0;
}
