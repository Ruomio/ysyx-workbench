#include <readline/chardefs.h>
#include "define.h"
#include "difftest-def.h"
#include "memory/paddr.h"
#include "verilated_vcd_c.h"
#include "common.h"
#include "ringbuffer.h"

#include "isa.h"
#include <cpu/difftest.h>
#include <stdio.h>

#if defined(ysyxSoCFull)
#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
#include "VysyxSoCFull__Dpi.h"
#define set_reset top->reset = 1
#define set_unreset top->reset = 0
#define toggle_clock top->clock ^= 1
#define is_clk_high (top->clock == 1)

#elif defined(ysyx_24080020_NPC)
#include "Vysyx_24080020_NPC.h"
#include "Vysyx_24080020_NPC___024root.h"
#include "Vysyx_24080020_NPC__Dpi.h"

#define set_reset top->rst = 0
#define set_unreset top->rst = 1
#define toggle_clock top->clk ^= 1
#define is_clk_high (top->clk == 1)
#endif

#ifdef CONFIG_LIGHTSSS
#include <lightsss/lightsss.h>
#endif

#if defined (CONFIG_NVBOARD) && defined (ysyxSoCFull)
#include <nvboard.h>

#define NVBOARD_ENABLE 1

void nvboard_bind_all_pins(TOP_NAME *top);
void nvboard_init(int);
void nvboard_update();
void nvboard_quit();
#else
#define NVBOARDNABLE 0
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

#if defined(ysyxSoCFull)
VysyxSoCFull *top = NULL;
#elif defined(ysyx_24080020_NPC)
Vysyx_24080020_NPC *top = NULL;
#endif
#if defined(CONFIG_WAVEFILE) || defined(CONFIG_LIGHTSSS)
VerilatedVcdC *tfp = NULL;
#endif
VerilatedContext *contextp = NULL;

npc_state u_npc_state = {.state=NPC_RUNNING, .pc=CONFIG_MBASE, .ret = true};

uint32_t g_pc, g_dnpc;
uint32_t last_pc;
static bool g_print_step = false;
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static uint32_t total_wave_step = 0;
static uint64_t total_cycles = 0;
static uint64_t wait_cycles = 0;
static uint64_t ifu_get_inst_cnt = 0;
static uint64_t ifu_icache_hit_cnt = 0;
static uint64_t ifu_icache_miss_cnt = 0;
static uint64_t dcache_hit_cnt = 0;
static uint64_t lsu_get_data_cnt = 0;
static uint64_t exu_complete_calcu_cnt = 0;
static uint64_t idu_calculate_type_cnt = 0;
static uint64_t idu_load_type_cnt = 0;
static uint64_t idu_store_type_cnt = 0;
static uint64_t idu_csr_type_cnt = 0;
static uint64_t idu_jump_type_cnt = 0;
static uint64_t btb_total_cnt = 0;
static uint64_t btb_hit_cnt = 0;

enum statistics_type{None=0, Calculate, Load, Store, CSR, Jump, Fetch, Icache_Hit, Icache_Miss};
static int idu_type = None;
static int icache_type = None;
static uint64_t idu_calculate_cycles = 0;
static uint64_t idu_load_cycles = 0;
static uint64_t idu_store_cycles = 0;
static uint64_t idu_csr_cycles = 0;
static uint64_t idu_jump_cycles = 0;
static uint64_t ifu_get_inst_cycles = 0;
static uint64_t ifu_icache_hit_cycles = 0;
static uint64_t ifu_icache_miss_cycles = 0;

#ifdef CONFIG_LIGHTSSS
// LightSSS
LightSSS lightsss;
static auto last_snapshot_time = std::chrono::steady_clock::now();
#endif

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
  IFDEF(CONFIG_DIFFTEST, difftest_step(last_pc, dnpc));

#ifdef CONFIG_WATCH_POINT
  // scan and print all watch point and break point
  bool is_chang = false;
  bool is_break = false;
  scan_watchpoint(&is_chang, &is_break);
  if((is_chang || is_break) && u_npc_state.state == NPC_RUNNING) u_npc_state.state = NPC_STOP;
