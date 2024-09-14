#include <cstdint>
#include <readline/chardefs.h>
#include <stdint.h>
#include "Vtop.h"
#include "Vtop___024root.h"
#include "define.h"
#include "memory/paddr.h"
#include "verilated_vcd_c.h"
#include "Vtop__Dpi.h"
#include "common.h"
#include "ringbuffer.h"


extern int argc;
extern char **argv;
extern npc_state u_npc_state;
extern uint8_t *memory;

extern "C" void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
extern void MtraceBuf_add_arrow(); 
extern void MtraceBuf_save();
extern int update_ftrace(uint32_t pc, uint32_t addr, uint32_t rs1, uint32_t rd);
extern int close_ftrace();

Vtop *top = NULL;
VerilatedVcdC *tfp = NULL;
VerilatedContext *contextp = NULL;

static uint32_t last_pc;
static bool g_print_step = false;

#ifdef CONFIG_ITRACE
char inst_buf[128] = {};
#endif

void check_trap(npc_state u_npc_state);

uint32_t g_get_pc();
uint32_t g_get_snpc();
uint32_t g_get_dnpc();
uint32_t g_get_rs1();
uint32_t g_get_rd();

static void trace_and_difftest(vaddr_t dnpc) {
#ifdef CONFIG_ITRACE_COND
  if (ITRACE_COND) { log_write("%s\n", _this->logbuf); }
#endif
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(inst_buf)); }
  IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, dnpc));

#ifdef CONFIG_WATCHPOINT_COND
  // scan and print all watch point and break point
  bool is_chang = false;
  bool is_break = false;
  scan_watchpoint(&is_chang, &is_break);
  if((is_chang || is_break) && nemu_state.state == NEMU_RUNNING) nemu_state.state = NEMU_STOP;
#endif
}

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
      break;
    }
  }
#ifdef CONFIG_ITRACE
  char *p = inst_buf;
  p += snprintf(p, sizeof(inst_buf), FMT_WORD ":", last_pc);
  int ilen = g_get_snpc() - last_pc;
  int i;
  uint32_t last_inst = read_memory(last_pc, ilen);
  uint8_t *inst = (uint8_t *)&last_inst;
  for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

#ifndef CONFIG_ISA_loongarch32r
  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, inst_buf + sizeof(inst_buf) - p,
      MUXDEF(CONFIG_ISA_x86, g_get_snpc(), last_pc), (uint8_t *)&last_inst, ilen);
#else
  p[0] = '\0'; // the upstream llvm does not support loongarch32r
#endif
  // RingBuffer_write(inst_buf, strlen(inst_buf));
#endif
}

void exec_all_npc() {
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
  g_print_step = n < 10;
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
      trace_and_difftest(g_get_dnpc());
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
  IFDEF(CONFIG_MTRACE, MtraceBuf_add_arrow(); MtraceBuf_save());
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

void update_ftace_dpi() {
  IFDEF(CONFIG_FTRACE, update_ftrace(g_get_pc(), g_get_dnpc(), g_get_rs1(), g_get_rd()));
}
static void close_ftace() {
  IFDEF(CONFIG_FTRACE, close_ftrace());
}



void ebreak() {
  u_npc_state.state = NPC_END;
  u_npc_state.ret = true;
  close_ftace();
}

void invalid_inst() {
  u_npc_state.state = NPC_ABORT;
  u_npc_state.ret = false;
  printf("Unknown inst.\n");
  close_ftace();
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

uint32_t g_get_reg(int i) {
  return (top->rootp->top__DOT__u_npc__DOT__u_reg__DOT__regs[i]);
}

uint32_t g_get_snpc() {
  return top->rootp->top__DOT__u_npc__DOT__ifu__DOT__snpc_reg;
}

uint32_t g_get_dnpc() {
  return top->rootp->top__DOT__u_npc__DOT__dnpc;
}

uint32_t g_get_rs1() {
  return BITS(top->rootp->__Vdly__top__DOT__u_npc__DOT__inst, 19, 15);
}
uint32_t g_get_rd() {
  return BITS(top->rootp->__Vdly__top__DOT__u_npc__DOT__inst, 11, 7);
}