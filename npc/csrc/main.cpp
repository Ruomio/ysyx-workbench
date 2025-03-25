#include "memory/memory.h"
#include <cstdio>
#include <climits>

#ifdef __cplusplus
extern "C" {
#endif

extern int init_monitor(int argc, char *argv[]);
extern void sdb_mainloop();
extern void init_sdb();
extern int is_exit_status_bad();
// extern void init_npc(int argc, char **argv);
extern void free_npc();



int main(int argc, char **argv) {


  init_monitor(argc, argv);


  sdb_mainloop();

  free_npc();

  free_memory();
  return is_exit_status_bad();
}

#ifdef __cplusplus
}
#endif