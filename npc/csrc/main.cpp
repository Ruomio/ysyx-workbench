#include "memory/memory.h"
#include <csignal>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <climits>

#include <signal.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
#include <cstdlib>
#include <ctime>

extern int init_monitor(int argc, char *argv[]);
extern void sdb_mainloop();
extern void init_sdb();
extern int is_exit_status_bad();
// extern void init_npc(int argc, char **argv);
extern void free_npc();



int main(int argc, char **argv) {
  // pid_t child_pid = -1;
  // uint32_t snapshot = 5;


  init_monitor(argc, argv);

  // while(1) {
  //   if(child_pid != -1) {
  //     kill(child_pid, SIGKILL);
  //     waitpid(child_pid, NULL, 0);
  //   }

  //   child_pid = fork();
  //   if(child_pid == -1) {
  //     perror("Fork faild");
  //     return EXIT_FAILURE;
  //   }
  //   else if(child_pid == 0) {
  //     sdb_mainloop();

  //     free_npc();

  //     free_memory();
  //     exit(is_exit_status_bad());
  //   }
  //   else {
  //     sdb_mainloop();

  //   }
  // }

  sdb_mainloop();

  free_npc();

  free_memory();
  return is_exit_status_bad();
}