#endif
}

void init_npc(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
#if defined(ysyxSoCFull)
  top = new VysyxSoCFull(contextp);
#elif defined(ysyx_24080020_NPC)
  top = new Vysyx_24080020_NPC(contextp);
#endif
#if defined(CONFIG_WAVEFILE) || defined(CONFIG_LIGHTSSS)
  // tfp = new VerilatedVcdC;
  // contextp->traceEverOn(true);
  // top->trace(tfp, 0);
  // tfp->open("build/wave.vcd");
#endif
#if NVBOARD_ENABLE
  nvboard_bind_all_pins(top);
  nvboard_init(1);
#endif
  int i = 0;
  set_reset;
  while(!contextp->gotFinish()) {
    toggle_clock;
    top->eval();
#if defined(CONFIG_WAVEFILE) || defined(CONFIG_LIGHTSSS)
    if(tfp) {
        tfp->dump(contextp->time());
        contextp->timeInc(1);
    }
#endif
    if(i++ > 20) {
      set_unreset;
#ifdef CONFIG_LIGHTSSS
    if (!lightsss.is_child()) {
      lightsss.do_fork(); // 创建子进程快照
    }
#endif
      break;
    }
    if(is_clk_high) {
      g_get_pc();
      total_cycles++;
#if NVBOARD_ENABLE
      nvboard_update();
#endif
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
    // top->clock ^= 1;
    toggle_clock;
    top->eval();
#ifdef CONFIG_WAVEFILE
    if(total_wave_step > CONFIG_BASE_WAVE_STEP && total_wave_step < CONFIG_BASE_WAVE_STEP + CONFIG_MAX_WAVE_STEP) {
      total_wave_step++;
      if(tfp) {
        tfp->dump(contextp->time());
        contextp->timeInc(1);
      }
    }
    else
      total_wave_step++;
#endif
#ifdef CONFIG_LIGHTSSS
    if(lightsss.get_flag() && lightsss.get_notgood()) {
      // total_wave_step++;
      if(tfp) {
        tfp->dump(contextp->time());
        contextp->timeInc(1);
      }
    }
    else {
      // total_wave_step++;
    }
#endif
    if(is_clk_high) {
      g_get_pc();
      total_cycles++;
      if(wait_cycles++ > 80000) {
        printf("wait too many cycles, maybe dead loop, last_pc:0x%x\n", last_pc);
        u_npc_state.state = NPC_ABORT;
        u_npc_state.pc = pc;
        u_npc_state.ret = true;
        return;
      }

      // test lightsss
      // if(g_pc == 0x300000e4) {
      //   printf("test lightsss\n");
      //   u_npc_state.state = NPC_ABORT;
      //   u_npc_state.pc = pc;
      //   u_npc_state.ret = true;
      //   return;
      // }

#if NVBOARD_ENABLE
#ifdef CONFIG_LIGHTSSS
      if(!lightsss.is_child()) {
          nvboard_update();
      }
#else
      nvboard_update();
#endif
#endif
      // printf("idu_type: %d, at pc: 0x%x\n", idu_type, g_pc);
      switch(idu_type) {
        case None: break;
        case Calculate: idu_calculate_cycles++; break;
        case Load: idu_load_cycles++; break;
        case Store: idu_store_cycles++; break;
        case CSR: idu_csr_cycles++; break;
        case Jump: idu_jump_cycles++; break;
        default: break;
      }
      switch(icache_type) {
        case None: {
          ifu_get_inst_cycles++;
          break;
        }
        case Icache_Hit: {
          ifu_icache_hit_cycles++;
          ifu_get_inst_cycles++;
          break;
        }
        case Icache_Miss: {
          ifu_icache_miss_cycles++;
          ifu_get_inst_cycles++;
          break;
        }
        case Fetch: break;
        default: break;
      }
    }
    if(last_pc != g_get_pc()) {
      if(g_pc == CONFIG_MBASE || g_pc == 0) {
          last_pc = g_pc;
          continue;
      }
      // printf("exec pc: 0x%x\n", last_pc);
      // Assert(g_pc >= CONFIG_MBASE, "pc invalid:0x%x, last pc: 0x%x", g_pc, last_pc);
      // idu_type = None;
      if(g_pc < CONFIG_MBASE) {
        u_npc_state.state = NPC_ABORT;
        u_npc_state.pc = pc;
        u_npc_state.ret = true;
        return;
      }
      else {
        wait_cycles = 0;
        break;
      }
    }
  }



  g_nr_guest_inst ++;


#ifdef CONFIG_ITRACE
  char *p = inst_buf;
  p += snprintf(p, sizeof(inst_buf), FMT_WORD ":", g_pc);
  // int ilen = g_get_snpc() - last_pc;
  int ilen = 4;
  int i;
  uint32_t last_inst = paddr_read(g_pc, ilen);
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
      MUXDEF(CONFIG_ISA_x86, g_get_snpc(), g_pc), (uint8_t *)&last_inst, ilen);
#else
  p[0] = '\0'; // the upstream llvm does not support loongarch32r
#endif
  // RingBuffer_write(inst_buf, strlen(inst_buf));
#endif

  // printf("npc exec pc: 0x%x, dnpc:0x%x\n", g_pc, g_get_dnpc());
  trace_and_difftest(g_pc);
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
  IFDEF(CONFIG_DTRACE_COND, dtrace_free());
  IFDEF(CONFIG_ETRACE_COND, etrace_close());
  IFDEF(CONFIG_MTRACE, MtraceBuf_add_arrow(); MtraceBuf_save());
  IFDEF(CONFIG_FTRACE, close_ftrace());
  if(u_npc_state.state == NPC_ABORT) {IFDEF(CONFIG_ITRACE, RingBuffer_add_arrow(); RingBuffer_print(); RingBuffer_save_file(););}
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
  Log("total_cycles = " NUMBERIC_FMT "  IPC = %lf", total_cycles, ((double)g_nr_guest_inst / total_cycles));

  if(!ifu_get_inst_cnt) printf("ifu_get_inst_cnt is 0\n");
  if(!idu_jump_type_cnt) printf("idu_jump_type_cnt is 0\n");
  if(!idu_csr_type_cnt) printf("idu_csr_type_cnt is 0\n");
  if(!idu_store_type_cnt) printf("idu_store_type_cnt is 0\n");
  if(!idu_load_type_cnt) printf("idu_load_type_cnt is 0\n");
  if(!idu_calculate_type_cnt) printf("idu_calculate_type_cnt is 0\n");

  if(ifu_get_inst_cnt && idu_jump_type_cnt && idu_csr_type_cnt && idu_store_type_cnt && idu_load_type_cnt && idu_calculate_type_cnt ) {
    float access_time = ifu_icache_hit_cycles*1.0 / ifu_icache_hit_cnt;
    float icache_hit_rate = ifu_icache_hit_cnt*1.0 / ifu_get_inst_cnt;
    float miss_time = ifu_icache_miss_cycles*1.0 / ifu_icache_miss_cnt;
    float icache_miss_rate =  1.0 - icache_hit_rate;

    Log("ifu_get_inst_cnt = " NUMBERIC_FMT " Average: %ld", ifu_get_inst_cnt, ifu_get_inst_cycles / ifu_get_inst_cnt);
    Log("ifu_icache_hit_cnt = " NUMBERIC_FMT " Percentage: %.2f%%, AMAT: %.2lf, TMT: %.2f", ifu_icache_hit_cnt, icache_hit_rate * 100.0, icache_hit_rate * access_time + icache_miss_rate * miss_time, miss_time );
    Log("dcache_hit_cnt = " NUMBERIC_FMT " Percentage: %.2f%% ", dcache_hit_cnt, dcache_hit_cnt * 100.0 / (ifu_get_inst_cnt) );
    Log("lsu_get_data_cnt = " NUMBERIC_FMT, lsu_get_data_cnt);
    Log("exu_complete_culca_cnt = " NUMBERIC_FMT, exu_complete_calcu_cnt);
    Log("idu_calcu_type_cnt = " NUMBERIC_FMT " Percentage: %.2f%%  Average: %ld", idu_calculate_type_cnt, idu_calculate_type_cnt * 100.0 / ifu_get_inst_cnt, idu_calculate_cycles / idu_calculate_type_cnt);
    Log("idu_load_type_cnt = " NUMBERIC_FMT " Percentage: %.2f%%  Average: %ld", idu_load_type_cnt, idu_load_type_cnt * 100.0 / ifu_get_inst_cnt, idu_load_cycles / idu_load_type_cnt);
    Log("idu_store_type_cnt = " NUMBERIC_FMT " Percentage: %.2f%%  Average: %ld", idu_store_type_cnt, idu_store_type_cnt * 100.0 / ifu_get_inst_cnt, idu_store_cycles / idu_store_type_cnt);
    Log("idu_csr_type_cnt = " NUMBERIC_FMT " Percentage: %.2f%%  Average: %ld", idu_csr_type_cnt, idu_csr_type_cnt * 100.0 / ifu_get_inst_cnt, idu_csr_cycles / idu_csr_type_cnt);
    Log("idu_jump_type_cnt = " NUMBERIC_FMT " Percentage: %.2f%%  Average: %ld", idu_jump_type_cnt, idu_jump_type_cnt * 100.0 / ifu_get_inst_cnt, idu_jump_cycles / idu_jump_type_cnt);
  }

  // BTB
  if(btb_total_cnt) {
    Log("btb_hit_cnt = " NUMBERIC_FMT " btb_total_cnt = " NUMBERIC_FMT " Percentage: %.2f%%", btb_hit_cnt, btb_total_cnt, btb_hit_cnt * 100.0 / btb_total_cnt);
  }
}

