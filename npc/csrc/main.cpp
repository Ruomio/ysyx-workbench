#include <cstdio>
#include <climits>

#include "memory/memory.h"



extern int init_monitor(int argc, char *argv[]);
extern void sdb_mainloop();
extern void init_sdb();
extern int is_exit_status_bad();


int main(int argc, char **argv) {

  init_memory();

  init_monitor(argc, argv);

  init_sdb();

  sdb_mainloop();

  free_memory();

  return is_exit_status_bad();
}
