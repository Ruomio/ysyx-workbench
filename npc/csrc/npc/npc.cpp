#include <cstdint>
#include <readline/chardefs.h>
#include <stdbool.h>
#include <stdint.h>
#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
#include "define.h"
#include "isa.h"
#include "memory/paddr.h"
#include "verilated_vcd_c.h"
#include "VysyxSoCFull__Dpi.h"
#include "common.h"
#include "ringbuffer.h"
#include <cpu/difftest.h>
#include <lightsss/lightsss.h>

#ifdef CONFIG_NVBOARD
#include <nvboard.h>
#include "VysyxSoCFull.h"

static TOP_NAME dut;
void nvboard_bind_all_pins(TOP_NAME *top);
#endif


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

VysyxSoCFull *top = NULL;
#if defined(CONFIG_WAVEFILE) || defined(CONFIG_LIGHTSSS)
VerilatedVcdC *tfp = NULL;
#endif
VerilatedContext *contextp = NULL;

npc_state u_npc_state = {.state=NPC_RUNNING, .pc=CONFIG_MBASE, .ret = true};

uint32_t g_pc;
static uint32_t last_pc;
static bool g_print_step = false;
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static uint32_t total_wave_step = 0; 

// LightSSS
LightSSS lightsss;
static auto last_snapshot_time = std::chrono::steady_clock::now();

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
#ifdef CONFIG_NVBOARD
  nvboard_bind_all_pins(&dut);
  nvboard_init();
#endif
  Verilated::commandArgs(argc, argv);

  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  top = new VysyxSoCFull(contextp);
#if defined(CONFIG_WAVEFILE) || defined(CONFIG_LIGHTSSS)
  tfp = new VerilatedVcdC;
  contextp->traceEverOn(true);
  top->trace(tfp, 0);
  tfp->open("build/wave.vcd");
#endif
  int i = 0;
  top->reset = 1;
  while(!contextp->gotFinish()) {
    top->clock ^= 1;
    top->eval();
#if defined(CONFIG_WAVEFILE) || defined(CONFIG_LIGHTSSS)
    tfp->dump(contextp->time());
    contextp->timeInc(1);
#endif
    if(i++ > 20) {
      top->reset = 0;
      break;
    }
#ifdef CONFIG_NVBOARD
    nvboard_update();
#endif
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
    top->clock ^= 1;
    top->eval();
#ifdef CONFIG_WAVEFILE
    if(total_wave_step > CONFIG_BASE_WAVE_STEP && total_wave_step < CONFIG_BASE_WAVE_STEP + CONFIG_MAX_WAVE_STEP) {
      total_wave_step++;
      tfp->dump(contextp->time());
      contextp->timeInc(1);
    }
    else 
      total_wave_step++;
#endif
#ifdef CONFIG_LIGHTSSS
    if(lightsss.get_flag() && lightsss.get_notgood()) {
      // total_wave_step++;
      tfp->dump(contextp->time());
      contextp->timeInc(1);
    }
    else {
      // total_wave_step++;
    }
#endif
    if(last_pc != g_get_pc()) {
      // printf("exec pc: 0x%x\n", last_pc);
      // Assert(g_pc >= CONFIG_MBASE, "pc invalid:0x%x, last pc: 0x%x", g_pc, last_pc);
      if(g_pc < CONFIG_MBASE) {
        u_npc_state.state = NPC_ABORT;
        u_npc_state.pc = pc;
        u_npc_state.ret = true;
        return;
      }
      else
        break;
    }
  }

#ifdef CONFIG_NVBOARD
    nvboard_update();
#endif

  g_nr_guest_inst ++;


