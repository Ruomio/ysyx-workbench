
#include <climits>
#include <nvboard.h>
#include "Vtop.h"

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME *top);

static void single_cycle() {
    // dut.a = rand()&1;
    // dut.b = rand()&1; 
    dut.eval();
}

static void reset(int n) {
    dut.a = 0;
    while(n-- > 0) single_cycle();
    dut.a = 1;
}

int main() {
    nvboard_bind_all_pins(&dut);
    nvboard_init();
    
    // reset(10);

    while (1) {
        nvboard_update();
        single_cycle();
    }

    // nvboard_quit();
}


// #include <cstdio>
// #include <verilated.h>
// #include "verilated_vcd_c.h"
// #include "Vtop.h"
// 
// int main(int argc, char **argv) {
//     VerilatedContext *contextp = new VerilatedContext;
//     contextp->commandArgs(argc, argv);
//     VerilatedVcdC *tfp = new VerilatedVcdC;
//     
//     Vtop *top = new Vtop(contextp);
//     contextp->traceEverOn(true);
//     top->trace(tfp, 0);
//     tfp->open("wave.vcd");
// 
//     while(!contextp->gotFinish()) {
//         static int i = 0;
//         if(i++>50) break;
//         top->a = rand()&1;
//         top->b = rand()&1;
//         top->eval();
//         printf("top->a = %d\n",top->a);
//         printf("top->b = %d\n",top->b);
//         printf("top->f = %d\n",top->f);
// 
//         tfp->dump(contextp->time());
//         contextp->timeInc(1);
//     }
//     top->final();
//     delete top;
//     tfp->close();
//     delete contextp;
//     return 0;
// }