void exec_npc(uint64_t n) {
  g_print_step = n < 10;
  switch (u_npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: u_npc_state.state = NPC_RUNNING;
  }

  uint64_t timer_start = get_time();



  for(; n>0; n--) {
#ifdef CONFIG_LIGHTSSS
    int snapshot_interval_seconds = 50; // 快照间隔时间（ms）

    auto current_time = std::chrono::steady_clock::now();
    auto elapsed_seconds = std::chrono::duration_cast<std::chrono::milliseconds>(current_time - last_snapshot_time).count();
    if (elapsed_seconds >= snapshot_interval_seconds && !lightsss.is_child()) {
      lightsss.do_fork(); // 创建子进程快照
      last_snapshot_time = current_time;
    }
    if(lightsss.is_child()) {
        if(!tfp) {
            tfp = new VerilatedVcdC;
            contextp->traceEverOn(true);
            top->trace(tfp, 0);
            tfp->open("build/wave.vcd");
        }
    }
#endif

    if (u_npc_state.state != NPC_RUNNING) break;
    exec_once_npc(g_pc);
  }


  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;


  switch(u_npc_state.state) {
    case NPC_END: case NPC_ABORT:
      check_trap(u_npc_state);
      // break;
#ifdef CONFIG_LIGHTSSS
      // 检测到结束或异常状态，通知最近的子进程生成波形
      if (u_npc_state.state == NPC_ABORT) {
        if(!lightsss.is_child()) {
          lightsss.wakeup_child(timer_end); // 使用当前的时间作为cycles参数
        }
      }
#endif
    case NPC_QUIT:
      statistic();
#ifdef CONFIG_LIGHTSSS
      if(!lightsss.is_child()) {
        lightsss.do_clear();
      }
      else {
          // not use exit(), because exit would release resources, which belongs parents' process.
          // _exit(-1);
      }
#endif
      break;
    default: break;;
  }
}

