#include <cstdint>
#include <readline/chardefs.h>
#include <stdbool.h>
#include <stdint.h>
#include "Vtop.h"
#include "Vtop___024root.h"
#include "define.h"
#include "isa.h"
#include "memory/paddr.h"
#include "verilated_vcd_c.h"
// #include "Vtop__Dpi.h"
#include "common.h"
#include "ringbuffer.h"
#include <cpu/difftest.h>

#define MAX_WAVE_STEP 10000

// TRACE
extern "C" void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
extern void MtraceBuf_add_arrow();
extern void MtraceBuf_save();
extern int update_ftrace(uint32_t pc, uint32_t addr, uint32_t rs1, uint32_t rd);
extern int close_ftrace();
extern void scan_watchpoint(bool *is_change, bool *is_break);

// difftest
CPU_state npc_cpu;
extern void difftest_skip_ref();
extern void difftest_skip_dut(int nr_ref, int nr_dut);
extern void difftest_step(vaddr_t pc, vaddr_t npc);

Vtop *top = NULL;
#ifdef CONFIG_WAVEFILE
VerilatedVcdC *tfp = NULL;
#endif
VerilatedContext *contextp = NULL;

npc_state u_npc_state = {.state=NPC_RUNNING, .pc=0x80000000, .ret = true};

uint32_t g_pc;
static uint32_t last_pc;
static bool g_print_step = false;
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static uint32_t total_wave_stop = 0; 

#ifdef CONFIG_ITRACE
char inst_buf[128] = {};
#endif

void check_trap(npc_state u_npc_state);

uint32_t g_get_pc();
uint32_t g_get_snpc();
uint32_t g_get_dnpc();
uint32_t g_get_rs1();
uint32_t g_get_rd();
void update_npc_cpu();

static void trace_and_difftest(vaddr_t dnpc) {
#ifdef CONFIG_ITRACE_COND
  if (ITRACE_COND) { log_write("%s\n", inst_buf); }
#endif
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(inst_buf)); }
  IFDEF(CONFIG_DIFFTEST, difftest_step(g_pc, g_get_dnpc()));

#ifdef CONFIG_WATCH_POINT
  // scan and print all watch point and break point
  bool is_chang = false;
  bool is_break = false;
  scan_watchpoint(&is_chang, &is_break);
  if((is_chang || is_break) && u_npc_state.state == NPC_RUNNING) u_npc_state.state = NPC_STOP;
#endif
}

void init_npc(int argc, char **argv) {
  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new Vtop(contextp);
#ifdef CONFIG_WAVEFILE
  tfp = new VerilatedVcdC;
  contextp->traceEverOn(true);
  top->trace(tfp, 0);
  tfp->open("build/wave.vcd");
#endif
  int i = 0;
  top->rst = 0;
  while(!contextp->gotFinish()) {
    top->clk ^= 1;
    top->eval();
#ifdef CONFIG_WAVEFILE
    tfp->dump(contextp->time());
    contextp->timeInc(1);
#endif
    if(i++ > 20) {
      top->rst = 1;
      break;
    }
  }
  g_get_pc();
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
#ifdef CONFIG_WAVEFILE
    if(total_wave_stop++ < MAX_WAVE_STEP) {
      tfp->dump(contextp->time());
      contextp->timeInc(1);
    }
#endif
    if(last_pc != g_get_pc()) {
      break;
    }
  }

  g_nr_guest_inst ++;


#ifdef CONFIG_ITRACE
  char *p = inst_buf;
  p += snprintf(p, sizeof(inst_buf), FMT_WORD ":", last_pc);
  // int ilen = g_get_snpc() - last_pc;
  int ilen = 4;
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


  trace_and_difftest(g_pc);
}

