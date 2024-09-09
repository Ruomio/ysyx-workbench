
#include <climits>
#include <nvboard.h>
#include "Vtop.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME *top);
void ebreak() {return;}

static void single_cycle() {
    dut.clk = 1;
    dut.clk = 0;
    dut.eval();
    printf("pc = 0x%x\n", dut.pc);
}

static void reset(int n) {
    dut.rst = 0;
    while(n-- > 0) single_cycle();
    dut.rst = 1;
}

int main() {
    nvboard_bind_all_pins(&dut);
    nvboard_init();
    
    reset(10);

    while (1) {
        nvboard_update();
        single_cycle();
    }

    // nvboard_quit();
}

