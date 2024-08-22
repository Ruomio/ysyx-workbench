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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = (unsigned)%s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

uint32_t buf_index=0;

static int choose(int n) {
  return rand()%n;
}

static void gen_space() {
  if(buf_index >= 65535-1) return;
  sprintf(buf+buf_index, "%c", ' ');
  buf_index += strlen(buf+buf_index);

}

static void gen_num() {
  if(buf_index >= 65535-3) return;
  uint32_t num = rand()%100;
  sprintf(buf+buf_index, "%u", num);
  buf_index += strlen(buf+buf_index);
  
  // add 'u'suffix to promise only unsigned opreation
  // sprintf(buf+buf_index, "%c", 'u'); 
  // buf_index += 1;

  // space
  for(int i=0; i<rand()%2; i++) {
    gen_space();
  }
}

static void gen(char ch) {
  if(buf_index >= 65535-1) return;
  sprintf(buf+buf_index, "%c", ch);
  buf_index += strlen(buf+buf_index);
  // space
  for(int i=0; i<rand()%2; i++) {
    gen_space();
  }
}

static void gen_rand_op() {
  if(buf_index >= 65535-1) return;
  int op = rand()%4;
  char ch[] = {'+', '-', '*', '/'};
  sprintf(buf+buf_index, "%c", ch[op]);
  buf_index += strlen(buf+buf_index);
  // space
  for(int i=0; i<rand()%2; i++) {
    gen_space();
  }
}

static void gen_rand_expr() {
  switch(choose(3)) {
    case 0: {
      gen_num(); 
      break;
    }
    case 1: {
      gen('('); 
      gen_rand_expr(); 
      gen(')'); 
      break;
    }
    default: {
      gen_rand_expr(); 
      gen_rand_op(); 
      gen_rand_expr(); 
      break;
    }
  }
  // buf[0] = '\0';
  
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    gen_rand_expr();

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc -Wall -Werror /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
    
    buf_index = 0;
    memset(buf, 0, 65536);
  }
  return 0;
}