#ifdef CONFIG_ITRACE
  char *p = inst_buf;
  p += snprintf(p, sizeof(inst_buf), FMT_WORD ":", last_pc);
  // int ilen = g_get_snpc() - last_pc;
  int ilen = 4;
  int i;
  uint32_t last_inst = paddr_read(last_pc, ilen);
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
    int snapshot_interval_seconds = 200; // 快照间隔时间（ms）
      
    auto current_time = std::chrono::steady_clock::now();
    auto elapsed_seconds = std::chrono::duration_cast<std::chrono::milliseconds>(current_time - last_snapshot_time).count();
    // printf("%ld, %ld, %ld\n", last_snapshot_time, current_time, elapsed_seconds);
    if (elapsed_seconds >= snapshot_interval_seconds && getpid() == lightsss.get_p_pid()) {
      lightsss.do_fork(); // 创建子进程快照
      last_snapshot_time = current_time;
    }

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
      int snapshot_interval_seconds = 200; // 快照间隔时间（ms）
      
      auto current_time = std::chrono::steady_clock::now();
      auto elapsed_seconds = std::chrono::duration_cast<std::chrono::milliseconds>(current_time - last_snapshot_time).count();
      if (elapsed_seconds >= snapshot_interval_seconds && getpid() == lightsss.get_p_pid()) {
        lightsss.do_fork(); // 创建子进程快照
        last_snapshot_time = current_time;
      }

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
      // 检测到结束或异常状态，通知最近的子进程生成波形
      if (u_npc_state.state == NPC_ABORT) {
        if(lightsss.get_p_pid() == getpid()) {
          lightsss.wakeup_child(timer_end); // 使用当前的时间作为cycles参数
          lightsss.do_clear();
        }
      }

    case NPC_QUIT: 
      statistic(); 
      if(lightsss.get_p_pid() == getpid()) {
        lightsss.do_clear();
      }
      else {
        exit(-1);
      }
      break;
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
  // g_pc =  top->rootp->top__DOT__u_npc__DOT__ifu__DOT__addr;
  g_pc  = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__ifu__DOT__addr;
  if(g_pc >= CONFIG_MBASE + CONFIG_MSIZE) {
    Assert(0, "pc is out of range pc = %x, last pc = %x",g_pc, last_pc);
  }
  return g_pc;
}

void g_set_pc(uint32_t pc) {
  // top->rootp->top__DOT__u_npc__DOT__ifu__DOT__addr = pc;
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__ifu__DOT__addr = pc;
}

uint32_t g_get_reg(int i) {
  // return (top->rootp->top__DOT__u_npc__DOT__u_reg__DOT__regs[i]);
  return (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_reg__DOT__regs[i]);
}

uint32_t g_get_snpc() {
  return g_pc + 4;
}

uint32_t g_get_dnpc() {
  // return top->rootp->top__DOT__u_npc__DOT__dnpc_wb;
  return top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__dnpc_wb;
}

uint32_t g_get_rs1() {
  // return BITS(top->rootp->top__DOT__u_npc__DOT__inst_ifu, 19, 15);
  return BITS(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__inst_ifu, 19, 15);
}
uint32_t g_get_rd() {
  // return BITS(top->rootp->top__DOT__u_npc__DOT__inst_ifu, 11, 7);
  return BITS(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__inst_ifu, 19, 7);
}

const char *regs_name[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};
bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  for(int i=0; i<sizeof(ref_r->gpr)/sizeof(ref_r->gpr[0]); i++) {
    if(ref_r->gpr[i] != g_get_reg(i)) {
      printf("The %s reg is diff, shoud be %#x  but get %#x.\n", regs_name[i], ref_r->gpr[i], g_get_reg(i));
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
    // top->rootp->top__DOT__u_npc__DOT__u_reg__DOT__regs[i] = npc_cpu.gpr[i];
    top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_reg__DOT__regs[i] = npc_cpu.gpr[i];
  }
  // top->pc = npc_cpu.pc;
  g_set_pc(npc_cpu.pc);
}

void printf_info() {
  printf("g_pc = 0x%x\n", g_pc);
}


extern "C" void npc_difftest_skip_ref() {
  IFDEF(CONFIG_DIFFTEST, difftest_skip_ref());
}