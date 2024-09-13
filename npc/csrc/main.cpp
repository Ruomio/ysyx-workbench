
#include <cstdio>
#include <climits>
#include <verilated.h>
#include "Vtop.h"
#include "verilated_vcd_c.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

#include "memory/memory.h"
#include "define.h"

char *img_file = NULL;
int argc = 0;
char **argv = NULL;
npc_state u_npc_state = {.state=NPC_RUNNING, .pc=0x80000000, .ret = true};






extern int parse_args(int argc, char *argv[]);
extern void sdb_mainloop();
extern void init_sdb();
extern int is_exit_status_bad();


int main(int argc, char **argv) {
  argc = argc;
  argv = argv;

  parse_args(argc, argv);

  init_memory();

  init_sdb();

  sdb_mainloop();
  
  free_memory();
  
  return is_exit_status_bad();
}




