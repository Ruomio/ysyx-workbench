#include <cstdio>
#include <climits>

#include "memory/memory.h"



extern int init_monitor(int argc, char *argv[]);
extern void sdb_mainloop();
extern void init_sdb();
extern int is_exit_status_bad();

int argc;
char **argv;


int main(int argc, char **argv) {
  argc = argc;
  argv = argv;

  init_memory();

  init_monitor(argc, argv);

  sdb_mainloop();

  free_memory();

  return is_exit_status_bad();
}