void free_npc() {
#if defined (CONFIG_LIGHTSSS)
  if(lightsss.is_child()) {
    // return;
  }
#endif

  if(top) {
    top->final();
    delete top;
    top = NULL;
  }
#if defined (CONFIG_WAVEFILE) || defined (CONFIG_LIGHTSSS)
  if(tfp) {
    tfp->close();
    delete tfp;
    tfp = NULL;
  }
#endif
  if(contextp) {
    delete contextp;
    contextp = NULL;
  }
#ifdef NVBOARD_ENABLE
  nvboard_quit();
#endif
}

void update_ftrace_dpi() {
  IFDEF(CONFIG_FTRACE, update_ftrace(last_pc, g_get_dnpc(), g_get_rs1(), g_get_rd()));
}

void ebreak() {
  #ifdef ysyx_24080020_NPC
  int a0 = top->rootp->ysyx_24080020_NPC__DOT__u_reg__DOT__regs[10];
  #endif
  #ifdef ysyxSoCFull
  int a0 = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_reg__DOT__regs[10];
  #endif
  u_npc_state.state = a0 ? NPC_ABORT : NPC_END;
  u_npc_state.ret = a0 ? true : false;
  u_npc_state.pc = g_pc;
}

void invalid_inst() {
  u_npc_state.state = NPC_ABORT;
  u_npc_state.ret = true;
  printf("Unknown inst.\n");
}

