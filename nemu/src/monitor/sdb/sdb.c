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
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
#include "debug.h"
#include <memory/paddr.h>
#include "utils.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_si(char *args) {
  char *arg = strtok(NULL, " ");

  if(arg == NULL) {
    // no parameter, default 1
    cpu_exec(1);
  }
  else {
    cpu_exec(atoi(arg));
  }
  return 0;
}

static int cmd_info(char *info) {
  char *arg = strtok(NULL, " ");

  if(strcmp(arg, "r") == 0) {
    isa_reg_display();
  }
  else if(strcmp(arg, "w") == 0) {

  }
  else {
    printf("Unknown command 'info %s'\n", arg);
  }

  return 0;
}

static int cmd_x(char *args) {
  char *arg = strtok(NULL, " ");

  uint32_t size = 0, total = 0;
  if(arg == NULL) {
    printf("command 'x': need two paramter, but get none\n");
  }
  else {
    // first parameter
    size = atoi(arg);
    Assert(size>0, "command 'x': could not get size\n");

    // second parameter
    arg = strtok(NULL, " ");
    char *num = arg + 2; // remove '0x' prefix
    
    for(int i=0; i<strlen(num); i++) {
      total *= 16;
      switch(num[i]) {
        case '0': total += num[i] - '0'; break;
        case '1': total += num[i] - '0'; break;
        case '2': total += num[i] - '0'; break;
        case '3': total += num[i] - '0'; break;
        case '4': total += num[i] - '0'; break;
        case '5': total += num[i] - '0'; break;
        case '6': total += num[i] - '0'; break;
        case '7': total += num[i] - '0'; break;
        case '8': total += num[i] - '0'; break;
        case '9': total += num[i] - '0'; break;
        case 'a': total += num[i] - 'a' + 10; break;
        case 'b': total += num[i] - 'a' + 10; break;
        case 'c': total += num[i] - 'a' + 10; break;
        case 'd': total += num[i] - 'a' + 10; break;
        case 'e': total += num[i] - 'a' + 10; break;
        default: break;
      }
    }
    while(size--) {
      printf("%s:\t0lx%x\n",num-2, paddr_read(total, 4));
    }
  }
  return 0;
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
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
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
}