void exec_all_npc() {
  while(u_npc_state.state == NPC_RUNNING) {
    exec_once_npc(g_pc);
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
  IFDEF(CONFIG_DTRACE_COND, dtrace_free());
  IFDEF(CONFIG_ETRACE_COND, etrace_close());
  if(u_npc_state.state == NPC_ABORT) {IFDEF(CONFIG_ITRACE, RingBuffer_add_arrow(); RingBuffer_print(); RingBuffer_save_file(););}
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

void exec_npc(int n) {
  g_print_step = n < 10;
  switch (u_npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: u_npc_state.state = NPC_RUNNING;
  }

  uint64_t timer_start = get_time();


  if(n < 0) {
    exec_all_npc();
  }
  else {
    for(; n>0; n--) {
      if (u_npc_state.state != NPC_RUNNING) break;
      exec_once_npc(g_pc);
    }
  }


  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;


  switch(u_npc_state.state) {
    case NPC_END: case NPC_ABORT:
      check_trap(u_npc_state);
      // break;

    case NPC_QUIT: statistic(); break;;
    default: break;;
  }
}

void free_npc() {
  IFDEF(CONFIG_MTRACE, MtraceBuf_add_arrow(); MtraceBuf_save());
  IFDEF(CONFIG_FTRACE, close_ftrace());
  if(top) {
    top->final();
    delete top;
    top = NULL;
  }
#ifdef CONFIG_WAVEFILE
  if(tfp) {
    tfp->close();
  }
#endif
  if(contextp) {
    delete contextp;
    contextp = NULL;
  }
}

void update_ftrace_dpi() {
  IFDEF(CONFIG_FTRACE, update_ftrace(last_pc, g_get_dnpc(), g_get_rs1(), g_get_rd()));
}

void ebreak() {
  u_npc_state.state = NPC_END;
  u_npc_state.ret = false;
  u_npc_state.pc = g_pc;
}

void invalid_inst() {
  u_npc_state.state = NPC_ABORT;
  u_npc_state.ret = true;
  printf("Unknown inst.\n");
}

void halt() {
  ebreak();
}

void check_trap(npc_state u_npc_state) {
  if(u_npc_state.ret) {
    printf("\33[1;31mNPC: HIT BAD TRAP. at pc=%#x\033[0m\n",u_npc_state.pc);
  }
  else {
    printf("\33[1;32mNPC: HIT GOOD TRAP. at pc=%#x\033[0m\n",u_npc_state.pc);
  }
}

uint32_t g_get_pc() {
  g_pc =  top->rootp->top__DOT__u_npc__DOT__ifu__DOT__addr;
  return g_pc;
}

void g_set_pc(uint32_t pc) {
  top->rootp->top__DOT__u_npc__DOT__ifu__DOT__addr = pc;
}

uint32_t g_get_reg(int i) {
  return (top->rootp->top__DOT__u_npc__DOT__u_reg__DOT__regs[i]);
}

uint32_t g_get_snpc() {
  return g_pc + 4;
}

uint32_t g_get_dnpc() {
  return top->rootp->top__DOT__u_npc__DOT__dnpc_wb;
}

uint32_t g_get_rs1() {
  return BITS(top->rootp->top__DOT__u_npc__DOT__inst_ifu, 19, 15);
}
uint32_t g_get_rd() {
  return BITS(top->rootp->top__DOT__u_npc__DOT__inst_ifu, 11, 7);
}

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for(int i=0; i<sizeof(ref_r->gpr)/sizeof(ref_r->gpr[0]); i++) {
    if(ref_r->gpr[i] != g_get_reg(i)) {
      printf("The %dth reg is diff, shoud be %#x  but get %#x.\n", i, ref_r->gpr[i], g_get_reg(i));
      return false;
    }
  }
  if(pc != g_pc) return false;
  return true;
}

void update_npc_cpu() {
  for(int i=0; i<32; i++) {
    npc_cpu.gpr[i] = g_get_reg(i);
  }
  npc_cpu.pc = g_pc;
}

void update_dut() {
  for(int i=0; i<32; i++) {
    top->rootp->top__DOT__u_npc__DOT__u_reg__DOT__regs[i] = npc_cpu.gpr[i];
  }
  // top->pc = npc_cpu.pc;
  g_set_pc(npc_cpu.pc);
}

void printf_info() {
  printf("araddr arbiter = 0x%x\n", top->rootp->top__DOT__u_npc__DOT__ifu__DOT__addr);
  printf("araddr ifu = 0x%x\n", top->rootp->top__DOT__u_npc__DOT__ifu__DOT__addr);
  printf("pc ifu = 0x%x\n", top->rootp->top__DOT__u_npc__DOT__pc_ifu);

  printf("g_pc = 0x%x\n", g_pc);
}