// void halt() {
//   ebreak();
// }

void check_trap(npc_state u_npc_state) {
  if(u_npc_state.ret) {
    printf("\33[1;31mNPC: HIT BAD TRAP. at pc=%#x\033[0m\n",u_npc_state.pc);
  }
  else {
    printf("\33[1;32mNPC: HIT GOOD TRAP. at pc=%#x\033[0m\n",u_npc_state.pc);
  }
}

uint32_t g_get_pc() {
#if defined (ysyxSoCFull)
  g_pc  = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__pc_wbu;
#elif defined (ysyx_24080020_NPC)
  g_pc = top->rootp->ysyx_24080020_NPC__DOT__pc_wbu;
#endif
  return g_pc;
}

void g_set_pc(uint32_t pc) {
  // top->rootp->top__DOT__u_npc__DOT__ifu__DOT__addr = pc;
#if defined (ysyxSoCFull)
  top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__pc_wbu = pc;
#elif defined (ysyx_24080020_NPC)
  top->rootp->ysyx_24080020_NPC__DOT__pc_wbu = pc;
#endif
}

uint32_t g_get_reg(int i) {
#if defined (ysyxSoCFull)
  return (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_reg__DOT__regs[i]);
#elif defined (ysyx_24080020_NPC)
  return top->rootp->ysyx_24080020_NPC__DOT__u_reg__DOT__regs[i];
#else
  return 0;
#endif
}
uint32_t g_get_csrs(int i) {
#if defined (ysyxSoCFull)
  return (top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_csr__DOT__csrs[i]);
#elif defined (ysyx_24080020_NPC)
  return top->rootp->ysyx_24080020_NPC__DOT__u_csr__DOT__csrs[i];
#else
  return 0;
#endif
}

uint32_t g_get_snpc() {
  return g_pc + 4;
}

uint32_t g_get_dnpc() {
#if defined (ysyxSoCFull)
  if(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_reg__DOT__is_dnpc_wb) {
    g_dnpc = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_reg__DOT__dnpc_wb;
  }
  else
    g_dnpc = g_pc + 4;
  return g_dnpc;
#elif defined (ysyx_24080020_NPC)
  if(top->rootp->ysyx_24080020_NPC__DOT__u_reg__DOT__is_dnpc_wb) {
    g_dnpc = top->rootp->ysyx_24080020_NPC__DOT__u_reg__DOT__dnpc_wb;
  }
  else
    g_dnpc = g_pc + 4;
  return g_dnpc;
#endif
}

uint32_t g_get_rs1() {
#if defined (ysyxSoCFull)
  return BITS(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__inst_ifu, 19, 15);
#elif defined (ysyx_24080020_NPC)
  return BITS(top->rootp->ysyx_24080020_NPC__DOT__inst_ifu, 19, 15);
#else
  return 0;
#endif
}
uint32_t g_get_rd() {
#if defined (ysyxSoCFull)
  return BITS(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__inst_ifu, 19, 7);
#elif defined (ysyx_24080020_NPC)
  return BITS(top->rootp->ysyx_24080020_NPC__DOT__inst_ifu, 19, 15);
#else

#endif
}


