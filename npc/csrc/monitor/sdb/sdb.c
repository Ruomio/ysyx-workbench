/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
// #include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
#include <memory/memory.h>
#include <stdint.h>
#include "stdio.h"

static int is_batch_mode = true;
extern npc_state u_npc_state;

void init_regex();
void init_wp_pool();

extern void init_npc();
extern void free_npc();
extern void exec_npc(uint64_t n);


/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  exec_npc(-1);
  return 0;
}


static int cmd_q(char *args) {
  u_npc_state.state = NPC_QUIT;
  return -1;
}

static int cmd_si(char *args) {
  char *arg = strtok(NULL, " ");

  if(arg == NULL) {
    // no parameter, default 1
    exec_npc(1);
  }
  else {
    exec_npc(atoi(arg));
  }
  return 0;
}

static int cmd_info(char *info) {
  char *arg = strtok(NULL, " ");

  if(arg == NULL) {
    printf("\033[0;31mCommand 'info': need parameter: 'r' or 'w'.\033[0m\n");
    return 0;
  }
  if(strcmp(arg, "r") == 0) {
    isa_reg_display();
  }
  else if(strcmp(arg, "w") == 0) {
    print_watchpoint();
  }
  else {
    printf("Unknown command 'info %s'\n", arg);
  }

  return 0;
}

static int cmd_x(char *args) {
  char *arg = strtok(NULL, " ");

  uint32_t size = 0;
  if(arg == NULL) {
    printf("command 'x': need two paramter, but get none\n");
  }
  else {
    // first parameter
    size = atoi(arg);
    if(size <= 0) {
      printf("command 'x': first parameter could not be '0' or not get size\n");
      return 0;
    }

    // second parameter: such as: 0x80000000+1*(2+2 )
    arg = strtok(NULL, " ");
    char buff[1024] = {0};
    int index = 0;
    while(arg  != NULL) {
      strcpy(buff+index, arg);
      index += strlen(arg);
      arg = strtok(NULL, " ");
    }
    bool success = false;
    uint32_t res = expr(buff, &success);
    if(success == false) return -1;
    for(int i=0; i<size; i++) {
      printf("0x%x:\t0x%08x\n", res+i*4, paddr_read(res+i*4, 4));
    }
  }
  return 0;
}

static int cmd_p(char *args) {

  char *arg = strtok(NULL, " ");
  if(arg == NULL) {
    printf("\033[0;31mCommand 'p': need expr parameter.\033[0m\n");
    return 0;
  }
  char buff[1024] = {0};
  int index = 0;
  while(arg  != NULL) {
    strcpy(buff+index, arg);
    index += strlen(arg);
    arg = strtok(NULL, " ");
  }
  bool success = false;
  uint32_t res = expr(buff, &success);
  if(success == false) return -1;
  printf("0x%08x\n", res);
  return 0;
}

static int cmd_w(char *args) {
  char *arg = strtok(NULL, " ");
  char buff[1024] = {0};
  int index = 0;
  if(arg == NULL) {
    printf("\033[0;31mCommand 'w': need expr parameter.\033[0m\n");
    return 0;
  }
  while(arg  != NULL) {
    strcpy(buff+index, arg);
    index += strlen(arg);
    arg = strtok(NULL, " ");
  }
  if(new_wp_interface(buff, WP_TYPE)) {
    return 0;
  }
  else {
    return -1;
  }
}

static int cmd_d(char *args) {
  char *arg = strtok(NULL, " ");
  int no = atoi(arg);
  bool ret = free_wp_by_no_interface(no);
  if(!ret) return -1;
  return 0;
}

static int cmd_b(char *args) {
  char *arg = strtok(NULL, " ");
  if(arg == NULL) {
    printf("\033[0;31mCommand 'b': need expr parameter.\033[0m\n");
    return 0;
  }
  char buff[1024] = {0};
  int index = 0;
  while(arg  != NULL) {
    strcpy(buff+index, arg);
    index += strlen(arg);
    arg = strtok(NULL, " ");
  }
  if(new_wp_interface(buff, BA_TYPE)) {
    return 0;
  }
  return -1;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "Instruction level single step, stepping into calls.", cmd_si },
  { "info", "Instruction level single step, stepping into calls.", cmd_info },
  { "x", "Instruction level single step, stepping into calls.", cmd_x },
  { "p", "Instruction level single step, stepping into calls.", cmd_p },
  { "w", "Set a watchpoint for EXPRESSION.", cmd_w },
  { "d", "Delete a watchpoint by NO.", cmd_d },
  { "b", "Set a breakpoint for EXPRESSION.", cmd_b },

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {

  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    /*extern void sdl_clear_event_queue();*/
    /*sdl_clear_event_queue();*/
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }

}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();

  // test_expr();
  // sdb_set_batch_mode();
  IFDEF(CONFIG_ITRACE, RingBuffer_create());
}