void update_npc_cpu() {
  for(int i=0; i<CONFIG_REGS_NUM; i++) {
    npc_cpu.gpr[i] = g_get_reg(i);
    if(i<4) {
      npc_cpu.csrs[i] = g_get_csrs(i);
    }
  }
  // assign csr_mvendorid = 32'h79737978;
  // assign csr_marchid = 32'h16f6e94;
  npc_cpu.csrs[4] = 0x79737978;
  npc_cpu.csrs[5] = 0x16f6e94;

  npc_cpu.pc = g_pc;
}

void update_dut() {
  for(int i=0; i<CONFIG_REGS_NUM; i++) {
#if defined (ysyxSoCFull)
    top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_npc__DOT__u_reg__DOT__regs[i] = npc_cpu.gpr[i];
#elif defined (ysyx_24080020_NPC)
    top->rootp->ysyx_24080020_NPC__DOT__u_reg__DOT__regs[i] = npc_cpu.gpr[i];
#endif
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

extern "C" void statistics_ifu_get_inst() {
  // printf("ifu_get_inst_cnt: %ld pc: 0x%x , total_guest_inst: 0x%ld\n", ifu_get_inst_cnt, g_pc, g_nr_guest_inst);
  icache_type = Fetch;
  ifu_get_inst_cnt ++;
}

extern "C" void statistics_lsu_get_data() {
  // printf("lsu_get_data_cnt: %ld at pc: 0x%x\n", lsu_get_data_cnt, g_pc);
  lsu_get_data_cnt ++;
}

extern "C" void statistics_exu_complete_calcu() {
  exu_complete_calcu_cnt ++;
}

extern "C" void statistics_idu_calculate_type() {
  // printf("idu_calculate_type_cnt: %ld  pc: 0x%x \n", idu_calculate_type_cnt, g_pc);
  idu_type = Calculate;
  idu_calculate_type_cnt ++;
}

extern "C" void statistics_idu_load_type() {
  // printf("idu_load_store_cnt: %ld  pc: 0x%x \n", idu_load_type_cnt, g_pc);
  idu_type = Load;
  idu_load_type_cnt ++;
}

extern "C" void statistics_idu_store_type() {
  // printf("idu_load_store_cnt: %ld  pc: 0x%x \n", idu_load_store_type_cnt, g_pc);
  idu_type = Store;
  idu_store_type_cnt ++;
}

extern "C" void statistics_idu_csr_type() {
  // printf("idu_calculate_type_cnt: %ld  pc: 0x%x \n", idu_calculate_type_cnt, g_pc);
  idu_type = CSR;
  idu_csr_type_cnt ++;
}

extern "C" void statistics_idu_jump_type() {
  idu_type = Jump;
  idu_jump_type_cnt ++;
}

extern "C" void statistics_icache_hit() {
  // printf("ifu_icache_hit_cnt: %ld  pc: 0x%x \n", ifu_icache_hit_cnt, g_pc);
  icache_type = Icache_Hit;
  ifu_icache_hit_cnt ++;
}

extern "C" void statistics_icache_miss_hit_cnt() {
    ifu_icache_hit_cnt --;
}

extern "C" void statistics_dcache_hit() {
  dcache_hit_cnt ++;
}

extern "C" void statistics_icache_miss() {
  // printf("ifu_icache_miss_cnt: %ld  pc: 0x%x \n", ifu_icache_miss_cnt, g_pc);
  icache_type = Icache_Miss;
  ifu_icache_miss_cnt ++;
}

extern "C" void statistics_btb_total() {
    btb_total_cnt ++;
}

extern "C" void statistics_btb_hit() {
    btb_hit_cnt ++;
}

extern "C" void statistics_btb_err_hit() {
    btb_hit_cnt --;
}
